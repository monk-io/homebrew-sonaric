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

EXPR="$(which expr 2>/dev/null)"
UNAME="$(which uname 2>/dev/null)"
SYSCTL="$(which sysctl 2>/dev/null)"
DIRNAME="$(which dirname 2>/dev/null)"
BASENAME="$(which basename 2>/dev/null)"

OS="$(${UNAME} 2>/dev/null)"
NAME="Sonaric installer"

if [[ "${OS}" != "Darwin" ]]; then
  abort "${NAME} is only supported on macOS."
fi

USER_SHELL=$(${BASENAME} $SHELL 2>/dev/null)
USER_SHELL_RC="~/.${USER_SHELL}rc"

NCPU=$(${SYSCTL} -n hw.ncpu 2>/dev/null)
MEMSIZE_MB=$(${EXPR} $(${SYSCTL} -n hw.memsize 2>/dev/null) / 1024 / 1024 2>/dev/null)

PODMAN_MACHINE_CPUS=""
PODMAN_MACHINE_MEMORY=""

if [ ${NCPU} -gt 0 ]; then
  PODMAN_MACHINE_CPUS="--cpus ${NCPU}"
fi

if [ ${MEMSIZE_MB} -gt 0 ]; then
  PODMAN_MACHINE_MEMORY="--memory ${MEMSIZE_MB}"
fi

HOMEBREW=$(which brew 2>/dev/null)
if [ ! -x "$(command -v ${HOMEBREW})" ]; then
  log "Homebrew is not installed in your system, let's change it"
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  addToPath "/usr/local/bin" "/opt/homebrew/bin"
  HOMEBREW=$(which brew 2>/dev/null)
  if [ ! -x "$(command -v ${HOMEBREW})" ]; then
    abort "Can not detect Homebrew, please follow the instruction on the screen and run this script again"
  fi
fi

log "Fetching the newest version of Homebrew and installed packages"
${HOMEBREW} update

log "Install the newest version of Sonaric"
${HOMEBREW} install monk-io/sonaric/sonaric

PODMAN=$(which podman 2>/dev/null)
if [ ! -x "$(command -v ${PODMAN})" ]; then
  abort "podman not found"
fi

log "Sonaric service stopping..."
${HOMEBREW} services stop sonaric

RUNNING=false
while [[ "$RUNNING" != "true" ]]; do
  case $(${PODMAN} machine inspect --format '{{.State}}' 2>/dev/null) in
    stopped)
      if [[ "${PODMAN_MACHINE_CPUS}" != "" ]]; then
        log "Podman machine set ${PODMAN_MACHINE_CPUS}"
        ${PODMAN} machine set ${PODMAN_MACHINE_CPUS}
      fi
      if [[ "${PODMAN_MACHINE_MEMORY}" != "" ]]; then
        log "Podman machine set ${PODMAN_MACHINE_MEMORY}"
        ${PODMAN} machine set ${PODMAN_MACHINE_MEMORY}
      fi
      # Start default podman machine
      log "Podman machine starting..."
      ${PODMAN} machine start || ${PODMAN} machine stop
      ;;
    running)
      # Machine is already running
      RUNNING=true
      ;;
    *)
      # Initialize default podman machine
      log "Podman machine initializing..."
      ${PODMAN} machine init --now --rootful ${PODMAN_MACHINE_CPUS} ${PODMAN_MACHINE_MEMORY} || abort "Podman machine initializing failed"
      ;;
  esac

  # Recheck machine each 3 sec
  sleep 3
done

log "Check podman machines..."
${PODMAN} machine ls

log "Sonaric service starting..."
${HOMEBREW} services start sonaric

log "Wait for Sonaric service..."
sleep 3
${HOMEBREW} services info sonaric
