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
- `git-worktree-jump`
  Interactive picker that prints a selected worktree path so shell wrappers can `cd` there quickly.
- `git-worktree-remove`
  Interactive picker for removable worktrees with a follow-up `No / Yes / Force` confirmation.
- `mvn-bg`
  Starts a Maven build in the background and records PID/log/status state for later viewing.
- `mvn-watch`
  Watches the latest log line from a `mvn-bg` build and can be stopped and resumed safely.

## Features

- Auto-detects running local AEM instances from `quickstart.jar` process arguments and Docker-published host ports.
- Offers an interactive instance picker with arrow keys and `j`/`k`.
- Labels detected instances by source so mixed local and Docker setups are easier to distinguish.
- Adds matching interactive Git worktree pickers for navigation and safe removal.
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
~/bin/aem-tools/bin/mvn-bg
~/bin/aem-tools/bin/mvn-watch
~/bin/aem-tools/bin/git-worktree-jump
~/bin/aem-tools/bin/git-worktree-remove
```

You can either call the canonical scripts directly or create wrappers/aliases such as:

```bash
alias aempkg="$HOME/bin/aem-package-install"
alias aembundle="$HOME/bin/aem-bundle-install"
alias aeminstall="$HOME/bin/aem-install"
```

`aem-tools/bin` is the canonical source of truth for the project on both macOS and Linux. Any older standalone copies outside this directory should be treated as deprecated compatibility copies.

For the worktree picker, use a shell function rather than a plain alias so the selected path can update your current shell:

```bash
wt() {
  local dest
  dest="$(git-worktree-jump "$@")" || return
  [[ -n "$dest" ]] && cd "$dest"
}

alias wtrm="$HOME/bin/git-worktree-remove"
```

## Quick Start

```bash
aem-install my-package.zip
aem-install my-bundle.jar

aem-package-install --shallow my-package.zip
aem-package-install --disable-workflows my-package.zip
aem-bundle-install --no-refresh --start-level 15 my-bundle.jar

aem-package-install --dry-run my-package.zip
aem-bundle-install --dry-run my-bundle.jar

wt
git-worktree-jump --sort recent
git-worktree-remove

mvn-bg clean install
mvn-watch
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
- Use `--disable-workflows` to disable `WorkflowLauncherImpl` and `WorkflowLauncherListener` via the OSGi console before upload and re-enable them after install completes. Useful when installing content packages with already-processed assets to avoid unnecessary background processing.
- If `-p` is omitted, detects host-local AEM instances from local JVM processes and Docker-published host ports.

### `aem-bundle-install`

- Uploads bundles to `/system/console/bundles`.
- Supports refresh and bundle start toggles.
- Supports configurable start level for newly installed bundles.
- If `-p` is omitted, detects host-local AEM instances from local JVM processes and Docker-published host ports.

### `git-worktree-jump`

- Lists worktrees for the current repository in an interactive picker.
- Shows each worktree path with its branch in a separate visual style.
- Prints the selected path to stdout so a shell function can `cd` there.
- Supports `--sort name` and `--sort recent`.
- Treats `q` as a clean no-op exit.

### `git-worktree-remove`

- Lists removable worktrees for the current repository.
- Omits the main worktree and the current worktree from the removal list.
- Confirms the selected removal with `No`, `Yes`, and `Force`.
- `Force` maps to `git worktree remove --force`.
- Treats `q` and `No` as clean no-op exits.

### `mvn-bg`

- Starts `mvn ...` in the background.
- Stores run state under `.mvn-bg/` by default.
- Writes the active wrapper PID to `.mvn-bg/build.pid`.
- Streams Maven output to `.mvn-bg/build.log`.
- Writes the Maven exit code to `.mvn-bg/build.status` when the build finishes.

### `mvn-watch`

- Reads state written by `mvn-bg`.
- Shows only the latest log line in-place while the build is still running.
- Exits automatically when the tracked build finishes.
- Can be interrupted with `Ctrl-C` and run again later to resume watching.
- Prints the final log tail and success or failure status once the build is done.

## Instance Detection

- Local AEM quickstarts are detected from running Java processes and their listening ports.
- Dockerized AEM instances are detected from running containers with published ports on the host.
- Docker detection uses the host-mapped port, not the container's internal AEM port.
- Every detected port is confirmed with lightweight AEM HTTP probes before it is shown in the picker or used automatically.
- Detection probes stay silent during discovery, even if a candidate port resets or refuses a connection.
- Detected instances are sorted numerically by port before they are listed.
- Picker and multi-instance output label each detected port as `local` or `docker`.

For example, if Docker publishes `14502->4502`, the installer will display and target `14502`.

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
- `docker` if you want Dockerized AEM instances to be auto-detected
- `ps`
- `sed`
- `sort`
- `mktemp`
- `stty` and `tput` for the interactive picker experience

The core commands still work without a rich terminal, but the interactive picker and styling depend on a TTY.

## Shell Completions

Source the completion script for bash or zsh:

```bash
# bash — add to ~/.bashrc or ~/.bash_profile
source /path/to/aem-tools/completions/aem-tools-completion.bash

# zsh — add to ~/.zshrc
autoload -U +X bashcompinit && bashcompinit
source /path/to/aem-tools/completions/aem-tools-completion.bash
```

Completions cover flags and file filtering (`.zip` for package installs, `.jar` for bundle installs) for all three commands.

## Project Layout

```text
aem-tools/
  bin/
    _git-worktree-common.sh
    aem-install
    aem-package-install
    aem-bundle-install
    _mvn-bg-runner
    mvn-bg
    mvn-watch
    git-worktree-jump
    git-worktree-remove
  completions/
    aem-tools-completion.bash
  CHANGELOG.md
  CONTRIBUTING.md
  LICENSE
  README.md
```

## Development

For now this project is intentionally lightweight. A solid baseline for changes is:

```bash
bash -n \
  bin/aem-install \
  bin/aem-package-install \
  bin/aem-bundle-install \
  bin/_mvn-bg-runner \
  bin/mvn-bg \
  bin/mvn-watch \
  bin/git-worktree-jump \
  bin/git-worktree-remove \
  bin/_git-worktree-common.sh
shellcheck \
  bin/aem-install \
  bin/aem-package-install \
  bin/aem-bundle-install \
  bin/_mvn-bg-runner \
  bin/mvn-bg \
  bin/mvn-watch \
  bin/git-worktree-jump \
  bin/git-worktree-remove \
  bin/_git-worktree-common.sh
```

If `shellcheck` is not installed, syntax checking with `bash -n` is still a minimum expectation.

## Roadmap

- Automated smoke tests around argument parsing and dispatch
- Better Linux packaging and install instructions
- Release tags and GitHub metadata
- Example GIFs or screenshots for the interactive picker
