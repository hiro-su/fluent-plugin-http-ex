# Fluent::Plugin::Http::Ex

## Overview

This plugin takes JSON or MessagePack of events as input via a single, list or chunked
HTTP POST request and emits each as an individual event to your output plugins.
If you're sending a lot of events this simplifies your client's code and eliminates
the overhead of creating a lot of brief connections.

## Configuration

The ExHttpInput plugin uses the same settings you would use for the standard
HTTP input plugin. Example:

    <source>
      type http_ex
      port 8888
      bind 0.0.0.0
      body_size_limit 32m
      keepalive_timeout 300s #0s is not timeout
    </source>

Like the HTTP input plugin, the tag is determined by the URL used, which means 
all events in one request must have the same tag.

## Usage

Have your logging system send JSON or Message of events. Example:

Base URL

    http://localhost:8888

### json
####  case 1

resource

    j or null

header

    Content-type: application/x-www-form-urlencoded

body

    json=<json data>

sample

    $ curl -X POST -d 'json={"action":"login","user":2}' \
        http://localhost:8888/j/test.tag.here;

    $ curl -X POST -d 'json={"action":"login","user":2}' \
        http://localhost:8888/test.tag.here;

#### case 2

resource

    j or null

header

    Content-type: application/json

body

    <json data>

sample

    $ curl -X POST -H 'Content-Type: application/json' -d '{"action":"login","user":2}' \
        http://localhost:8888/j/test.tag.here;

    $ curl -X POST -H 'Content-Type: application/json' -d '{"action":"login","user":2}' \
        http://localhost:8888/test.tag.here;

### json list
#### case 1

resource

    js

header

    Content-type: application/x-www-form-urlencoded

body

    json=<json list data>

sample

    $ curl -X POST -d 'json=[{"action":"login","user":2},{"action":"login","user":2}]' \
        http://localhost:8888/js/test.tag.here;

#### case 2

resource

    js

header

    Content-type: application/json

body

    json=<json list data>

sample

    $ curl -X POST -d '[{"action":"login","user":2},{"action":"login","user":2}]' \
        http://localhost:8888/js/test.tag.here;

### msgpack
#### case 1

resource

    m or null

header

    Content-type: application/x-www-form-urlencoded

body

    msgpack=<hash msgpack data>
             hash.to_msgpack

#### case2

resource

    m or null

header

    Content-type: application/x-msgpack

body

    <msgpack data>
     hash.to_msgpack

### msgpack list
#### case 1

resource

    ms

header

    Content-type: application/x-www-form-urlencoded

body

    msgpack=<msgpack list data>
             [hash,hash,hash].to_msgpack

#### case 2

resource

    ms

header

    Content-type: application/x-msgpack

body

    msgpack=<msgpack list data>
             [hash,hash,hash].to_msgpack

### msgpack chunked

resource

    ms

header

    Content-type: application/x-msgpack
    Transfer-Encoding: chunked

body

    <msgpack chunk data>
     "#{hash.to_msgpack}#{hash.to_msgpack}"...


Each event in the list will be sent to your output plugins as an individual
event. 

## Performance

Comparison of in_http and in_http_ex.
send 10,000 messages.


machine spec

    Mac OS X 10.8.2
    1.8 GHz Intel Core i5
    8 GB 1600 MHz DDR3

### in_http

json

    $ time ruby examples/json.rb
    
    real    2m27.480s
    user    0m7.252s
    sys     0m4.438s

msgpack

    $ time ruby examples/msgpack.rb
    
    real    2m36.408s
    user    0m8.249s
    sys     0m4.441s

### in_http_ex

json

    $ time ruby examples/json.rb
    
    real    2m30.639s
    user    0m7.195s
    sys     0m4.686s

msgpack

    $ time ruby examples/msgpack.rb
    
    real    2m28.442s
    user    0m7.126s
    sys     0m4.324s

json list

    $ time ruby examples/json_list.rb
    
    real    0m18.179s
    user    0m0.872s
    sys     0m0.477s

msgpack list

    $ time ruby examples/msgpack_list.rb
    
    real    0m13.787s
    user    0m0.908s
    sys     0m0.470s

msgpack chunked

    $ time ruby examples/nc_chunked.rb
    
    real    0m1.584s
    user    0m0.244s
    sys     0m0.107s


## Copyright

Copyright (c) 2013 hiro-su.

Based on the in_http plugin by FURUHASHI Sadayuki

 Apache License, Version 2.0
