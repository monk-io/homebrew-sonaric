#!/bin/bash

while true; do
  case $(podman machine inspect --format '{{.State}}') in
    stopped)
      # Start default podman machine
      podman machine start
      ;;
    running)
      # Machine is already running
      sleep 60
      ;;
    *)
      # Initialize default podman machine
      podman machine init --now --rootful
      ;;
  esac

  # Recheck machine each 5 min
  sleep 300
done
