module Fluent

class ExHttpInput < HttpInput
  Plugin.register_input('http_ex', self)

  config_param :port, :integer, :default => 8888
  config_param :bind, :string, :default => '0.0.0.0'
  config_param :body_size_limit, :size, :default => 32*1024*1024
  config_param :keepalive_timeout, :time, :default => 30

  class KeepaliveManager < Coolio::TimerWatcher
    class TimerValue
      def initialize
        @value = 0
      end
      attr_accessor :value
    end

    def initialize(timeout)
      super(1, true)
      @cons = {}
      @timeout = timeout.to_i
    end

    def add(sock)
      @cons[sock] = sock
    end

    def delete(sock)
      @cons.delete(sock)
    end

    def on_timer
      @cons.each_pair {|sock,val|
        if sock.step_idle > @timeout
          sock.close unless @timeout == 0
        end
      }
    end
  end

  def start
    $log.debug "listening http on #{@bind}:#{@port}"
    lsock = TCPServer.new(@bind, @port)

    detach_multi_process do
      Input.new.start
      @km = KeepaliveManager.new(@keepalive_timeout)
      @lsock = Coolio::TCPServer.new(lsock, nil, ExHandler, @km, method(:on_request), @body_size_limit, $log)

      @loop = Coolio::Loop.new
      @loop.attach(@km)
      @loop.attach(@lsock)

      @thread = Thread.new(&method(:run))
    end
  end
  
  def on_request(path_info, params)
    $log.debug "remote_addr: #{params["REMOTE_ADDR"]}, path_info: #{path_info}"
    begin
      path = path_info[1..-1] # remove /
      resource, tag = path.split('/')
      tag ||= resource

      if chunk = params['chunked']
        record = chunk 
        
      elsif js = params['json']
        record = JSON.parse(js)

      elsif ms = params['x-msgpack'] || ms = params['msgpack']
        record = MessagePack::unpack(ms)

      else
        raise "'json' or 'msgpack' parameter is required"
      end

      time = params['time']
      time = time.to_i
      if time == 0
        time = Engine.now
      end

    rescue
      return ["400 Bad Request", {'Content-type'=>'text/plain'}, "400 Bad Request\n#{$!}\n"]
    end

    # TODO server error
    begin
      case params["resource"]
      when :js
        record.each do |v|
          line = begin
            JSON.parse(v)
          rescue TypeError
            v #hash
          end
          Engine.emit(tag, time, line)
        end

      when :ms
        record.each {|line| Engine.emit(tag, time, line) }

      else
        Engine.emit(tag, time, record)
      end

    rescue
      return ["500 Internal Server Error", {'Content-type'=>'text/plain'}, "500 Internal Server Error\n#{$!}\n"]
    end

    return ["200 OK", {'Content-type'=>'text/plain'}, ""]
  end

  class ExHandler < Handler
    def on_close
      $log.debug "close #{@remote_addr}:#{@remote_port}"
      super
    end

    def on_headers_complete(headers)
      expect = nil
      size = nil
      if @parser.http_version == [1, 1]
        @keep_alive = true
      else
        @keep_alive = false
      end
      @env = {}
      headers.each_pair {|k,v|
        @env["HTTP_#{k.gsub('-','_').upcase}"] = v
        case k
        when /Expect/i
          expect = v
        when /Content-Length/i
          size = v.to_i
        when /Content-Type/i
          @content_type = v
        when /Connection/i
          if v =~ /close/i
            @keep_alive = false
          elsif v =~ /Keep-alive/i
            @keep_alive = true
          end
        when /Transfer-Encoding/i
          if v =~ /chunked/i
            @chunked = true
          end
        end
      }
      if expect
        if expect == '100-continue'
          if !size || size < @body_size_limit
            send_response_nobody("100 Continue", {})
          else
            send_response_and_close("413 Request Entity Too Large", {}, "Too large")
          end
        else
          send_response_and_close("417 Expectation Failed", {}, "")
        end
      end
    end

    def on_body(chunk)
      if @chunked && @content_type =~ /application\/x-msgpack/i
        m = method(:on_read_msgpack)
        @u = MessagePack::Unpacker.new
        (class << self; self; end).module_eval do
          define_method(:on_body, m)
        end
        m.call(chunk)
      else
        if @body.bytesize + chunk.bytesize > @body_size_limit
          unless closing?
            send_response_and_close("413 Request Entity Too Large", {}, "Too large")
          end
          return
        end
        @body << chunk
      end
    end

    def on_read_msgpack(data)
      params = WEBrick::HTTPUtils.parse_query(@parser.query_string)
      path_info = @parser.request_path
      @u.feed_each(data) do |obj|
        params["chunked"] = obj
        params["REMOTE_ADDR"] = @remote_addr
        @callback.call(path_info, params)
      end
    rescue
      $log.error "on_read_msgpack error: #{$!.to_s}"
      $log.error_backtrace
      close
    end

    def on_message_complete
      return if closing?

      @env['REMOTE_ADDR'] = @remote_addr

      params = WEBrick::HTTPUtils.parse_query(@parser.query_string)
      path_info = @parser.request_path

      params = check_content_type(params, @content_type, @body, path_info)
      params.merge!(@env)
      @env.clear

      unless @chunked
        code, header, body = *@callback.call(path_info, params)
        body = body.to_s

        if @keep_alive
          header['Connection'] = 'Keep-Alive'
          send_response(code, header, body)
        else
          send_response_and_close(code, header, body)
        end
      else
        send_response("200 OK", {'Content-type'=>'text/plain', 'Connection'=>'Keep-Alive'}, "")
      end
    end

    def check_content_type(params, content_type, body, path_info)
      path = path_info[1..-1] # remove /
      resource, _ = path.split('/')
      case resource
      when /^js$/
        params["resource"] = :js
      when /^ms$/
        params["resource"] = :ms
      end

      if content_type =~ /^application\/x-www-form-urlencoded/
        params.update WEBrick::HTTPUtils.parse_query(body)
      elsif content_type =~ /^multipart\/form-data; boundary=(.+)/
        boundary = WEBrick::HTTPUtils.dequote($1)
        params.update WEBrick::HTTPUtils.parse_form_data(body, boundary)
      elsif content_type =~ /^application\/(json|x-msgpack)/
        params[$1] = body
      end

      params
    rescue => ex
      $log.error ex
      $log.error ex.backtrace * "\n"
    end
  end
end

end
