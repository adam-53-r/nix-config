#!/usr/bin/env bash
set -euo pipefail
sops decrypt "$1"
