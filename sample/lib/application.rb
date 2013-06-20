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

    def json path
      @http.post(path, "json=#{@json}")
    end

    def json_chunk path
      records = [@json, @json, @json]
      @http.post(path, "json-chunk=#{records}")
    end

    def json_stream path
      req = Net::HTTP::Post.new(path)
      req[ "Content-Type" ] = 'application/x-json-stream'
      req[ "Transfer-Encoding" ] = "chunked"
      File.open(@json_file) do |io|
        req.body_stream = io
        @http.request(req).body
      end
    end

    def msgpack path
      record_m = @record.to_msgpack
      @http.post(path, "msgpack=#{record_m}")
    end

    def msgpack_chunk path
      records = [@record, @record, @record]
      records_m = records.to_msgpack
      @http.post(path, "msgpack-chunk=#{records_m}")
    end

    def msgpack_stream path
      req = Net::HTTP::Post.new(path)
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
