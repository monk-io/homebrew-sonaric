#!/bin/bash

# We don't need return codes for "$(command)", only stdout is needed.
# Allow `[[ -n "$(command)" ]]`, `func "$(command)"`, pipes, etc.
# shellcheck disable=SC2312

set -u

OS="$(uname)"
NAME="Sonaric uninstaller"
USER_SHELL=$(basename $SHELL)
USER_SHELL_RC="~/.${USER_SHELL}rc"

log() {
  printf "%s\n" "$@"
}

warn() {
  printf "[Warning] %s\n" "$(log "$1")" >&2
}

abort() {
  printf "%s\n" "$@" >&2
  exit 1
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

if [[ "${OS}" != "Darwin" ]]; then
  abort "${NAME} is only supported on macOS."
fi

HOMEBREW=$(which brew 2>/dev/null)
if [ -x "$(command -v ${HOMEBREW})" ]; then
  log "Homebrew automaticaly detected: ${HOMEBREW}"
elif [ -x "$(command -v /usr/local/bin/brew)" ]; then
  HOMEBREW="/usr/local/bin/brew"
  log "Homebrew detected: ${HOMEBREW}"
elif [ -x "$(command -v /opt/homebrew/bin/brew)" ]; then
  HOMEBREW="/opt/homebrew/bin/brew"
  log "Homebrew detected: ${HOMEBREW}"
else
  HOMEBREW=""
  log "Homebrew is not installed in your system"
fi

PODMAN=$(which podman 2>/dev/null)
if [ -x "$(command -v ${PODMAN})" ]; then
  log "Podman automaticaly detected: ${PODMAN}"
elif [ -x "$(command -v /usr/local/bin/podman)" ]; then
  PODMAN="/usr/local/bin/podman"
  log "Podman detected: ${PODMAN}"
elif [ -x "$(command -v /opt/homebrew/bin/podman)" ]; then
  PODMAN="/opt/homebrew/bin/podman"
  log "Podman detected: ${PODMAN}"
else
  PODMAN=""
  log "Podman is not installed in your system"
fi

if [ "${HOMEBREW}" != "" ]; then
  log "Sonaric service stopping..."
  ${HOMEBREW} services stop sonaric
  sleep 3

  log "Sonaric service uninstalling..."
  ${HOMEBREW} uninstall -f --ignore-dependencies sonaric
fi

if [ "${PODMAN}" != "" ]; then
  log "Podman machine stopping..."
  ${PODMAN} machine stop
  sleep 3

  log "Podman machine removing..."
  ${PODMAN} machine rm -f
fi
