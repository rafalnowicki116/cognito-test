#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_DIR="${1:-$(pwd)}"

if [[ ! -f "${SOURCE_ROOT}/AGENTS.md" ]]; then
  echo "Source AGENTS.md not found in ${SOURCE_ROOT}" >&2
  exit 1
fi

if [[ ! -d "${SOURCE_ROOT}/.opencode/skills" ]]; then
  echo "Source skills directory not found in ${SOURCE_ROOT}/.opencode/skills" >&2
  exit 1
fi

mkdir -p "${TARGET_DIR}/.opencode"

cp "${SOURCE_ROOT}/AGENTS.md" "${TARGET_DIR}/AGENTS.md"
rm -rf "${TARGET_DIR}/.opencode/skills"
cp -r "${SOURCE_ROOT}/.opencode/skills" "${TARGET_DIR}/.opencode/skills"

echo "Copied AGENTS.md and .opencode/skills to ${TARGET_DIR}"
