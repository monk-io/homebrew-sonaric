#!/bin/bash

# We don't need return codes for "$(command)", only stdout is needed.
# Allow `[[ -n "$(command)" ]]`, `func "$(command)"`, pipes, etc.
# shellcheck disable=SC2312
set -u

NAME="Sonaric installer"
SONARIC_OPTS="--nofancy --nocolor"
BREW_SONARIC_PKG="monk-io/sonaric/sonaric"
BREW_INSTALLER_LINK="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

log() {
  echo "$@"
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
CURL=$(which curl 2>/dev/null)
check_command "curl" "${CURL}"
ARCH=$(which arch 2>/dev/null)
check_command "arch" "${ARCH}"
EXPR=$(which expr 2>/dev/null)
check_command "expr" "${EXPR}"
UNAME=$(which uname 2>/dev/null)
check_command "uname" "${UNAME}"
SYSCTL=$(which sysctl 2>/dev/null)
check_command "sysctl" "${SYSCTL}"
DIRNAME=$(which dirname 2>/dev/null)
check_command "dirname" "${DIRNAME}"
BASENAME=$(which basename 2>/dev/null)
check_command "basename" "${BASENAME}"

OS="$(${UNAME} 2>/dev/null)"
# Check if we are on mac
if [[ "${OS}" != "Darwin" ]]; then
  abort "${NAME} is only supported on macOS."
fi

OS_ARCH=amd64
case $(${ARCH}) in
  arm | arm64 | aarch | aarch64)
    OS_ARCH=arm64
    ;;
  *)
    OS_ARCH=amd64
    ;;
esac

log "${NAME} started on: ${OS} ${OS_ARCH}"

export PATH="${PATH}"
log "${NAME} detects paths:"
for p in $(echo ${PATH} | ${TR} ":" " "); do
  log " - ${p}"
done

BREW=$(which brew 2>/dev/null)
if [ ! -x "$(command -v ${BREW})" ]; then
  log "Homebrew is not installed in your system, let's change it"
  bash -c "$(${CURL} -fsSL ${BREW_INSTALLER_LINK})"

  add_to_path "/usr/local/bin" "/opt/homebrew/bin"
  BREW=$(which brew 2>/dev/null)
  check_command "brew" "${BREW}"
fi

log "Fetching the newest version of Homebrew and installed packages"
${BREW} update

log "Install the newest version of Sonaric"
${BREW} install ${BREW_SONARIC_PKG}

PODMAN=$(which podman 2>/dev/null)
check_command "podman" "${PODMAN}"
SONARIC=$(which sonaric 2>/dev/null)
check_command "sonaric" "${SONARIC}"

log "Sonaric service restarting..."
${BREW} services restart sonaric

ITR=0
RUNNING=false
while [[ "$RUNNING" != "true" ]]; do
  ITR=$((ITR + 1))
  if ${SONARIC} ${SONARIC_OPTS} version; then
    RUNNING=true

    # If sonaric was started we should add some pause to become it ready
    log "Wait for Sonaric daemon to become ready..."
    sleep 15
  else
    log "${ITR}) Wait for Sonaric daemon to become started..."
    sleep 5
  fi
done

log "Check Podman machines..."
${PODMAN} machine ls

log "Check Sonaric service..."
${BREW} services info sonaric
