[![add-on registry](https://img.shields.io/badge/DDEV-Add--on_Registry-blue)](https://addons.ddev.com)
[![tests](https://github.com/e0ipso/ddev-drupalorg-cli/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/e0ipso/ddev-drupalorg-cli/actions/workflows/tests.yml?query=branch%3Amain)
[![last commit](https://img.shields.io/github/last-commit/e0ipso/ddev-drupalorg-cli)](https://github.com/e0ipso/ddev-drupalorg-cli/commits)
[![release](https://img.shields.io/github/v/release/e0ipso/ddev-drupalorg-cli)](https://github.com/e0ipso/ddev-drupalorg-cli/releases/latest)

# DDEV Drupal.org CLI

## Overview

This add-on installs [mglaman/drupalorg-cli](https://github.com/mglaman/drupalorg-cli) globally inside the DDEV web container, together with its bash completion script. Once installed, the `drupalorg` command is available on `PATH` in the web container.

## Installation

```bash
ddev add-on get e0ipso/ddev-drupalorg-cli
ddev restart
```

After installation, commit the `.ddev` directory to version control.

## Usage

Run the CLI inside the web container:

```bash
ddev exec drupalorg --version
ddev exec drupalorg issue:info 3141592
```

Or open an interactive shell (where bash completion is active):

```bash
ddev ssh
drupalorg <TAB>
```

The PHAR is fetched from the [latest GitHub release](https://github.com/mglaman/drupalorg-cli/releases/latest) at web-image build time. To upgrade to a newer upstream release, rebuild the image:

```bash
ddev debug refresh
```

## How it works

| File | Purpose |
| ---- | ------- |
| `web-build/Dockerfile.drupalorg-cli` | Downloads `drupalorg.phar` to `/usr/local/bin/drupalorg` and the completion script to `/etc/bash_completion.d/drupalorg` during the web-image build. |

## Credits

**Contributed and maintained by [@e0ipso](https://github.com/e0ipso)**
