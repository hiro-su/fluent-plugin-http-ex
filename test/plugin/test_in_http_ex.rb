require 'helper'
require 'net/http'

class ExHttpInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
port 9911
bind 127.0.0.1
body_size_limit 10m
keepalive_timeout 5
]

  def create_driver(conf=CONFIG)
    Fluent::Test::ExHttpInputTestDriver.new(Fluent::ExHttpInput).configure(conf)
  end

  def test_configure
    d = create_driver
    assert_equal 9911, d.instance.port
    assert_equal '127.0.0.1', d.instance.bind
    assert_equal 10*1024*1024, d.instance.body_size_limit
    assert_equal 5, d.instance.keepalive_timeout
  end

  def test_time
    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    Fluent::Engine.now = time

    d.expect_emit "tag1", time, {"a"=>1}
    d.expect_emit "tag2", time, {"a"=>2}

    d.run do
      d.expected_emits.each {|tag,time,record|
        res = post("/#{tag}", {"json"=>record.to_json})
        assert_equal "200", res.code
      }
    end
  end

  def test_json
    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i

    d.expect_emit "tag1", time, {"a"=>1}
    d.expect_emit "tag2", time, {"a"=>2}

    d.run do
      d.expected_emits.each {|tag,time,record|
        res = post("/#{tag}", {"json"=>record.to_json, "time"=>time.to_s})
        assert_equal "200", res.code
      }
    end
  end

  def test_application_json
    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i

    d.expect_emit "tag1", time, {"a"=>1}
    d.expect_emit "tag2", time, {"a"=>2}

    d.run do
      d.expected_emits.each {|tag,time,record|
        http = Net::HTTP.new("127.0.0.1", 9911)
        req = Net::HTTP::Post.new("/#{tag}?time=#{time.to_s}", {"content-type"=>"application/json; charset=utf-8"})
        req.body = record.to_json
        res = http.request(req)
        assert_equal "200", res.code
      }
    end
  end

  def test_resource_json
    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i

    d.expect_emit "tag1", time, {"a"=>1}
    d.expect_emit "tag2", time, {"a"=>2}

    d.run do
      d.expected_emits.each {|tag,time,record|
        res = post("/j/#{tag}", {"json"=>record.to_json, "time"=>time.to_s})
        assert_equal "200", res.code
      }
    end
  end

  def test_application_resource_json
    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i

    d.expect_emit "tag1", time, {"a"=>1}
    d.expect_emit "tag2", time, {"a"=>2}

    d.run do
      d.expected_emits.each {|tag,time,record|
        http = Net::HTTP.new("127.0.0.1", 9911)
        req = Net::HTTP::Post.new("/j/#{tag}?time=#{time.to_s}", {"content-type"=>"application/json; charset=utf-8"})
        req.body = record.to_json
        res = http.request(req)
        assert_equal "200", res.code
      }
    end
  end

  def test_resource_json_list
    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i

    d.expect_emit "tag1", time, {"a"=>1}
    d.expect_emit "tag2", time, {"a"=>2}
    d.expect_emit "tag3", time, {"a"=>3}
    
    rs = d.run do
      d.expected_emits.each {|tag,time,record|
        res = post("/js/#{tag}", {"json"=>"[#{record.to_json},#{record.to_json},#{record.to_json}]", "time"=>time.to_s})
        assert_equal "200", res.code
      }
    end

    expects, results = rs
    i, c = 0, 0
    results.each {|tag,es|
      es.each {|time,record|
        assert_equal(expects[i], [tag, time, record])
        c += 1
        i += 1 if c % 3 == 0
      }
    }
  end

  def test_application_resource_json_list
    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i

    d.expect_emit "tag1", time, {"a"=>1}
    d.expect_emit "tag2", time, {"a"=>2}
    d.expect_emit "tag3", time, {"a"=>3}

    rs = d.run do
      d.expected_emits.each {|tag,time,record|
        http = Net::HTTP.new("127.0.0.1", 9911)
        req = Net::HTTP::Post.new("/js/#{tag}?time=#{time.to_s}", {"content-type"=>"application/json; charset=utf-8"})
        req.body = "[#{record.to_json},#{record.to_json},#{record.to_json}]"
        res = http.request(req)
        assert_equal "200", res.code
      }
    end

    expects, results = rs
    i, c = 0, 0
    results.each {|tag,es|
      es.each {|time,record|
        assert_equal(expects[i], [tag, time, record])
        c += 1
        i += 1 if c % 3 == 0
      }
    }
  end

  def test_msgpack
    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i

    d.expect_emit "tag1", time, {"a"=>1}
    d.expect_emit "tag2", time, {"a"=>2}

    d.run do
      d.expected_emits.each {|tag,time,record|
        res = post("/#{tag}", {"msgpack"=>record.to_msgpack, "time"=>time.to_s})
        assert_equal "200", res.code
      }
    end
  end

  def test_application_msgpack
    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i

    d.expect_emit "tag1", time, {"a"=>1}
    d.expect_emit "tag2", time, {"a"=>2}

    d.run do
      d.expected_emits.each {|tag,time,record|
        http = Net::HTTP.new("127.0.0.1", 9911)
        req = Net::HTTP::Post.new("/#{tag}?time=#{time.to_s}", {"content-type"=>"application/x-msgpack; charset=utf-8"})
        req.body = record.to_msgpack
        res = http.request(req)
        assert_equal "200", res.code
      }
    end
  end

  def test_resource_msgpack
    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i

    d.expect_emit "tag1", time, {"a"=>1}
    d.expect_emit "tag2", time, {"a"=>2}

    d.run do
      d.expected_emits.each {|tag,time,record|
        res = post("/m/#{tag}", {"msgpack"=>record.to_msgpack, "time"=>time.to_s})
        assert_equal "200", res.code
      }
    end
  end

  def test_application_resource_msgpack
    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i

    d.expect_emit "tag1", time, {"a"=>1}
    d.expect_emit "tag2", time, {"a"=>2}

    d.run do
      d.expected_emits.each {|tag,time,record|
        http = Net::HTTP.new("127.0.0.1", 9911)
        req = Net::HTTP::Post.new("/m/#{tag}?time=#{time.to_s}", {"content-type"=>"application/x-msgpack; charset=utf-8"})
        req.body = record.to_msgpack
        res = http.request(req)
        assert_equal "200", res.code
      }
    end
  end

  def test_resource_msgpack_list
    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i

    d.expect_emit "tag1", time, {"a"=>1}
    d.expect_emit "tag2", time, {"a"=>2}
    d.expect_emit "tag3", time, {"a"=>3}
    
    rs = d.run do
      d.expected_emits.each {|tag,time,record|
        res = post("/ms/#{tag}", {"msgpack"=>[record,record,record].to_msgpack, "time"=>time.to_s})
        assert_equal "200", res.code
      }
    end

    expects, results = rs
    i, c = 0, 0
    results.each {|tag,es|
      es.each {|time,record|
        assert_equal(expects[i], [tag, time, record])
        c += 1
        i += 1 if c % 3 == 0
      }
    }
  end

  def test_application_resource_msgpack_list
    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i

    d.expect_emit "tag1", time, {"a"=>1}
    d.expect_emit "tag2", time, {"a"=>2}
    d.expect_emit "tag3", time, {"a"=>3}

    rs = d.run do
      d.expected_emits.each {|tag,time,record|
        http = Net::HTTP.new("127.0.0.1", 9911)
        req = Net::HTTP::Post.new("/ms/#{tag}?time=#{time.to_s}", {"content-type"=>"application/x-msgpack; charset=utf-8"})
        req.body = [record,record,record].to_msgpack
        res = http.request(req)
        assert_equal "200", res.code
      }
    end

    expects, results = rs
    i, c = 0, 0
    results.each {|tag,es|
      es.each {|time,record|
        assert_equal(expects[i], [tag, time, record])
        c += 1
        i += 1 if c % 3 == 0
      }
    }
  end

  def test_msgpack_chunked
    require 'stringio'

    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i

    d.expect_emit "tag1", time, {"a"=>1}
    d.expect_emit "tag1", time, {"a"=>2}
    d.expect_emit "tag1", time, {"a"=>3}

    http = Net::HTTP.new("127.0.0.1", 9911)

    rs = d.run do
      io = StringIO.new
      req = ""
      d.expected_emits.each {|tag,time,record|
        req = Net::HTTP::Post.new("/ms/#{tag}?time=#{time.to_s}")
        req["Content-Type"] = "application/x-msgpack"
        req["Transfer-Encoding"] = "chunked"
        io << record.to_msgpack
        io << record.to_msgpack
        io << record.to_msgpack
      }
      io.rewind
      req.body_stream = io
      res = http.request(req)
      assert_equal "200", res.code
    end

    expects, results = rs
    i, c = 0, 0
    results.each {|tag,es|
      es.each {|time,record|
        assert_equal(expects[i], [tag, time, record])
        c += 1
        i += 1 if c % 3 == 0
      }
    }
  end

  def post(path, params)
    http = Net::HTTP.new("127.0.0.1", 9911)
    req = Net::HTTP::Post.new(path, {})
    req.set_form_data(params)
    http.request(req)
  end

end
