%%
%% Copyright (c) 2026, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(codec_json).
-moduledoc """
JSON encoder and decoder.

It implements RFC 8259 with explicit records instead of native Erlang maps
or lists. `encode/1` and `decode/1` return the binary or node directly and
raise documented codec errors. `try_encode/1` and `try_decode/1` wrap the
same behavior in `{ok, Value}` or `{error, Error}`.

```erlang
-include_lib("codec_json/include/codec_json.hrl").

Node = #json_object{members = [
    {<<"ok">>, #json_bool{value = true}}
]},
<<"{\"ok\":true}">> = codec_json:encode(Node),
Node = codec_json:decode(<<"{\"ok\":true}">>).
```

Numbers keep their exact JSON literal. Object members keep source order and
duplicate names. A leading UTF-8 BOM is rejected, and nesting deeper than
512 is rejected.
""".

-export_type([
    json_node/0,
    string_value/0,
    object_name/0,
    number_literal/0,
    object_member/0,
    decode_error/0,
    encode_error/0
]).

-export([encode/1, decode/1]).
-export([try_encode/1, try_decode/1]).

-include("codec_json.hrl").

-define(MAX_NESTING_DEPTH, 512).

-doc "A JSON string or object name as a UTF-8 binary.".
-type string_value() :: binary().

-doc "An object member name.".
-type object_name() :: string_value().

-doc "A JSON number stored as its exact literal text.".
-type number_literal() :: binary().

-doc "An object member as a name and value pair.".
-type object_member() :: {object_name(), json_node()}.

-doc "A JSON value in the record-based data model.".
-type json_node() ::
    #json_null{} |
    #json_bool{} |
    #json_number{} |
    #json_string{} |
    #json_array{} |
    #json_object{}
.

-doc "A documented decode failure.".
-type decode_error() :: {invalid_json, Reason :: term()}.

-doc "A documented encode failure.".
-type encode_error() :: {invalid_json_node, Reason :: term()}.

-doc """
Encode a JSON node into UTF-8 JSON text.

It returns the JSON text directly. It raises `error({invalid_json_node,
Reason})` when the input is not a valid JSON node.
""".
-spec encode(Node :: json_node()) -> binary().
encode(Node) ->
    iolist_to_binary(encode_node(Node)).

-doc """
Safely encode a JSON node into UTF-8 JSON text.

It returns `{ok, Binary}` on success or `{error, Error}` for documented codec
errors.
""".
-spec try_encode(Term :: term()) -> {ok, binary()} | {error, encode_error()}.
try_encode(Term) ->
    try {ok, encode(Term)}
    catch
        error:{invalid_json_node, _} = Error ->
            {error, Error}
    end.

-doc """
Decode UTF-8 JSON text.

It returns the JSON data model directly. It raises `error({invalid_json,
Reason})` when the input is not valid JSON.
""".
-spec decode(Binary :: binary()) -> json_node().
decode(Binary) when is_binary(Binary) ->
    {Node, Rest} = parse_value(skip_ws(Binary), 0),
    case skip_ws(Rest) of
        <<>> ->
            Node;
        _Rest ->
            invalid_json(trailing_data)
    end;
decode(_Binary) ->
    erlang:error({invalid_json, not_binary}).

-doc """
Safely decode UTF-8 JSON text.

It returns `{ok, Node}` on success or `{error, Error}` for documented codec
errors.
""".
-spec try_decode(Term :: term()) -> {ok, json_node()} | {error, decode_error()}.
try_decode(Term) ->
    try {ok, decode(Term)}
    catch
        error:{invalid_json, _} = Error ->
            {error, Error}
    end.

