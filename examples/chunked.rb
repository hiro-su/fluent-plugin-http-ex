require 'open3'
require 'msgpack'

class ChunkTest
  def initialize(host, port)
    @host = host
    @port = port
    @cmd = "nc"
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
          body = {"key#{i}"=>"value#{i}"}.to_msgpack
          size = body.size
          head = \
            "POST /ms/test.tag HTTP/1.1\r\nUser-Agent: curl/7.28.0\r\nHost: #{@host}:#{@port}\r\nContent-type: application/x-msgpack\r\nTransfer-Encoding: chunked\r\nConnection: Keep-Alive\r\nExpect: 100-continue\r\n\r\n"
          if i == 0
            stdin << head
          elsif i > 10000
            stdin << "0\r\n\r\n"
            break
          else
            chunk = "#{size.to_s(16)}\r\n#{body}\r\n"
            stdin << chunk
          end
          i += 1
        end
      ensure
        stdin.close
      end
    end
  end
end

chunk = ChunkTest.new('localhost', 8888)
chunk.run
