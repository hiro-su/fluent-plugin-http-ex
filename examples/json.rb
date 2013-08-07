require 'net/http'

# in_http
host, port = 'localhost', 7777
path = "/test.tag"
http = Net::HTTP.new(host, port)
req = Net::HTTP::Post.new(path)
req["Content-Type"] = "application/json"
1.upto(10000) do |i|
  req.body = "{\"key#{i}\":\"value#{i}\"}"
  http.request(req)
end

# in_http_ex
host, port = 'localhost', 8888
path = "/j/test.tag"
http = Net::HTTP.new(host, port)
req = Net::HTTP::Post.new(path)
req["Content-Type"] = "application/json"
1.upto(10000) do |i|
  req.body = "{\"key#{i}\":\"value#{i}\"}"
  http.request(req)
end
