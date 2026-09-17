# codec-json — Rules

Pure Erlang JSON encoder and decoder in the `data-codec` family.

## Key Rules
- Target RFC 8259 / STD 90. Do not add JSON5, JSONC, comments, or trailing commas.
- Keep `encode/1` and `decode/1` as direct-return functions, with `try_encode/1` and `try_decode/1` as the safe variants.
- Store numbers as exact JSON literals in `#json_number.literal`.
- Store object members as an ordered list; preserve duplicate names.
- Reject a leading UTF-8 BOM and nesting deeper than 512.
- Run the vendored JSONTestSuite corpus as part of ordinary `rebar3 eunit`.
