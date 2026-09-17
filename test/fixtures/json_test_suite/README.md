# JSONTestSuite fixtures

This directory vendors the parser conformance fixtures from
`nst/JSONTestSuite`.

- Source: https://github.com/nst/JSONTestSuite
- Revision: `1ef36fa01286573e846ac449e8683f8833c5b26a`
- Included corpus: `test_parsing/*.json`
- Included metadata: upstream `LICENSE` and `UPSTREAM_README.md`

Ordinary `rebar3 eunit` runs this corpus. Override the fixture directory with
`CODEC_JSON_JSON_TEST_SUITE_DIR` when needed.
