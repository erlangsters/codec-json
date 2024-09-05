-module(codec_json).

-export([encode/1]).
-export([decode/1]).

%%
%% JSON encoder/decoder.
%%

-spec encode(Term :: term()) -> binary().
encode(Term) ->
    Term.

-spec decode(Binary :: binary()) -> term().
decode(Binary) ->
    Binary.
