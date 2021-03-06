require 'net/http'
require 'msgpack'

host, port = 'localhost', 8888
path = "/ms/test.tag"
http = Net::HTTP.new(host, port)
req = Net::HTTP::Post.new(path)
req["Content-Type"] = "application/x-msgpack"
1.upto(1000) do |i|
  req.body = [
    {"key#{i}"=>"value#{i}"},
    {"key#{i}"=>"value#{i}"},
    {"key#{i}"=>"value#{i}"},
    {"key#{i}"=>"value#{i}"},
    {"key#{i}"=>"value#{i}"},
    {"key#{i}"=>"value#{i}"},
    {"key#{i}"=>"value#{i}"},
    {"key#{i}"=>"value#{i}"},
    {"key#{i}"=>"value#{i}"},
    {"key#{i}"=>"value#{i}"},
  ].to_msgpack
  http.request(req)
end
