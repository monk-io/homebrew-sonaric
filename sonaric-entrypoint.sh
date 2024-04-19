#!/bin/bash

PODMAN=$(which podman 2>/dev/null)
if ! [ -x "$(command -v ${PODMAN})" ]; then
  if [ -x "$(command -v /usr/local/bin/podman)" ]; then
    PODMAN="/usr/local/bin/podman"
  elif [ -x "$(command -v /opt/homebrew/bin/podman)" ]; then
    PODMAN="/opt/homebrew/bin/podman"
  else
    >&2 echo "ERROR: podman not found"
    exit 1
  fi
fi

SONARICD=$(which sonaricd 2>/dev/null)
if ! [ -x "$(command -v ${sonaricd})" ]; then
  if [ -x "$(command -v /usr/local/bin/sonaricd)" ]; then
    SONARICD="/usr/local/bin/sonaricd"
  elif [ -x "$(command -v /opt/homebrew/bin/sonaricd)" ]; then
    SONARICD="/opt/homebrew/bin/sonaricd"
  else
    >&2 echo "ERROR: sonaricd not found"
    exit 1
  fi
fi

RUNNING=false
while [[ "$RUNNING" != "true" ]]; do
  case $(${PODMAN} machine inspect --format '{{.State}}' 2>/dev/null) in
    stopped)
      # Start default podman machine
      echo "Podman machine starting..."
      ${PODMAN} machine start
      ;;
    running)
      # Machine is already running
      RUNNING=true
      ;;
    *)
      # Initialize default podman machine
      echo "Podman machine initializing..."
      ${PODMAN} machine init --now --rootful --disk-size 20 || exit 1
      ;;
  esac

  # Recheck machine each 3 sec
  sleep 3
done

# Run sonaric daemon
echo "Sonaric starting..."
${SONARICD}
