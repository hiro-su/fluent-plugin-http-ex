module Fluent

class ExHttpInput < HttpInput
  Plugin.register_input('http_ex', self)

  config_param :port, :integer, :default => 9880
  config_param :bind, :string, :default => '0.0.0.0'
  config_param :body_size_limit, :size, :default => 32*1024*1024
  config_param :keepalive_timeout, :time, :default => 30

  def start
    $log.debug "listening http on #{@bind}:#{@port}"
    lsock = TCPServer.new(@bind, @port)

    detach_multi_process do
      Input.new.start
      @km = KeepaliveManager.new(@keepalive_timeout)
      @lsock = Coolio::TCPServer.new(lsock, nil, ExHandler, @km, method(:on_request), @body_size_limit)

      @loop = Coolio::Loop.new
      @loop.attach(@km)
      @loop.attach(@lsock)

      @thread = Thread.new(&method(:run))
    end
  end

  def on_request(path_info, params)
    $log.debug "#{params["REMOTE_ADDR"]}, path_info: #{path_info}"
    begin
      path = path_info[1..-1] # remove /
      resource, tag = path.split('/')
      tag ||= resource

      if js = params['json'] || js = params['json-list']
        record = JSON.parse(js)

      elsif ms = params['msgpack'] || ms = params['msgpack-list']
        record = MessagePack::unpack(ms)

      elsif chunk = params['json-chunk'] || chunk = params['msgpack-chunk']
        record = chunk

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
      if params['json-list']
        record.each do |v|
          line = begin
            JSON.parse(v)
          rescue TypeError
            v #hash
          end
          Engine.emit(tag, time, line)
        end

      elsif params['json-chunk']
        record.split("\n").each do |v|
          line = begin
            JSON.parse(v)
          rescue TypeError
            v #hash
          end
          Engine.emit(tag, time, line)
        end

      elsif params['msgpack-list'] 
        record.each {|line| Engine.emit(tag, time, line) }

      elsif params['msgpack-chunk']
        msgpack_each(record) do |v|
          v.each {|line| Engine.emit(tag, time, line) } 
        end
      
      else
        Engine.emit(tag, time, record)
      end

    rescue
      return ["500 Internal Server Error", {'Content-type'=>'text/plain'}, "500 Internal Server Error\n#{$!}\n"]
    end

    return ["200 OK", {'Content-type'=>'text/plain'}, ""]
  end

  def msgpack_each(v)
    u = MessagePack::Unpacker.new
    u.feed(v)
    yield u
  end

  class ExHandler < Handler
    def on_message_complete
      return if closing?

      @env['REMOTE_ADDR'] = @remote_addr

      params = WEBrick::HTTPUtils.parse_query(@parser.query_string)
      path_info = @parser.request_path

      case @env['HTTP_TRANSFER_ENCODING']
      when /^chunked/
        params = check_content_type(params, @content_type, @body, path_info, 'chunked')
      else
        params = check_content_type(params, @content_type, @body, path_info)
      end

      params.merge!(@env)
      @env.clear

      code, header, body = *@callback.call(path_info, params)
      body = body.to_s

      if @keep_alive
        header['Connection'] = 'Keep-Alive'
        send_response(code, header, body)
      else
        send_response_and_close(code, header, body)
      end
    end

    def check_content_type(params, content_type, body, path_info, chunked=nil)
      set_params = lambda do |type, key|
        if content_type =~ /^application\/x-www-form-urlencoded/
          params.update WEBrick::HTTPUtils.parse_query(body)
        elsif content_type =~ /^multipart\/form-data; boundary=(.+)/
          boundary = WEBrick::HTTPUtils.dequote($1)
          params.update WEBrick::HTTPUtils.parse_form_data(body, boundary)
        elsif content_type =~ /^application\/#{type}/
          params[key] = body
        end
      end

      path = path_info[1..-1] # remove /
      resource, tag = path.split('/')
      tag ||= resource
      case resource
      when /^j$/
        set_params.call('json','json')
      when /^m$/
        set_params.call('x-msgpack','msgpack')
      when /^js$/
        if chunked
          set_params.call('json','json-chunk')
        else
          set_params.call('json','json-list')
        end
      when /^ms$/
        if chunked
          set_params.call('x-msgpack','msgpack-chunk')
        else
          set_params.call('x-msgpack','msgpack-list')
        end
      when tag
        set_params.call('json','json')
        set_params.call('x-msgpack','msgpack')
      end

      params
    rescue => ex
      $log.error ex
      $log.error ex.backtrace * "\n"
    end
  end
end

end
