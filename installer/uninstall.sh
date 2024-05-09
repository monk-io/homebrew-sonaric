#!/bin/bash

# We don't need return codes for "$(command)", only stdout is needed.
# Allow `[[ -n "$(command)" ]]`, `func "$(command)"`, pipes, etc.
# shellcheck disable=SC2312
set -u

log() {
  echo "$@"
}

abort() {
  echo "ERROR: $@" >&2
  exit 1
}

addToPath(){
  for arg in $@; do
    if [ -d "${arg}" ]; then
      if [[ "${PATH}" == "" ]]; then
        PATH="${arg}"
      else
        case ":${PATH}:" in
          *:"${arg}":*)
            ;;
          *)
            PATH="${arg}:${PATH}"
            ;;
        esac
      fi
    fi
  done
}

# Fail fast with a concise message when not using bash
# Single brackets are needed here for POSIX compatibility
# shellcheck disable=SC2292
if [ -z "${BASH_VERSION:-}" ]; then
  abort "Bash is required to interpret this script."
fi

addToPath "/sbin" "/usr/sbin" "/usr/local/sbin"
addToPath "/bin" "/usr/bin" "/usr/local/bin"
addToPath "/opt/homebrew/bin"

OS="$(uname)"
NAME="Sonaric uninstaller"

if [[ "${OS}" != "Darwin" ]]; then
  abort "${NAME} is only supported on macOS."
fi

USER_SHELL=$(basename $SHELL)
USER_SHELL_RC="~/.${USER_SHELL}rc"

HOMEBREW=$(which brew 2>/dev/null)
if [ ! -x "$(command -v ${HOMEBREW})" ]; then
  HOMEBREW=""
  log "Homebrew is not installed in your system"
fi

PODMAN=$(which podman 2>/dev/null)
if [ ! -x "$(command -v ${PODMAN})" ]; then
  PODMAN=""
  log "Podman is not installed in your system"
fi

if [ "${HOMEBREW}" != "" ]; then
  log "Sonaric service stopping..."
  ${HOMEBREW} services stop sonaric
  sleep 3

  log "Sonaric uninstalling..."
  ${HOMEBREW} uninstall -f --ignore-dependencies sonaric
fi

if [ "${PODMAN}" != "" ]; then
  log "Podman machine stopping..."
  ${PODMAN} machine stop
  sleep 3

  log "Podman machine removing..."
  ${PODMAN} machine rm -f
fi

if [ "${HOMEBREW}" != "" ]; then
  log "Podman uninstalling..."
  ${HOMEBREW} uninstall -f --ignore-dependencies podman
fi

rm -rf ~/.local/share/containers
rm -rf ~/.config/containers
