#!/bin/bash

# Guard: prevent loading this module multiple times
if [[ -n "${CRONJOB_DOCKER_MODULE_LOADED:-}" ]]; then
  return
fi

ensure_docker() {
  echo "🔍 Checking Docker installation..."
  if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker is not installed. Please install Docker first." >&2
    exit 1
  fi
  if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker daemon is not running. Please start Docker." >&2
    exit 1
  fi
}

CRONJOB_DOCKER_MODULE_LOADED=1
