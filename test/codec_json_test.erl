-module(codec_json_test).
-include_lib("eunit/include/eunit.hrl").

codec_json_test() ->
    codec_json:encode(42),
    codec_json:decode(<<42>>),

    ok.