-spec encode_node(term()) -> iolist().
encode_node(#json_null{}) ->
    <<"null">>;
encode_node(#json_bool{value = true}) ->
    <<"true">>;
encode_node(#json_bool{value = false}) ->
    <<"false">>;
encode_node(#json_bool{}) ->
    invalid_json_node(invalid_bool);
encode_node(#json_number{literal = Literal}) when is_binary(Literal) ->
    case valid_number_literal(Literal) of
        true ->
            Literal;
        false ->
            invalid_json_node(invalid_number_literal)
    end;
encode_node(#json_number{}) ->
    invalid_json_node(invalid_number);
encode_node(#json_string{value = Value}) when is_binary(Value) ->
    encode_string(Value);
encode_node(#json_string{}) ->
    invalid_json_node(invalid_string);
encode_node(#json_array{items = Items}) when is_list(Items) ->
    [$[, join_encoded([encode_node(Item) || Item <- Items]), $]];
encode_node(#json_array{}) ->
    invalid_json_node(invalid_array);
encode_node(#json_object{members = Members}) when is_list(Members) ->
    [$\{, join_encoded([encode_member(Member) || Member <- Members]), $\}];
encode_node(#json_object{}) ->
    invalid_json_node(invalid_object);
encode_node(_Term) ->
    invalid_json_node(invalid_node).

-spec encode_member(term()) -> iolist().
encode_member({Name, Value}) when is_binary(Name) ->
    [encode_string(Name), $:, encode_node(Value)];
encode_member(_Term) ->
    invalid_json_node(invalid_object_member).

-spec join_encoded([iolist()]) -> iolist().
join_encoded([]) ->
    [];
join_encoded([Item]) ->
    Item;
join_encoded([Item | Items]) ->
    [Item, $, | join_encoded(Items)].

-spec encode_string(binary()) -> iolist().
encode_string(Value) ->
    [$", encode_string_chars(Value), $"].

-spec encode_string_chars(binary()) -> iolist().
encode_string_chars(<<>>) ->
    [];
encode_string_chars(<<$", Rest/binary>>) ->
    [$\\, $" | encode_string_chars(Rest)];
encode_string_chars(<<$\\, Rest/binary>>) ->
    [$\\, $\\ | encode_string_chars(Rest)];
encode_string_chars(<<$\b, Rest/binary>>) ->
    [$\\, $b | encode_string_chars(Rest)];
encode_string_chars(<<$\f, Rest/binary>>) ->
    [$\\, $f | encode_string_chars(Rest)];
encode_string_chars(<<$\n, Rest/binary>>) ->
    [$\\, $n | encode_string_chars(Rest)];
encode_string_chars(<<$\r, Rest/binary>>) ->
    [$\\, $r | encode_string_chars(Rest)];
encode_string_chars(<<$\t, Rest/binary>>) ->
    [$\\, $t | encode_string_chars(Rest)];
encode_string_chars(<<Codepoint/utf8, Rest/binary>>) when Codepoint < 16#20 ->
    [unicode_escape(Codepoint) | encode_string_chars(Rest)];
encode_string_chars(<<Codepoint/utf8, Rest/binary>>) ->
    [<<Codepoint/utf8>> | encode_string_chars(Rest)];
encode_string_chars(_InvalidUtf8) ->
    invalid_json_node({invalid_string, invalid_utf8}).

-spec unicode_escape(0..16#10FFFF) -> binary().
unicode_escape(Codepoint) when Codepoint =< 16#FFFF ->
    <<
        $\\,
        $u,
        (hex_digit((Codepoint bsr 12) band 16#F)),
        (hex_digit((Codepoint bsr 8) band 16#F)),
        (hex_digit((Codepoint bsr 4) band 16#F)),
        (hex_digit(Codepoint band 16#F))
    >>;
unicode_escape(Codepoint) ->
    High = 16#D800 + ((Codepoint - 16#10000) bsr 10),
    Low = 16#DC00 + ((Codepoint - 16#10000) band 16#3FF),
    <<(unicode_escape(High))/binary, (unicode_escape(Low))/binary>>.

-spec hex_digit(0..15) -> byte().
hex_digit(Value) when Value < 10 ->
    $0 + Value;
hex_digit(Value) ->
    $a + (Value - 10).

-spec valid_number_literal(binary()) -> boolean().
valid_number_literal(Literal) ->
    try parse_number(Literal) of
        {#json_number{}, <<>>} ->
            true;
        _Other ->
            false
    catch
        error:{invalid_json, _Reason} ->
            false
    end.

-spec parse_value(binary(), non_neg_integer()) -> {json_node(), binary()}.
parse_value(_Binary, Depth) when Depth > ?MAX_NESTING_DEPTH ->
    invalid_json(max_nesting_depth_exceeded);
parse_value(<<"null", Rest/binary>>, _Depth) ->
    {#json_null{}, Rest};
parse_value(<<"true", Rest/binary>>, _Depth) ->
    {#json_bool{value = true}, Rest};
parse_value(<<"false", Rest/binary>>, _Depth) ->
    {#json_bool{value = false}, Rest};
parse_value(<<"\"", Rest/binary>>, _Depth) ->
    {String, Rest1} = parse_string(Rest),
    {#json_string{value = String}, Rest1};
parse_value(<<"[", Rest/binary>>, Depth) ->
    parse_array(skip_ws(Rest), Depth, []);
parse_value(<<"{", Rest/binary>>, Depth) ->
    parse_object(skip_ws(Rest), Depth, []);
parse_value(<<Byte, _Rest/binary>> = Binary, _Depth)
        when Byte =:= $-; Byte >= $0, Byte =< $9 ->
    parse_number(Binary);
parse_value(<<>>, _Depth) ->
    invalid_json(unexpected_end);
parse_value(<<Byte, _Rest/binary>>, _Depth) ->
    invalid_json({unexpected_byte, Byte}).

-spec parse_array(binary(), non_neg_integer(), [json_node()]) ->
    {#json_array{}, binary()}.
parse_array(<<"]", Rest/binary>>, _Depth, []) ->
    {#json_array{items = []}, Rest};
parse_array(<<"]", _Rest/binary>>, _Depth, _Items) ->
    invalid_json(trailing_array_comma);
parse_array(Binary, Depth, Items) ->
    {Item, Rest0} = parse_value(Binary, Depth + 1),
    Rest1 = skip_ws(Rest0),
    case Rest1 of
        <<",", Rest2/binary>> ->
            parse_array(skip_ws(Rest2), Depth, [Item | Items]);
        <<"]", Rest2/binary>> ->
            {#json_array{items = lists:reverse([Item | Items])}, Rest2};
        <<>> ->
            invalid_json(unclosed_array);
        <<Byte, _Rest/binary>> ->
            invalid_json({expected_array_separator_or_end, Byte})
    end.

-spec parse_object(binary(), non_neg_integer(), [object_member()]) ->
    {#json_object{}, binary()}.
parse_object(<<"}", Rest/binary>>, _Depth, []) ->
    {#json_object{members = []}, Rest};
parse_object(<<"}", _Rest/binary>>, _Depth, _Members) ->
    invalid_json(trailing_object_comma);
parse_object(<<"\"", Rest/binary>>, Depth, Members) ->
    {Name, Rest0} = parse_string(Rest),
    Rest1 = skip_ws(Rest0),
    Rest2 = case Rest1 of
        <<":", AfterColon/binary>> ->
            skip_ws(AfterColon);
        <<>> ->
            invalid_json(unclosed_object);
        <<Byte1, _Rest1/binary>> ->
            invalid_json({expected_name_separator, Byte1})
    end,
    {Value, Rest3} = parse_value(Rest2, Depth + 1),
    Rest4 = skip_ws(Rest3),
    case Rest4 of
        <<",", Rest5/binary>> ->
            parse_object(skip_ws(Rest5), Depth, [{Name, Value} | Members]);
        <<"}", Rest5/binary>> ->
            {#json_object{members = lists:reverse([{Name, Value} | Members])}, Rest5};
        <<>> ->
            invalid_json(unclosed_object);
        <<Byte2, _Rest2/binary>> ->
            invalid_json({expected_object_separator_or_end, Byte2})
    end;
parse_object(<<>>, _Depth, _Members) ->
    invalid_json(unclosed_object);
parse_object(<<Byte, _Rest/binary>>, _Depth, _Members) ->
    invalid_json({expected_object_name_or_end, Byte}).

-spec parse_string(binary()) -> {binary(), binary()}.
parse_string(Binary) ->
    parse_string_chars(Binary, []).

-spec parse_string_chars(binary(), iolist()) -> {binary(), binary()}.
parse_string_chars(<<"\"", Rest/binary>>, Acc) ->
    {iolist_to_binary(lists:reverse(Acc)), Rest};
parse_string_chars(<<"\\", Rest/binary>>, Acc) ->
    {Escaped, Rest1} = parse_escape(Rest),
    parse_string_chars(Rest1, [Escaped | Acc]);
parse_string_chars(<<Byte, _Rest/binary>>, _Acc) when Byte < 16#20 ->
    invalid_json(unescaped_control_character);
parse_string_chars(<<Codepoint/utf8, Rest/binary>>, Acc) ->
    parse_string_chars(Rest, [<<Codepoint/utf8>> | Acc]);
parse_string_chars(<<>>, _Acc) ->
    invalid_json(unclosed_string);
parse_string_chars(_InvalidUtf8, _Acc) ->
    invalid_json(invalid_utf8).

-spec parse_escape(binary()) -> {binary(), binary()}.
parse_escape(<<"\"", Rest/binary>>) ->
    {<<"\"">>, Rest};
parse_escape(<<"\\", Rest/binary>>) ->
    {<<"\\">>, Rest};
parse_escape(<<"/", Rest/binary>>) ->
    {<<"/">>, Rest};
parse_escape(<<"b", Rest/binary>>) ->
    {<<"\b">>, Rest};
parse_escape(<<"f", Rest/binary>>) ->
    {<<"\f">>, Rest};
parse_escape(<<"n", Rest/binary>>) ->
    {<<"\n">>, Rest};
parse_escape(<<"r", Rest/binary>>) ->
    {<<"\r">>, Rest};
parse_escape(<<"t", Rest/binary>>) ->
    {<<"\t">>, Rest};
parse_escape(<<"u", Rest/binary>>) ->
    parse_unicode_escape(Rest);
parse_escape(<<>>) ->
    invalid_json(incomplete_escape);
parse_escape(<<Byte, _Rest/binary>>) ->
    invalid_json({invalid_escape, Byte}).

-spec parse_unicode_escape(binary()) -> {binary(), binary()}.
parse_unicode_escape(Binary) ->
    {CodeUnit, Rest} = parse_hex4(Binary),
    case CodeUnit of
        High when High >= 16#D800, High =< 16#DBFF ->
            parse_low_surrogate(High, Rest);
        Low when Low >= 16#DC00, Low =< 16#DFFF ->
            invalid_json(lone_low_surrogate);
        Codepoint ->
            {<<Codepoint/utf8>>, Rest}
    end.

-spec parse_low_surrogate(16#D800..16#DBFF, binary()) -> {binary(), binary()}.
parse_low_surrogate(High, <<"\\u", Rest/binary>>) ->
    {Low, Rest1} = parse_hex4(Rest),
    case Low of
        _ when Low >= 16#DC00, Low =< 16#DFFF ->
            Codepoint = 16#10000 + ((High - 16#D800) bsl 10) + (Low - 16#DC00),
            {<<Codepoint/utf8>>, Rest1};
        _Other ->
            invalid_json(invalid_surrogate_pair)
    end;
parse_low_surrogate(_High, _Rest) ->
    invalid_json(invalid_surrogate_pair).

-spec parse_hex4(binary()) -> {0..16#FFFF, binary()}.
parse_hex4(<<A, B, C, D, Rest/binary>>) ->
    case {hex_value(A), hex_value(B), hex_value(C), hex_value(D)} of
        {{ok, A1}, {ok, B1}, {ok, C1}, {ok, D1}} ->
            {((A1 bsl 12) bor (B1 bsl 8) bor (C1 bsl 4) bor D1), Rest};
        _Other ->
            invalid_json(invalid_unicode_escape)
    end;
parse_hex4(_TooShort) ->
    invalid_json(invalid_unicode_escape).

-spec hex_value(byte()) -> {ok, 0..15} | error.
hex_value(Byte) when Byte >= $0, Byte =< $9 ->
    {ok, Byte - $0};
hex_value(Byte) when Byte >= $a, Byte =< $f ->
    {ok, Byte - $a + 10};
hex_value(Byte) when Byte >= $A, Byte =< $F ->
    {ok, Byte - $A + 10};
hex_value(_Byte) ->
    error.

-spec parse_number(binary()) -> {#json_number{}, binary()}.
parse_number(Binary) ->
    Rest0 = parse_minus(Binary),
    Rest1 = parse_int(Rest0),
    Rest2 = parse_frac(Rest1),
    Rest3 = parse_exp(Rest2),
    Length = byte_size(Binary) - byte_size(Rest3),
    Literal = binary:part(Binary, 0, Length),
    {#json_number{literal = Literal}, Rest3}.

-spec parse_minus(binary()) -> binary().
parse_minus(<<"-", Rest/binary>>) ->
    Rest;
parse_minus(Binary) ->
    Binary.

-spec parse_int(binary()) -> binary().
parse_int(<<"0", Rest/binary>>) ->
    case Rest of
        <<Digit, _/binary>> when Digit >= $0, Digit =< $9 ->
            invalid_json(leading_zero);
        _Other ->
            Rest
    end;
parse_int(<<Digit, Rest/binary>>) when Digit >= $1, Digit =< $9 ->
    consume_digits(Rest);
parse_int(_Binary) ->
    invalid_json(invalid_number).

-spec parse_frac(binary()) -> binary().
parse_frac(<<".", Rest/binary>>) ->
    consume_one_or_more_digits(Rest);
parse_frac(Binary) ->
    Binary.

-spec parse_exp(binary()) -> binary().
parse_exp(<<"e", Rest/binary>>) ->
    parse_exp_digits(Rest);
parse_exp(<<"E", Rest/binary>>) ->
    parse_exp_digits(Rest);
parse_exp(Binary) ->
    Binary.

-spec parse_exp_digits(binary()) -> binary().
parse_exp_digits(<<"+", Rest/binary>>) ->
    consume_one_or_more_digits(Rest);
parse_exp_digits(<<"-", Rest/binary>>) ->
    consume_one_or_more_digits(Rest);
parse_exp_digits(Binary) ->
    consume_one_or_more_digits(Binary).

-spec consume_one_or_more_digits(binary()) -> binary().
consume_one_or_more_digits(<<Digit, Rest/binary>>) when Digit >= $0, Digit =< $9 ->
    consume_digits(Rest);
consume_one_or_more_digits(_Binary) ->
    invalid_json(invalid_number).

-spec consume_digits(binary()) -> binary().
consume_digits(<<Digit, Rest/binary>>) when Digit >= $0, Digit =< $9 ->
    consume_digits(Rest);
consume_digits(Binary) ->
    Binary.

-spec skip_ws(binary()) -> binary().
skip_ws(<<16#20, Rest/binary>>) ->
    skip_ws(Rest);
skip_ws(<<16#09, Rest/binary>>) ->
    skip_ws(Rest);
skip_ws(<<16#0A, Rest/binary>>) ->
    skip_ws(Rest);
skip_ws(<<16#0D, Rest/binary>>) ->
    skip_ws(Rest);
skip_ws(Binary) ->
    Binary.

-spec invalid_json(term()) -> no_return().
invalid_json(Reason) ->
    erlang:error({invalid_json, Reason}).

-spec invalid_json_node(term()) -> no_return().
invalid_json_node(Reason) ->
    erlang:error({invalid_json_node, Reason}).
