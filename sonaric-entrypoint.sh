#!/bin/bash

# We don't need return codes for "$(command)", only stdout is needed.
# Allow `[[ -n "$(command)" ]]`, `func "$(command)"`, pipes, etc.
# shellcheck disable=SC2312
set -u

NAME="Sonaric entrypoint"

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

TR="$(which tr 2>/dev/null)"
EXPR="$(which expr 2>/dev/null)"
UNAME="$(which uname 2>/dev/null)"
SYSCTL="$(which sysctl 2>/dev/null)"

OS="$(${UNAME} 2>/dev/null)"
# Check if we are on mac
if [[ "${OS}" != "Darwin" ]]; then
  abort "${NAME} is only supported on macOS."
fi

export PATH="${PATH}"
log "${NAME} detects paths:"
for p in $(echo ${PATH} | ${TR} ":" " "); do
  log " - ${p}"
done

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

PODMAN=$(which podman 2>/dev/null)
if [ ! -x "$(command -v ${PODMAN})" ]; then
  abort "podman not found"
fi

SONARICD=$(which sonaricd 2>/dev/null)
if [ ! -x "$(command -v ${SONARICD})" ]; then
  abort "sonaricd not found"
fi

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
      ${PODMAN} machine init --now --rootful ${PODMAN_MACHINE_CPUS} ${PODMAN_MACHINE_MEMORY} || exit 1
      ;;
  esac

  # Recheck machine each 3 sec
  sleep 3
done

# Container runtime path lookup
CR_PATH=$(${PODMAN} info --format '{{.Host.RemoteSocket.Path}}' 2>/dev/null)
MACHINE_CR_PATH=$(${PODMAN} machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null)
if [ -S ${CR_PATH} ]; then
  log "Autodetected container runtime path: ${CR_PATH}"
elif [ -S /run/podman/podman.sock ]; then
  CR_PATH=/run/podman/podman.sock
  log "Selected default container runtime path: ${CR_PATH}"
elif [ -S ~/.local/share/containers/podman/machine/podman.sock ]; then
  CR_PATH=~/.local/share/containers/podman/machine/podman.sock
  log "Selected user container runtime path: ${CR_PATH}"
elif [ -S ${MACHINE_CR_PATH} ]; then
  CR_PATH=${MACHINE_CR_PATH}
  log "Selected machine container runtime path: ${CR_PATH}"
else
  abort "cannot detect path to container runtime"
fi

# Run sonaric daemon
log "Sonaric starting..."
${SONARICD} -m "unix://${CR_PATH}"
