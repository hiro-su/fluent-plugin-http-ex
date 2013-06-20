require './lib/application'
app = HttpInputEX::Application.new(
  host: "localhost",
  port: 5000,
  json_file: File.join(File.dirname(__FILE__),"json/sample.json")
)
# json
app.json '/test.http-ex.json'
app.json_chunk '/test.http-ex.json-chunk'
app.json_stream '/test.http-ex.json-stream'
# msgpack
app.msgpack '/test.http-ex.msgpack'
app.msgpack_chunk '/test.http-ex.msgpack-chunk'
app.msgpack_stream '/test.http-ex.msgpack-stream'
