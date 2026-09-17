%%
%% Copyright (c) 2026, Byteplug LLC.
%%
%% This source file is part of a project made by the Erlangsters community and
%% is released under the MIT license. Please refer to the LICENSE.md file that
%% can be found at the root of the project repository.
%%
%% Written by Jonathan De Wachter <jonathan.dewachter@byteplug.io>
%%

-record(json_null, {}).

-record(json_bool, {
    value :: boolean()
}).

-record(json_number, {
    literal :: codec_json:number_literal()
}).

-record(json_string, {
    value :: codec_json:string_value()
}).

-record(json_array, {
    items = [] :: [codec_json:json_node()]
}).

-record(json_object, {
    members = [] :: [codec_json:object_member()]
}).
