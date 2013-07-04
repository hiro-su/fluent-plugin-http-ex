# Fluent::Plugin::Http::Ex

## Overview

This plugin takes JSON or MessagePack of events as input via a single or chunked
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
      keepalive_timeout 300s
    </source>

Like the HTTP input plugin, the tag is determined by the URL used, which means 
all events in one request must have the same tag.

## Usage

Have your logging system send JSON or Message of events. Example:

Base URL

    http://localhost:8888

### single json

resource

    j

header

    Content-type: applicatoin/x-www-form/urlencoded

body

    json=<json data>

sample

    $ curl -X POST -d 'json=[{"action":"login","user":2}]' \
        http://localhost:8888/j/test.tag.here;

### json list

resource

    js

header

    Content-type: applicatoin/x-www-form/urlencoded

body

    json-list=<json list data>

sample

    $ curl -X POST -d 'json-list=[{"action":"login","user":2},{"action":"login","user":2}]' \
        http://localhost:8888/js/test.tag.here;

### json chunked

resource

    js

header

    Content-type: application/json
    Transfer-Encoding: chunked

body

    <json chunk data of \n split>

sample

    $ vi test.txt
    {"action":"login","user":2}
    {"action":"login","user":2}
    {"action":"login","user":2}
    .
    .
    .
    
    $ curl -s -T "test.txt" -H 'Content-type: application/json' --header "Transfer-Encoding: chunked"  http://localhost:8888/js/test.tag.here;

### msgpack

resource

    m

header

    Content-type: applicatoin/x-www-form/urlencoded

body

    msgpack=<msgpack data>
             hash.to_msgpack

### msgpack list

resource

    ms

header

    Content-type: applicatoin/x-www-form/urlencoded

body

    msgpack-list=<msgpack list data>
                  [hash,hash,hash].to_msgpack

### msgpack chunked

resource

    ms

header

    Content-type: application/x-msgpack
    Transfer-Encoding: chunked

body

    <msgpack chunk data>
     "#{hash.to_msgpack}#{hash.to_msgpack}"


Each event in the list will be sent to your output plugins as an individual
event. 

## Copyright

Copyright (c) 2013 hiro-su.

Based on the in_http plugin by FURUHASHI Sadayuki

 Apache License, Version 2.0
