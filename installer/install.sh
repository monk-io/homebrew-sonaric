#!/bin/bash

# We don't need return codes for "$(command)", only stdout is needed.
# Allow `[[ -n "$(command)" ]]`, `func "$(command)"`, pipes, etc.
# shellcheck disable=SC2312

set -u

OS="$(uname)"
NAME="Sonaric installer"
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

setupHomebrew() {
  HOMEBREW=${1}
  HOMEBREW_DIR=$(dirname ${HOMEBREW})

  log "Homebrew detected: ${HOMEBREW}"
  log " "
  log "Please add Homebrew directory '${HOMEBREW_DIR}' to PATH into '${USER_SHELL_RC}'"
  log "------------------------------------------------------------------------------------"
  log " echo PATH=${HOMEBREW_DIR}:"'$PATH'" >> ${USER_SHELL_RC} && source ${USER_SHELL_RC} "
  log "------------------------------------------------------------------------------------"
  log " "
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

if [[ "${OS}" == "Linux" ]]; then
  ON_LINUX=1
elif [[ "${OS}" == "Darwin" ]]; then
  ON_MACOS=1
else
  abort "${NAME} is only supported on macOS and Linux."
fi

HOMEBREW=$(which brew 2>/dev/null)
if [ -x "$(command -v ${HOMEBREW})" ]; then
  log "Homebrew automaticaly detected: ${HOMEBREW}"
elif [ -x "$(command -v /usr/local/bin/brew)" ]; then
  setupHomebrew "/usr/local/bin/brew"
elif [ -x "$(command -v /opt/homebrew/bin/brew)" ]; then
  setupHomebrew "/opt/homebrew/bin/brew"
else
  log "Homebrew is not installed in your system, let's change it"
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  HOMEBREW=$(which brew 2>/dev/null)
  if [ -x "$(command -v ${HOMEBREW})" ]; then
    log "Homebrew automaticaly detected: ${HOMEBREW}"
  elif [ -x "$(command -v /usr/local/bin/brew)" ]; then
    setupHomebrew "/usr/local/bin/brew"
  elif [ -x "$(command -v /opt/homebrew/bin/brew)" ]; then
    setupHomebrew "/opt/homebrew/bin/brew"
  else
    abort "Can not detect Homebrew, please follow the instruction on the screen and run this script again"
  fi
fi

log "Fetching the newest version of Homebrew and installed packages"
${HOMEBREW} update

log "Install the newest version of Sonaric"
${HOMEBREW} install monk-io/sonaric/sonaric

PODMAN=$(which podman 2>/dev/null)
if ! [ -x "$(command -v ${PODMAN})" ]; then
  if [ -x "$(command -v /usr/local/bin/podman)" ]; then
    PODMAN="/usr/local/bin/podman"
  elif [ -x "$(command -v /opt/homebrew/bin/podman)" ]; then
    PODMAN="/opt/homebrew/bin/podman"
  else
    abort "ERROR: podman not found"
  fi
fi

log "Sonaric service stopping..."
${HOMEBREW} services stop sonaric

case $(${PODMAN} machine inspect --format '{{.State}}' 2>/dev/null) in
  stopped)
    # Start default podman machine
    log "Podman machine starting..."
    ${PODMAN} machine start
    ;;
  running)
    log "Podman machine has started"
    ;;
  *)
    # Initialize default podman machine
    log "Podman machine initializing..."
    ${PODMAN} machine init --now --rootful --disk-size 20 || abort "ERROR: podman machine can not be initialized"
    ;;
esac

log "Check podman machines..."
${PODMAN} machine ls

log "Sonaric service starting..."
${HOMEBREW} services start sonaric

log "Wait for Sonaric service..."
sleep 3
${HOMEBREW} services info sonaric

