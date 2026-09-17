# JSON encoder/decoder

[![Erlangsters Repository](https://img.shields.io/badge/erlangsters-codec--json-%23a90432)](https://github.com/erlangsters/codec-json)
![Supported Erlang/OTP Versions](https://img.shields.io/badge/erlang%2Fotp-27%7C28%7C29-%23a90432)
![Current Version](https://img.shields.io/badge/version-0.0.1-%23354052)
![License](https://img.shields.io/github/license/erlangsters/codec-json)
[![Build Status](https://img.shields.io/github/actions/workflow/status/erlangsters/codec-json/build.yml)](https://github.com/erlangsters/codec-json/actions/workflows/build.yml)
[![Documentation Link](https://img.shields.io/badge/documentation-available-yellow)](http://erlangsters.github.io/codec-json/)

A clean JSON encoder/decoder for the BEAM, meant to be unambiguous, not fast.

```erlang
{ok, Data} = file:read_file("data.json").

Json = codec_json:decode(Data).
Encoded = codec_json:encode(Json).
```

For callers that treat malformed input as expected data, use the safe variants.

```erlang
{ok, Json} = codec_json:try_decode(Data).
{ok, Encoded} = codec_json:try_encode(Json).
```

Written by the Erlangsters [community](https://about.erlangsters.org/) and
released under the MIT [license](https://opensource.org/license/mit).

## Getting started

Include the public records when constructing or matching JSON values.

```erlang
-include_lib("codec_json/include/codec_json.hrl").
```

```erlang
Json = #json_object{
    members = [
        {<<"name">>, #json_string{value = <<"Ada">>}},
        {<<"active">>, #json_bool{value = true}},
        {<<"score">>, #json_number{literal = <<"1e400">>}},
        {<<"tags">>, #json_array{items = [#json_string{value = <<"math">>}]}},
        {<<"notes">>, #json_null{}}
    ]
},
Data = codec_json:encode(Json),
Json = codec_json:decode(Data).
```

The library targets RFC 8259. Numbers are stored as their exact JSON literals. Object members are stored as an ordered list, so duplicate names and source order are preserved.

A leading UTF-8 BOM is rejected. Nesting deeper than 512 is rejected. Encoded strings use a defined escape set, so decode-then-encode is not always byte-identical to the input.

## Installing the library

To use `codec-json` in a `rebar3` project, add it to your `rebar.config`.

```erlang
{deps, [
  {codec_json, {git, "https://github.com/erlangsters/codec-json.git", {tag, "0.0.1"}}}
]}.
```
