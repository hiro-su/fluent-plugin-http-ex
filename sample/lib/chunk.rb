require 'open3'
require 'msgpack'
require 'json'
require 'nio'

# usage: ruby chunk_test.rb msgpack
class ChunkTest
  def initialize(host, port, mode)
    @host = host
    @port = port
    @cmd = "nc"
    @mode = mode || "msgpack"
    @term = false
    @selector = NIO::Selector.new
  end

  def run
    Signal.trap(:INT){
      @term = true
    }

    req = ->x{->y{->size{->body{
      "PUT /#{x}/test.tag.here HTTP/1.1\r\nUser-Agent: curl/7.28.0\r\nHost: localhost:5000\r\nContent-type: application/#{y}\r\nTransfer-Encoding: chunked\r\nConnection: Keep-Alive\r\nExpect: 100-continue\r\n\r\n#{size.to_s(16)}\r\n#{body}\r\n0\r\n\r\n"
    }}}}
    Open3.popen3("#{@cmd} #{@host} #{@port}") do |stdin, stdout, stderr, wait_thr|
      begin
        i = 0
        loop do
          break if @term
          reader, writer = stdout, stdin
          monitor = @selector.register(reader, :r)
          monitor.value = proc { puts monitor.io.read_nonblock(4096) }
            body = %Q({"test":"hoge", "data":"data#{i}"})
            case @mode
            when /msgpack/
              body = JSON.parse(body.chomp).to_msgpack
              body = "#{body}#{body}#{body}"
              size = body.size
              head = req["ms"]["x-msgpack"][size][body]
            when /json/
              body = "#{body}\n#{body}\n#{body}"
              size = body.size
              head = req["js"]["json"][size][body]
            end
            i += 1
            writer << head
            @selector.select { |m| m.value.call }
            @selector.deregister(reader)
            sleep 1
          #end
        end
      ensure
        stdin.close
      end
    end
  end
end
