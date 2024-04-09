#!/bin/bash

# We don't need return codes for "$(command)", only stdout is needed.
# Allow `[[ -n "$(command)" ]]`, `func "$(command)"`, pipes, etc.
# shellcheck disable=SC2312

set -u

abort() {
  printf "%s\n" "$@" >&2
  exit 1
}

log() {
  printf "%s...\n" "$@"
}

warn() {
  printf "[Warning] %s\n" "$(log "$1")" >&2
}

# Fail fast with a concise message when not using bash
# Single brackets are needed here for POSIX compatibility
# shellcheck disable=SC2292
if [ -z "${BASH_VERSION:-}" ]; then
  abort "Bash is required to interpret this script."
fi

# Check if script is run with force-interactive mode in CI
if [[ -n "${CI-}" && -n "${INTERACTIVE-}" ]]; then
  abort "Cannot run force-interactive mode in CI."
fi

# Check if both `INTERACTIVE` and `NONINTERACTIVE` are set
# Always use single-quoted strings with `exp` expressions
# shellcheck disable=SC2016
if [[ -n "${INTERACTIVE-}" && -n "${NONINTERACTIVE-}" ]]; then
  abort 'Both `$INTERACTIVE` and `$NONINTERACTIVE` are set. Please unset at least one variable and try again.'
fi

# Check if script is run in POSIX mode
if [[ -n "${POSIXLY_CORRECT+1}" ]]; then
  abort 'Bash must not run in POSIX mode. Please unset POSIXLY_CORRECT and try again.'
fi

NAME="Sonaric installer"

# First check OS.
OS="$(uname)"
if [[ "${OS}" == "Linux" ]]; then
  ON_LINUX=1
elif [[ "${OS}" == "Darwin" ]]; then
  ON_MACOS=1
else
  abort "${NAME} is only supported on macOS and Linux."
fi

# Install Homebrew if it needed
if ! [ -x "$(command -v brew)" ]; then
  log "Homebrew is not installed in your system, let's change it"
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

log "Fetching the newest version of Homebrew and installed packages"
brew update

log "Install the newest version of Sonaric"
brew install monk-io/sonaric/sonaric

