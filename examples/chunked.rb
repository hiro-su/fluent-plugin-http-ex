require 'net/http'
require 'stringio'
require 'msgpack'
require 'json'

host, port = 'localhost', 8888
path = "/ms/test.tag"
http = Net::HTTP.new(host, port)
req = Net::HTTP::Post.new(path)
req[ "Content-Type" ] = 'application/x-msgpack'
req[ "Transfer-Encoding" ] = "chunked"
req[ "Connection" ] = "Keep-Alive"

io = StringIO.new
DATA.each do |line|
  io << JSON.parse(line.chomp).to_msgpack
end
io.rewind
req.body_stream = io
http.request(req).body

__END__
{"key1":"value1"}
{"key2":"value2"}
{"key3":"value3"}
{"key4":"value4"}
{"key5":"value5"}
