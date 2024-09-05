%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.txt file that
%% can be found at the root of the project directory.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>, April 2025
%%
-module(codec_json_test).
-include_lib("eunit/include/eunit.hrl").

codec_json_test() ->
    codec_json:encode(42),
    codec_json:decode(<<42>>),

    ok.
