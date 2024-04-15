#!/bin/bash

PODMAN=$(which podman 2>/dev/null)
if ! [ -x "$(command -v ${PODMAN})" ]; then
  if [ -x "$(command -v /usr/local/bin/podman)" ]; then
    PODMAN="/usr/local/bin/podman"
  elif [ -x "$(command -v /opt/homebrew/bin/podman)" ]; then
    PODMAN="/opt/homebrew/bin/podman"
  else
    echo "ERROR: podman not found"
    exit 1
  fi
fi

while true; do
  case $(${PODMAN} machine inspect --format '{{.State}}') in
    stopped)
      # Start default podman machine
      ${PODMAN} machine start
      ;;
    running)
      # Machine is already running
      sleep 60
      ;;
    *)
      # Initialize default podman machine
      ${PODMAN} machine init --now --rootful
      ;;
  esac

  # Recheck machine each 5 min
  sleep 300
done
