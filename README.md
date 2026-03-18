# aem-tools

`aem-tools` is a small, focused shell toolkit for installing Adobe Experience Manager content packages and OSGi bundles from the terminal with safer defaults, clearer feedback, and a polished interactive workflow.

The project is intentionally small, but it aims to feel like professional infrastructure: predictable behavior, good terminal UX, built-in help, dry-run support, and a clean path to local use or open-source publication.

## Why This Exists

AEM package and bundle installs are common development tasks, but the default browser-driven workflow is slower than it needs to be and ad hoc shell snippets tend to grow sharp edges quickly. `aem-tools` packages those tasks into a few dependable commands that are:

- quick to run from any project directory
- explicit about what they will do
- safe to debug before execution
- pleasant to use repeatedly

## Commands

- `aem-install`
  Front-door wrapper that dispatches by artifact type.
  `.zip` routes to `aem-package-install`; `.jar` routes to `aem-bundle-install`.
- `aem-package-install`
  Installs AEM content packages using Package Manager in extract-only mode.
- `aem-bundle-install`
  Installs or updates OSGi bundles through the Felix Web Console.

## Features

- Auto-detects running local AEM instances from `quickstart.jar` process arguments.
- Offers an interactive instance picker with arrow keys and `j`/`k`.
- Shows upload progress in interactive terminals.
- Supports `--dry-run` for request inspection and safer debugging.
- Prints built-in usage/help when invoked incorrectly.
- Keeps stdout and stderr separated so command substitution remains reliable.
- Uses conservative input validation for ports, files, and option values.
- Preserves a clean front-door command while still exposing explicit specialized commands.

## Installation

The simplest local setup is to keep the toolkit under a directory already on your `PATH`.

```bash
~/bin/aem-tools/bin/aem-install
~/bin/aem-tools/bin/aem-package-install
~/bin/aem-tools/bin/aem-bundle-install
```

You can either call the canonical scripts directly or create wrappers/aliases such as:

```bash
alias aempkg="$HOME/bin/aem-package-install"
alias aembundle="$HOME/bin/aem-bundle-install"
alias aeminstall="$HOME/bin/aem-install"
```

`aem-tools/bin` is the canonical source of truth for the project on both macOS and Linux. Any older standalone copies outside this directory should be treated as deprecated compatibility copies.

## Quick Start

```bash
aem-install my-package.zip
aem-install my-bundle.jar

aem-package-install --shallow my-package.zip
aem-bundle-install --no-refresh --start-level 15 my-bundle.jar

aem-package-install --dry-run my-package.zip
aem-bundle-install --dry-run my-bundle.jar
```

## Command Behavior

### `aem-install`

- Accepts a `.zip` or `.jar` artifact and dispatches to the appropriate installer.
- Passes most options through to the target installer unchanged.
- Exists as a convenience layer; use the direct commands for installer-specific help.

### `aem-package-install`

- Installs content packages in extract-only mode.
- Extracts subpackages by default.
- Use `--shallow` to disable subpackage extraction.

### `aem-bundle-install`

- Uploads bundles to `/system/console/bundles`.
- Supports refresh and bundle start toggles.
- Supports configurable start level for newly installed bundles.

## Design Principles

- Safe by default
  Validate inputs, prefer explicit behavior, and expose a dry-run path.
- Friendly in the terminal
  Terminal UI should feel intentional, readable, and low-friction.
- Small surface area
  Do a few tasks well rather than becoming a large CLI framework.
- Cross-platform where practical
  Favor shell patterns that behave well on both macOS and Linux.
- Open-source ready
  Keep project layout, docs, and repo hygiene suitable for publication.

## Requirements

- Bash
- `curl`
- `ps`
- `sed`
- `sort`
- `mktemp`
- `stty` and `tput` for the interactive picker experience

The core commands still work without a rich terminal, but the interactive picker and styling depend on a TTY.

## Project Layout

```text
aem-tools/
  bin/
    aem-install
    aem-package-install
    aem-bundle-install
  CHANGELOG.md
  CONTRIBUTING.md
  LICENSE
  README.md
```

## Development

For now this project is intentionally lightweight. A solid baseline for changes is:

```bash
bash -n bin/aem-install bin/aem-package-install bin/aem-bundle-install
shellcheck bin/aem-install bin/aem-package-install bin/aem-bundle-install
```

If `shellcheck` is not installed, syntax checking with `bash -n` is still a minimum expectation.

## Roadmap

- Shell completion support
- Automated smoke tests around argument parsing and dispatch
- Better Linux packaging and install instructions
- Release tags and GitHub metadata
- Example GIFs or screenshots for the interactive picker
