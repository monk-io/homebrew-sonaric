#!/bin/bash

# We don't need return codes for "$(command)", only stdout is needed.
# Allow `[[ -n "$(command)" ]]`, `func "$(command)"`, pipes, etc.
# shellcheck disable=SC2312
set -u

export HOMEBREW_NO_COLOR=1
export HOMEBREW_NO_EMOJI=1
export HOMEBREW_AUTO_UPDATE_SECS=1

NAME="Sonaric entrypoint"
SONARIC_SERVICE_NAME="sonaric"
SONARIC_RUNTIME_SERVICE_NAME="sonaric-runtime"

log() {
  echo "$@"
}

warn() {
  echo "WARNING: $@"
}

abort() {
  echo "ERROR: $@" >&2
  exit 1
}

add_to_path(){
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

check_command(){
  for arg in $@; do
    local n="${arg}"
    local p=$(which ${n} 2>/dev/null)
    if [[ "${p}" == "" ]]; then
      abort "${n} not found"
    fi
    if [ ! -x "$(command -v ${p})" ]; then
      abort "${p} not executable"
    fi
  done
}

# Fail fast with a concise message when not using bash
# Single brackets are needed here for POSIX compatibility
# shellcheck disable=SC2292
if [ -z "${BASH_VERSION:-}" ]; then
  abort "Bash is required to interpret this script."
fi

add_to_path "/sbin" "/usr/sbin" "/usr/local/sbin"
add_to_path "/bin" "/usr/bin" "/usr/local/bin"
add_to_path "/opt/homebrew/bin"

check_command ps tr arch expr uname sysctl brew podman sonaricd

OS="$(uname 2>/dev/null)"
# Check if we are on mac
if [[ "${OS}" != "Darwin" ]]; then
  abort "${NAME} is only supported on macOS."
fi

OS_ARCH=amd64
case $(arch) in
  arm | arm64 | aarch | aarch64)
    OS_ARCH=arm64
    ;;
  *)
    OS_ARCH=amd64
    ;;
esac

log "${NAME} running on ${OS} ${OS_ARCH}"

export PATH="${PATH}"
log "${NAME} detects paths:"
for p in $(echo ${PATH} | tr ":" " "); do
  log " - ${p}"
done

RUNNING=false
while [[ "${RUNNING}" != "true" ]]; do
  PODMAN_MACHINE_STATE=$(podman machine inspect --format '{{.State}}' 2>/dev/null)
  log "${NAME} detects podman machine state: '${PODMAN_MACHINE_STATE}'"

  log "${NAME} runtime service checking..."
  brew services info -q ${SONARIC_RUNTIME_SERVICE_NAME}

  case "${PODMAN_MACHINE_STATE}" in
    running)
      # Sonaric-runtime is already running
      RUNNING=true
      ;;
    *)
      # Initialize sonaric-runtime
      log "Sonaric-runtime initializing..."
      brew services start -q ${SONARIC_RUNTIME_SERVICE_NAME} || abort "Service ${SONARIC_RUNTIME_SERVICE_NAME} initialization failed"
      ;;
  esac

  # Recheck machine each 3 sec
  sleep 3
done

# Container runtime path lookup
CR_PATH=$(podman info --format '{{.Host.RemoteSocket.Path}}' 2>/dev/null)
MACHINE_CR_PATH=$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null)
if [ -S "${CR_PATH}" ]; then
  log "Autodetected container runtime path: ${CR_PATH}"
elif [ -S /run/podman/podman.sock ]; then
  CR_PATH=/run/podman/podman.sock
  log "Selected default container runtime path: ${CR_PATH}"
elif [ -S ~/.local/share/containers/podman/machine/podman.sock ]; then
  CR_PATH=~/.local/share/containers/podman/machine/podman.sock
  log "Selected user container runtime path: ${CR_PATH}"
elif [ -S "${MACHINE_CR_PATH}" ]; then
  CR_PATH=${MACHINE_CR_PATH}
  log "Selected machine container runtime path: ${CR_PATH}"
else
  abort "cannot detect path to container runtime"
fi

###
# trap
###
# 0     0        On exit from shell
# 1     SIGHUP   Clean tidyup
# 2     SIGINT   Interrupt (CTRL-C)
# 3     SIGQUIT  Quit
# 6     SIGABRT  Cancel
# 9     SIGKILL  Die Now (cannot be trap'ped)
# 14    SIGALRM  Alarm Clock
# 15    SIGTERM  Terminate

daemon_shutdown(){
  local pid=${1}
  local itr=0
  local num=0
  while ps -o pid= -p ${pid} >/dev/null; do
    itr=$((itr + 1))
    log "${itr}) Sonaric daemon stopping (PID=${pid})..."

    num=$((num + 1))
    if [[ ${num} -ge 3 ]]; then
      num=0
      log " - send SIGTERM signal to Sonaric daemon (PID=${pid})..."
      kill -15 ${pid}
    else
      sleep 5
    fi
  done
}

# Start sonaric daemon
log "Sonaric daemon starting..."
sonaricd --truncate-log -m "unix://${CR_PATH}" &
SONARICD_PID=$!

log "Sonaric daemon started (PID=${SONARICD_PID})"
trap "daemon_shutdown ${SONARICD_PID}" 1 2 3 6 15

log "Sub-processes checking..."
jobs

log "Waiting for Sonaric daemon (PID=${SONARICD_PID})"
wait "${SONARICD_PID}"

log "Sub-processes checking..."
jobs

log "Waiting for Sonaric daemon stopping..."
sleep 15

log "Service ${SONARIC_RUNTIME_SERVICE_NAME} checking..."
brew services info -q ${SONARIC_RUNTIME_SERVICE_NAME}
