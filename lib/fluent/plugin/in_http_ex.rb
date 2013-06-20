module Fluent
  class HttpInputEx < HttpInput
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
        @lsock = Coolio::TCPServer.new(lsock, nil, HandlerEX, @km, method(:on_request), @body_size_limit)

        @loop = Coolio::Loop.new
        @loop.attach(@km)
        @loop.attach(@lsock)

        @thread = Thread.new(&method(:run))
      end
    end

    def on_request(path_info, params)
      begin
        path = path_info[1..-1] # remove /
        tag = path.split('/').join('.')

        if msgpack_chunk = params['msgpack_chunk']
          record = msgpack_chunk

        elsif msgpack = params['msgpack']
          record = MessagePack;;unpack(msgpack)

        elsif js = params['json']
          record = JSON.parse(js)

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
        if params['msgpack_chunk']
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

    class HandlerEX < Handler
      def on_message_complete
        return if closing?

        @env['REMOTE_ADDR'] = @remote_addr

        params = WEBrick::HTTPUtils.parse_query(@parser.query_string)

        if @content_type =~ /^application\/x-www-form-urlencoded/
          params.update WEBrick::HTTPUtils.parse_query(@body)
        elsif @content_type =~ /^multipart\/form-data; boundary=(.+)/
          boundary = WEBrick::HTTPUtils.dequote($1)
          params.update WEBrick::HTTPUtils.parse_form_data(@body, boundary)
        elsif @content_type =~ /^application\/json/
          params['json'] = @body
        elsif @content_type =~ /^application\/msgpack/
          params['msgpack'] = @body
        elsif @content_type =~ /^application\/x-msgpack/
          params['msgpack_chunk'] = @body
        end
        path_info = @parser.request_path

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
    end
  end
end
