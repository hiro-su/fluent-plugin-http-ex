require 'open3'
require 'msgpack'
require 'json'

# usage: ruby chunk_test.rb msgpack
class ChunkTest
  def initialize(host, port, mode)
    @host = host
    @port = port
    @cmd = "nc"
    @mode = mode || "msgpack"
    @term = false
  end

  def run
    Signal.trap(:INT){
      @term = true
    }

    Open3.popen3("#{@cmd} #{@host} #{@port}") do |stdin, stdout, stderr, wait_thr|
      begin
        i = 0
        loop do
          break if @term
          body = %Q({"test":"hoge", "data":"data#{i}"})
          case @mode
          when /msgpack/
            body = JSON.parse(body.chomp).to_msgpack
            body = "#{body}#{body}#{body}"
            size = body.size + 1
            head = "PUT /ms/dagrin.test HTTP/1.1\r\nUser-Agent: curl/7.28.0\r\nHost: localhost:5000\r\nAccept: */*\r\nContent-type: application/x-msgpack\r\nTransfer-Encoding: chunked\r\nConnection: Keep-Alive\r\nExpect: 100-continue\r\n\r\n#{size.to_s(16)}\r\n#{body}\n\r\n0\r\n\r\n"
          when /json/
            body = "#{body}\n#{body}\n#{body}"
            size = body.size + 1
            head = "PUT /js/dagrin.test HTTP/1.1\r\nUser-Agent: curl/7.28.0\r\nHost: localhost:5000\r\nAccept: */*\r\nContent-type: application/json\r\nTransfer-Encoding: chunked\r\nConnection: Keep-Alive\r\nExpect: 100-continue\r\n\r\n#{size.to_s(16)}\r\n#{body}\n\r\n0\r\n\r\n"
          end
          i += 1
          stdin.puts head
          sleep 0.5
        end
      ensure
        stdin.close
      end
    end
  end
end
