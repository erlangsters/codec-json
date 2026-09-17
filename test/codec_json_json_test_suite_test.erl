%%
%% Copyright (c) 2026, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%
-module(codec_json_json_test_suite_test).
-include_lib("eunit/include/eunit.hrl").

-define(SUITE_DIR_ENV, "CODEC_JSON_JSON_TEST_SUITE_DIR").
-define(DEFAULT_SUITE_DIR, "test/fixtures/json_test_suite").

json_test_suite_test_() ->
    json_test_suite_cases().

json_test_suite_cases() ->
    ParsingDir = json_test_suite_parsing_dir(),
    Files = lists:sort(filelib:wildcard(filename:join(ParsingDir, "*.json"))),
    Cases = [json_test_suite_case(File) || File <- Files, is_suite_case(File)],
    case Cases of
        [] ->
            [{"JSONTestSuite fixtures present", fun() ->
                erlang:error({json_test_suite_no_cases, ParsingDir})
            end}];
        _ ->
            Cases
    end.

json_test_suite_parsing_dir() ->
    Root = case os:getenv(?SUITE_DIR_ENV) of
        false ->
            ?DEFAULT_SUITE_DIR;
        Directory ->
            Directory
    end,
    Candidate = filename:join(Root, "test_parsing"),
    case filelib:is_dir(Candidate) of
        true ->
            Candidate;
        false ->
            Root
    end.

is_suite_case(File) ->
    case filename:basename(File) of
        "y_" ++ _Name ->
            true;
        "n_" ++ _Name ->
            true;
        "i_" ++ _Name ->
            true;
        _Name ->
            false
    end.

json_test_suite_case(File) ->
    Name = filename:basename(File),
    {Name, fun() -> run_json_test_suite_case(File) end}.

run_json_test_suite_case(File) ->
    {ok, Json} = file:read_file(File),
    case expected_result(filename:basename(File)) of
        accept ->
            assert_json_test_suite_accepts(File, Json);
        reject ->
            assert_json_test_suite_rejects(File, Json)
    end.

expected_result("y_" ++ _Name) ->
    accept;
expected_result("n_" ++ _Name) ->
    reject;
expected_result("i_number_" ++ _Name) ->
    accept;
expected_result("i_structure_500_nested_arrays.json") ->
    accept;
expected_result("i_string_" ++ _Name) ->
    reject;
expected_result("i_object_key_lone_2nd_surrogate.json") ->
    reject;
expected_result("i_structure_UTF-8_BOM_empty_object.json") ->
    reject.

assert_json_test_suite_accepts(File, Json) ->
    case codec_json:try_decode(Json) of
        {ok, _Node} ->
            ok;
        {error, Error} ->
            erlang:error({json_test_suite_expected_accept, File, Error})
    end.

assert_json_test_suite_rejects(File, Json) ->
    case codec_json:try_decode(Json) of
        {error, {invalid_json, _Reason}} ->
            ok;
        {ok, Node} ->
            erlang:error({json_test_suite_expected_reject, File, Node})
    end.
