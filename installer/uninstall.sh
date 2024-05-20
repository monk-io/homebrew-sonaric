#!/bin/bash

# We don't need return codes for "$(command)", only stdout is needed.
# Allow `[[ -n "$(command)" ]]`, `func "$(command)"`, pipes, etc.
# shellcheck disable=SC2312
set -u

NAME="Sonaric uninstaller"
SONARIC_OPTS="--nofancy --nocolor"

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

# check_command {{name}} {{path}}
check_command(){
  local n="${1}"
  local p="${2}"
  if [[ "${p}" == "" ]]; then
    abort "${n} not found"
  fi
  if [ ! -x "$(command -v ${p})" ]; then
    abort "${p} not executable"
  fi
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

TR=$(which tr 2>/dev/null)
check_command "tr" "${TR}"
RM=$(which rm 2>/dev/null)
check_command "rm" "${RM}"
UNAME=$(which uname 2>/dev/null)
check_command "uname" "${UNAME}"
BASENAME=$(which basename 2>/dev/null)
check_command "basename" "${BASENAME}"

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

BREW=$(which brew 2>/dev/null)
if [ ! -x "$(command -v ${BREW})" ]; then
  BREW=""
  log "Homebrew is not installed in your system"
fi

PODMAN=$(which podman 2>/dev/null)
if [ ! -x "$(command -v ${PODMAN})" ]; then
  PODMAN=""
  log "Podman is not installed in your system"
fi

SONARIC=$(which sonaric 2>/dev/null)
if [ -x "$(command -v ${SONARIC})" ]; then
  if [[ "${BREW}" != "" ]]; then
    if ! "${SONARIC}" ${SONARIC_OPTS} "version"; then
      log "Sonaric service starting..."
      ${BREW} services start sonaric
      log "Wait for Sonaric service to become ready..."
      sleep 5
    fi
  fi

  ITR=0
  TOTAL_ITRS=50
  RUNNING=false
  while [[ "$RUNNING" != "true" && ${ITR} -le ${TOTAL_ITRS} ]]; do
    ITR=$((ITR + 1))

    if "${SONARIC}" ${SONARIC_OPTS} "version"; then
      RUNNING=true

      # If sonaric was started we should add some pause to become it ready
      log "Wait for Sonaric daemon to become ready..."
      sleep 15
    else
      log "${ITR}) Wait for Sonaric daemon to become started..."
      sleep 5
    fi
  done

  log "Sonaric resources stopping..."
  if ! "${SONARIC}" ${SONARIC_OPTS} "stop" "-a"; then
    warn "Sonaric resources stop failed"
  fi

  log "Sonaric resources deleting..."
  if ! "${SONARIC}" ${SONARIC_OPTS} "delete" "-a" "--force"; then
    warn "Sonaric resources delete failed"

    if [[ "${PODMAN}" != "" ]]; then
      if ! "${PODMAN}" "container" "prune" "-f"; then
        warn "Podman containers force prune failed"
      fi
      if ! "${SONARIC}" ${SONARIC_OPTS} "delete" "-a" "--force"; then
        warn "Sonaric resources cleanup failed"
      fi
    fi
  fi
fi

if [ "${BREW}" != "" ]; then
  log "Sonaric service stopping..."
  ${BREW} services stop sonaric
fi

if [ "${PODMAN}" != "" ]; then
  log "Podman machine stopping..."
  ${PODMAN} machine stop

  log "Podman machine removing..."
  ${PODMAN} machine rm -f
fi

if [ "${BREW}" != "" ]; then
  log "Sonaric uninstalling..."
  ${BREW} uninstall -f --ignore-dependencies sonaric
fi

if [ ! -x "$(command -v $(which podman 2>/dev/null))" ]; then
  log "Podman has already uninstalled from your system"
  ${RM} -rf ~/.local/share/containers
  ${RM} -rf ~/.config/containers
fi
