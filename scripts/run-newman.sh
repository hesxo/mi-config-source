#!/usr/bin/env bash
set -euo pipefail

newman run integration/newman/collection.json \
  -e integration/newman/environment.json
