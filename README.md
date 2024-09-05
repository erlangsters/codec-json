# JSON encoder/decoder

A clean JSON encoder/decoder for Erlang, meant to be unambiguous, not fast.

```erlang
{ok, Data} = file:read_file("data.json").

{ok, Json} = codec_json:decode(Data).
{ok, Data} = codec_json:encode(Json).
```

🚧 It's a work-in-progress, use at your own risk.

Written by the Erlangsters [community](https://www.erlangsters.org/) and
released under the MIT [license](https://opensource.org/license/mit).

## Getting started

To be written.

## Using it in your project

With the **Rebar3** build system, add the following to the `rebar.config` file
of your project.

```
{deps, [
  {codec_json, {git, "https://github.com/erlangsters/codec-json.git", {tag, "master"}}}
]}.
```

If you happen to use the **Erlang.mk** build system, then add the following to
your Makefile.

```
BUILD_DEPS = codec_json
dep_codec_json = git https://github.com/erlangsters/codec-json master
```

In practice, you want to replace the branch "master" with a specific "tag" to
avoid breaking your project if incompatible changes are made.
