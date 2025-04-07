#!/bin/bash

CURRENT_DIR="$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"
SCRIPTS_DIR="$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"
PROJECT_DIR="$(cd -- "$( dirname -- "${SCRIPTS_DIR}/../../../.." )" &> /dev/null && pwd)"

echo "Current directory: $CURRENT_DIR"
echo "Scripts Dir $SCRIPTS_DIR"
echo "Project directory: $PROJECT_DIR"