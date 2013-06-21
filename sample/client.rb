require './lib/application'
app = HttpInputEX::Application.new(
  host: "localhost",
  port: 5000,
  json_file: File.join(File.dirname(__FILE__),"json/sample.json")
)
# json
app.json '/test.http-ex.json'
app.json_list '/test.http-ex.json-list'
app.json_chunk '/test.http-ex.json-chunk'
# msgpack
app.msgpack '/test.http-ex.msgpack'
app.msgpack_list '/test.http-ex.msgpack-list'
app.msgpack_chunk '/test.http-ex.msgpack-chunk'
