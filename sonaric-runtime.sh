#!/bin/bash

# We don't need return codes for "$(command)", only stdout is needed.
# Allow `[[ -n "$(command)" ]]`, `func "$(command)"`, pipes, etc.
# shellcheck disable=SC2312
set -u

APP="xyz.sonaric.desktop"
NAME="Sonaric-runtime"

if [[ "${HOME}" == "" ]]; then
  HOME="~"
fi

LOG_DIR="${HOME}/Library/Logs/${APP}"
LOG_FILE="${LOG_DIR}/runtime.log"

log() {
  echo "$@"
  if [ -f ${LOG_FILE} ]; then
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $@" >> ${LOG_FILE}
  fi
}

warn() {
  echo "WARNING: $@"
  if [ -f ${LOG_FILE} ]; then
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] WARNING: $@" >> ${LOG_FILE}
  fi
}

abort() {
  echo "ERROR: $@" >&2
  if [ -f ${LOG_FILE} ]; then
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] ERROR: $@" >> ${LOG_FILE}
  fi
  exit 1
}

execute() {
  log "${NAME} execute: $@"
  if ! $@ 2>&1 >> ${LOG_FILE}; then
    warn "Failed during: ${@}"
    return 1
  fi
  return 0
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

add_to_path "/sbin" "/usr/sbin" "/usr/local/sbin"
add_to_path "/bin" "/usr/bin" "/usr/local/bin"
add_to_path "/opt/homebrew/bin"

check_command ps tr tee arch expr date uname mkdir touch sysctl podman

mkdir -p ${LOG_DIR}
touch ${LOG_FILE}
log "${NAME} starting ..."

# Fail fast with a concise message when not using bash
# Single brackets are needed here for POSIX compatibility
# shellcheck disable=SC2292
if [ -z "${BASH_VERSION:-}" ]; then
  abort "Bash is required to interpret this script."
fi

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

NCPU=$(sysctl -n hw.ncpu 2>/dev/null)
MEMSIZE_MB=$(expr $(sysctl -n hw.memsize 2>/dev/null) / 1024 / 1024 2>/dev/null)
log "${NAME} detects resources: NCPU=${NCPU} and MEMSIZE=${MEMSIZE_MB}(MB)"

VM_OS_BUILD=""
if [[ "${OS_ARCH}" == "arm64" ]]; then
  # ISSUE: https://github.com/containers/podman/issues/22708
  VM_OS_BUILD="39.20240407.3.0"
fi

PODMAN_MACHINE_CPUS=""
PODMAN_MACHINE_MEMORY=""
PODMAN_MACHINE_IMAGE=""

if [ ${NCPU} -gt 0 ]; then
  PODMAN_MACHINE_CPUS="--cpus ${NCPU}"
fi

if [ ${MEMSIZE_MB} -gt 0 ]; then
  PODMAN_MACHINE_MEMORY="--memory ${MEMSIZE_MB}"
fi

if [[ "${VM_OS_BUILD}" != "" ]]; then
  log "${NAME} uses build of VM OS: fedora coreos ${VM_OS_BUILD} applehv aarch64"
  PODMAN_MACHINE_IMAGE="--image https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/${VM_OS_BUILD}/aarch64/fedora-coreos-${VM_OS_BUILD}-applehv.aarch64.raw.gz"
fi

PODMAN_MACHINE_INITIAL_STATE=$(podman machine inspect --format '{{.State}}' 2>/dev/null)

RUNNING=false
while [[ "$RUNNING" != "true" ]]; do
  PODMAN_MACHINE_STATE=$(podman machine inspect --format '{{.State}}' 2>/dev/null)
  log "${NAME} detects podman machine state: '${PODMAN_MACHINE_STATE}'"

  case ${PODMAN_MACHINE_STATE} in
    stopped)
      if [[ "${PODMAN_MACHINE_CPUS}" != "" ]]; then
        log "Podman machine set ${PODMAN_MACHINE_CPUS}"
        execute podman machine set ${PODMAN_MACHINE_CPUS}
      fi
      if [[ "${PODMAN_MACHINE_MEMORY}" != "" ]]; then
        log "Podman machine set ${PODMAN_MACHINE_MEMORY}"
        execute podman machine set ${PODMAN_MACHINE_MEMORY}
      fi
      # Start default podman machine
      log "Podman machine start"
      execute podman machine start || execute podman machine stop
      ;;
    starting)
      # Machine is starting, let's wait a little bit
      log "Podman machine starting"
      sleep 2
      ;;
    running)
      # Machine is already running
      RUNNING=true
      ;;
    *)
      # Initialize default podman machine
      log "Podman machine init --now --rootful ${PODMAN_MACHINE_CPUS} ${PODMAN_MACHINE_MEMORY} ${PODMAN_MACHINE_IMAGE}"
      execute podman machine init --now --rootful ${PODMAN_MACHINE_CPUS} ${PODMAN_MACHINE_MEMORY} ${PODMAN_MACHINE_IMAGE} || abort "Podman machine initializing failed"
      ;;
  esac

  # Recheck machine each 3 sec
  sleep 3
done

# Sync time service for the time synchronisation between VM and Host each 1 min
echo "[Unit]
Description=System time sync

[Service]
User=root
Group=root
ExecStart=sh -c 'while true; do hwclock -s; sleep 60; done'
Restart=on-failure
KillMode=process

[Install]
WantedBy=multi-user.target
" | podman machine ssh tee /etc/systemd/system/systime-sync.service || warn "Create systime-sync.service"

execute podman machine ssh chmod 664 /etc/systemd/system/systime-sync.service || warn "Update permissions for systime-sync.service"

# If the service was disabled for some reason we should enable it on each restart
execute podman machine ssh systemctl enable --now systime-sync || warn "Enable systime-sync.service"
sleep 3
execute podman machine ssh systemctl status systime-sync.service

# If service was changed we should restart it to apply changes
execute podman machine ssh systemctl restart systime-sync.service || warn "Restart systime-sync.service"
sleep 3
execute podman machine ssh systemctl status systime-sync.service

log "Host: $(date)"
log "=VM=: $(podman machine ssh date)"

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

trap 'shutdown=1' 1 2 3 6 15

shutdown=0
while [ "${shutdown}" -ne 1 ]; do
    sleep 1
done

PODMAN_MACHINE_STATE=$(podman machine inspect --format '{{.State}}' 2>/dev/null)
log "${NAME} detects podman machine state: '${PODMAN_MACHINE_STATE}'"

sleep 1
log "${NAME} has successfully stopped"
