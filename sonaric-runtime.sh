#!/bin/bash

while true; do
  case $(podman machine inspect --format '{{.State}}') in
    stopped)
      podman machine start
      ;;
    running)
      echo "Machine is already running"
      ;;
    *)
      podman machine init --now --rootful
      ;;
  esac

  # Recheck machine each 5 min
  sleep 300
done
