# rubric

Rubric from your terminal — where your coding agents already are.

One call hands an agent everything left to do; the rest are how it reports
back. You sign in as yourself, and the machine becomes a session on your
account that you can sign out on its own.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/rahul-thatipamula/rubric-cli/main/install.sh | sh
```

Or take a binary from [Releases](../../releases) and put it on your PATH.
macOS and Linux, Intel and ARM. No runtime, no dependencies.

## Start

```sh
export RUBRIC_HOST=https://devrubric.tech
rubric login          # your password, and your 2FA code — no key to paste
rubric link           # tie this directory to a project
rubric brief          # what is left to do
```

## The loop

```sh
rubric brief                                  # project, features, open cases
rubric case show 42                           # one case in full
rubric case comment 42 -m "verified locally"  # say what you did, pass or fail
rubric case tick 42                           # only when it genuinely passes
rubric case ask 42 "which currency applies?"  # park it rather than guess
```

Case numbers are the ones shown in the app — `#42`, not an id to copy.

## For agents

Every command takes `--json`, and `rubric brief --json` returns the server's
own response untouched.

```sh
rubric prompt                 # what to paste to your coding agent
rubric brief --json | jq '.features[].testCases[].testCase.title'
```

## CI

A build server has nobody to type a password, so give it a session of its own.
The token is printed once and expires in 90 days by default.

```sh
rubric session create ci-deploy --expires 30
RUBRIC_TOKEN=rbs_… RUBRIC_HOST=https://devrubric.tech rubric brief --json
```

`rubric session list` shows everything signed in; `rubric session revoke <id>`
cuts one off immediately.

## Where it points

In order: `--host`, `RUBRIC_HOST`, the `.rubric.json` in this directory or a
parent, then the single host you are signed in to.

`.rubric.json` holds a project id and a host and no credential — commit it.

Full guide: https://devrubric.tech/cli
