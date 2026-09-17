%%
%% Copyright (c) 2026, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(codec_json_test).
-include_lib("eunit/include/eunit.hrl").
-include("codec_json.hrl").

codec_json_data_model_test() ->
    #json_object{} = #json_object{
        members = [
            {<<"name">>, #json_string{value = <<"Alice">>}},
            {<<"age">>, #json_number{literal = <<"30">>}},
            {<<"active">>, #json_bool{value = true}},
            {<<"children">>, #json_array{items = []}},
            {<<"spouse">>, #json_null{}}
        ]
    },
    ok.

codec_json_decode_literals_test() ->
    #json_null{} = codec_json:decode(<<"null">>),
    #json_bool{value = true} = codec_json:decode(<<" true ">>),
    #json_bool{value = false} = codec_json:decode(<<"\nfalse\r">>),
    #json_string{value = <<"hello">>} = codec_json:decode(<<"\"hello\"">>),
    #json_number{literal = <<"-12.34e+56">>} =
        codec_json:decode(<<"-12.34e+56">>).

codec_json_decode_arrays_and_objects_test() ->
    #json_array{
        items = [
            #json_number{literal = <<"1">>},
            #json_string{value = <<"two">>},
            #json_null{}
        ]
    } = codec_json:decode(<<"[1, \"two\", null]">>),

    #json_object{
        members = [
            {<<"id">>, #json_number{literal = <<"1">>}},
            {<<"id">>, #json_number{literal = <<"2">>}},
            {<<"ok">>, #json_bool{value = true}}
        ]
    } = codec_json:decode(<<"{\"id\":1,\"id\":2,\"ok\":true}">>).

codec_json_decode_string_escapes_test() ->
    #json_string{
        value = <<$", $\\, $/, $\b, $\f, $\n, $\r, $\t, 16#1D11E/utf8>>
    } = codec_json:decode(<<"\"\\\"\\\\\\/\\b\\f\\n\\r\\t\\uD834\\uDD1E\"">>).

codec_json_decode_errors_test() ->
    ?assertError({invalid_json, not_binary}, codec_json:decode("null")).

codec_json_try_decode_error_test() ->
    {error, {invalid_json, not_binary}} = codec_json:try_decode("null"),
    {error, {invalid_json, leading_zero}} = codec_json:try_decode(<<"01">>),
    {error, {invalid_json, trailing_array_comma}} =
        codec_json:try_decode(<<"[1,]">>),
    {error, {invalid_json, trailing_object_comma}} =
        codec_json:try_decode(<<"{\"a\":1,}">>),
    {error, {invalid_json, invalid_surrogate_pair}} =
        codec_json:try_decode(<<"\"\\uD834x\"">>).

codec_json_try_encode_error_test() ->
    {error, {invalid_json_node, invalid_node}} = codec_json:try_encode(#{}),
    {error, {invalid_json_node, invalid_number_literal}} =
        codec_json:try_encode(#json_number{literal = <<"01">>}),
    {error, {invalid_json_node, {invalid_string, invalid_utf8}}} =
        codec_json:try_encode(#json_string{value = <<16#FF>>}).

codec_json_encode_values_test() ->
    <<"null">> = codec_json:encode(#json_null{}),
    <<"true">> = codec_json:encode(#json_bool{value = true}),
    <<"false">> = codec_json:encode(#json_bool{value = false}),
    <<"-0.5E-10">> = codec_json:encode(#json_number{literal = <<"-0.5E-10">>}),
    <<"[]">> = codec_json:encode(#json_array{}),
    <<"[null,true]">> = codec_json:encode(#json_array{
        items = [#json_null{}, #json_bool{value = true}]
    }).

codec_json_encode_string_escapes_test() ->
    Value = <<$", $\\, $\b, $\f, $\n, $\r, $\t, 1, 16#1D11E/utf8>>,
    Expected = <<
        $",
        $\\, $",
        $\\, $\\,
        $\\, $b,
        $\\, $f,
        $\\, $n,
        $\\, $r,
        $\\, $t,
        $\\, $u, $0, $0, $0, $1,
        16#1D11E/utf8,
        $"
    >>,
    Expected = codec_json:encode(#json_string{value = Value}).

codec_json_encode_object_preserves_members_test() ->
    Json = #json_object{
        members = [
            {<<"id">>, #json_number{literal = <<"1">>}},
            {<<"id">>, #json_number{literal = <<"2">>}},
            {<<"name">>, #json_string{value = <<"Ada">>}}
        ]
    },
    <<"{\"id\":1,\"id\":2,\"name\":\"Ada\"}">> = codec_json:encode(Json).

codec_json_roundtrip_test() ->
    Json = #json_object{
        members = [
            {<<"list">>, #json_array{
                items = [
                    #json_number{literal = <<"1e400">>},
                    #json_string{value = <<"line\nbreak">>}
                ]
            }},
            {<<"empty">>, #json_object{}}
        ]
    },
    Json = codec_json:decode(codec_json:encode(Json)).
