%%
%% Copyright (c) 2025, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.txt file that
%% can be found at the root of the project directory.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>, April 2025
%%
-module(codec_json).
-moduledoc """
To be written.
""".

-export([encode/1]).
-export([decode/1]).

%%
%% JSON encoder/decoder.
%%

-doc "To be written.".
-spec encode(Term :: term()) -> binary().
encode(Term) ->
    Term.

-doc "To be written.".
-spec decode(Binary :: binary()) -> term().
decode(Binary) ->
    Binary.
