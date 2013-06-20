require './lib/application'
app = HttpInputEX::Application.new(
  host: "localhost",
  port: 5000,
  json_file: File.join(File.dirname(__FILE__),"json/sample.json")
)
# json
app.json
app.json_chunk
app.json_stream
# msgpack
app.msgpack
app.msgpack_chunk
app.msgpack_stream
