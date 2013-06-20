require 'net/http'
require 'json'
require 'msgpack'
require 'stringio'

module HttpInputEX
  class Application
    def initialize(opts={})
      host, port = opts[:host], opts[:port]
      @http = Net::HTTP.new(host, port)
      configure(opts[:json_file])
    end

    def configure(json_file)
      @json = '{"id":123,"name":"foo"}'
      @record = JSON.parse(@json)
      @json_file = File.join(json_file)
    end

    def json
      @http.post("/test.http-ex.json", "json=#{@json}")
    end

    def json_chunk
      records = [@json, @json, @json]
      @http.post("/test.http-ex.json-chunk", "json-chunk=#{records}")
    end

    def json_stream
      req = Net::HTTP::Post.new("/test.http-ex.json-stream")
      req[ "Content-Type" ] = 'application/x-json-stream'
      req[ "Transfer-Encoding" ] = "chunked"
      File.open(@json_file) do |io|
        req.body_stream = io
        @http.request(req).body
      end
    end

    def msgpack
      record_m = @record.to_msgpack
      @http.post("/test.http-ex.msgpack", "msgpack=#{record_m}")
    end

    def msgpack_chunk
      records = [@record, @record, @record]
      records_m = records.to_msgpack
      @http.post("/test.http-ex.msgpack-chunk", "msgpack-chunk=#{records_m}")
    end

    def msgpack_stream
      req = Net::HTTP::Post.new("/test.http-ex.msgpack-stream")
      req[ "Content-Type" ] = 'application/x-msgpack-stream'
      req[ "Transfer-Encoding" ] = "chunked"
      io = StringIO.new
      File.open(@json_file) do |f| 
        while line = f.gets
          io << line.chomp.to_msgpack
        end
      end
      io.rewind
      req.body_stream = io
      @http.request(req).body
    end
  end
end
