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
      @json_file = File.join(json_file)
      @json = File.open(@json_file) {|f| f.gets.chomp }
      @record = JSON.parse(@json)
    end

    def json path
      @http.post(path, %Q(json=#{@json}))
    end

    def json_list path
      records = [@json, @json, @json]
      @http.post(path, %Q(json-list=#{records}))
    end

    def json_chunk path
      req = Net::HTTP::Post.new(path)
      req[ "Content-Type" ] = 'application/json'
      req[ "Transfer-Encoding" ] = "chunked"
      File.open(@json_file) do |io|
        req.body_stream = io
        @http.request(req).body
      end
    end

    def msgpack path
      record_m = URI.encode_www_form({"msgpack" => @record.to_msgpack})
      @http.post(path, record_m)
    end

    def msgpack_list path
      records = [@record, @record, @record]
      records_m = URI.encode_www_form({"msgpack-list" => records.to_msgpack})
      @http.post(path, records_m)
    end

    def msgpack_chunk path
      req = Net::HTTP::Post.new(path)
      req[ "Content-Type" ] = 'application/x-msgpack'
      req[ "Transfer-Encoding" ] = "chunked"
      io = StringIO.new
      File.open(@json_file) do |f| 
        while line = f.gets
          io << JSON.parse(line.chomp).to_msgpack
        end
      end
      io.rewind
      req.body_stream = io
      @http.request(req).body
    end
  end
end
