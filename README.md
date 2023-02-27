# Kernel Streams [![Styled with Prettier](https://img.shields.io/badge/code_style-prettier-ff69b4.svg)](https://prettier.io) [![Commitizen Friendly](https://img.shields.io/badge/commitizen-friendly-brightgreen.svg)](http://commitizen.github.io/cz-cli/) [![License: LGPL3.0](https://img.shields.io/badge/License-LGPL%20v3-008033.svg)](https://opensource.org/licenses/lgpl-3.0)

This is a set of payment streaming contracts for open source contributors working on public goods.

It combines [Paul Razvan Berg's](https://github.com/PaulRBerg) work on both Sablier and Foundry templates. We are enormously grateful to him for both of these meaningful exmaples of the kinds of public goods we love working with, and are interested in creating ourselves.

**Note**: while Paul's foundry template is licensed under MIT, we have followed the GPL-3.0 licensing for Sablier, as this holds the functionality we intend to use.

## Getting Started

You can clone the repo and set it up manually:

```sh
git clone --recurse-submodules https://github.com/kernel-community/streams.git
cd streams
yarn
```

If you prefer to install using foundry directly:

```sh
forge init kernel-streams --template https://github.com/kernel-community/streams
cd kernel-streams
yarn # install Solhint, Prettier, and other Node.js deps
```

If this is your first time with Foundry, check out the
[installation](https://github.com/foundry-rs/foundry#installation) instructions.

## Work TODO

1. Tests
2. Deploy scripts

## Features

If you're interested in exploring Foundry in more detail, you should look at the
[Foundry Book](https://book.getfoundry.sh/). In particular, you may be interested in reading the
[Writing Tests](https://book.getfoundry.sh/forge/writing-tests.html) tutorial.

### Sensible Defaults

This template comes with a set of sensible default configurations for you to use. These defaults can be found in the
following files:

```text
├── .editorconfig
├── .gitignore
├── .prettierignore
├── .prettierrc.yml
├── .solhint.json
├── .yarnrc.yml
├── foundry.toml
└── remappings.txt
```

### VSCode Integration

This template is IDE agnostic, but for the best user experience, you may want to use it in VSCode alongside Juan
Blanco's [Solidity extension](https://github.com/juanfranblanco/vscode-solidity).

For guidance on how to integrate a Foundry project in VSCode, please refer to this
[guide](https://book.getfoundry.sh/config/vscode).

## Writing Tests

To write a new test contract, you start by importing [PRBTest](https://github.com/PaulRBerg/prb-test) and inherit from
it in your test contract. PRBTest comes with a pre-instantiated [cheatcodes](https://book.getfoundry.sh/cheatcodes/)
environment accessible via the `vm` property. If you would like to view the logs in the terminal output you can add the
`-vvv` flag and use [console.log](https://book.getfoundry.sh/faq?highlight=console.log#how-do-i-use-consolelog).

This template comes with an example test contract [Foo.t.sol](./test/Foo.t.sol).

## Usage

This is a list of the most frequently needed commands.

### Build

Build the contracts:

```sh
$ forge build
```

### Clean

Delete the build artifacts and cache directories:

```sh
$ forge clean
```

### Compile

Compile the contracts:

```sh
$ forge build
```

### Coverage

Get a test coverage report:

```sh
$ forge coverage
```

### Deploy

Deploy to Anvil:

```sh
$ forge script script/DeployStreams.s.sol --broadcast --fork-url http://localhost:8545
```

For this script to work, you need to have a `MNEMONIC` environment variable set to a valid
[BIP39 mnemonic](https://iancoleman.io/bip39/).

For instructions on how to deploy to a testnet or mainnet, check out the
[Solidity Scripting](https://book.getfoundry.sh/tutorials/solidity-scripting.html) tutorial.

### Format

Format the contracts:

```sh
$ forge fmt
```

### Gas Usage

Get a gas report:

```sh
$ forge test --gas-report
```

### Lint

Lint the contracts:

```sh
$ yarn lint
```

### Test

Run the tests:

```sh
$ forge test
```

## What's Inside

- [Forge](https://github.com/foundry-rs/foundry/blob/master/forge): compile, test, fuzz, format, and deploy smart
  contracts
- [PRBTest](https://github.com/PaulRBerg/prb-test): modern collection of testing assertions and logging utilities
- [Forge Std](https://github.com/foundry-rs/forge-std): collection of helpful contracts and cheatcodes for testing
- [Solhint](https://github.com/protofire/solhint): linter for Solidity code
- [Prettier Plugin Solidity](https://github.com/prettier-solidity/prettier-plugin-solidity): code formatter for
  non-Solidity files
