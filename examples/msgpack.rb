require 'net/http'
require 'msgpack'

# in_http
#host, port = 'localhost', 7777
#path = "/test.tag"
#http = Net::HTTP.new(host, port)
#1.upto(10000) do |i|
#  record = URI.encode_www_form({"msgpack"=>{"key#{i}"=>"value#{i}"}.to_msgpack})
#  http.post(path, record)
#end

# in_http_ex
host, port = 'localhost', 8888
path = "/m/test.tag"
http = Net::HTTP.new(host, port)
req = Net::HTTP::Post.new(path)
req["Content-Type"] = "application/x-msgpack"
1.upto(10000) do |i|
  req.body = {"key#{i}"=>"value#{i}"}.to_msgpack
  http.request(req)
end
