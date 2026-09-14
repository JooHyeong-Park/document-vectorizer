#!/usr/bin/env bash

set -Eeuo pipefail

# CPython portable runtime for WSL2 Linux x86_64.
# Keep the runtime outside the repository and do not modify global shell state.
PYTHON_BUILD_VERSION="20260901"
PYTHON_VERSION="3.13.15"
PYTHON_ARTIFACT="cpython-${PYTHON_VERSION}+${PYTHON_BUILD_VERSION}-x86_64-unknown-linux-gnu-install_only.tar.gz"
PYTHON_SHA256="0651dd7157d3debf769e15a52c1de9de7fbcdc36ba72faf79fde3c44f14d9461"
PYTHON_DOWNLOAD_URL="https://github.com/astral-sh/python-build-standalone/releases/download/${PYTHON_BUILD_VERSION}/${PYTHON_ARTIFACT/+/%2B}"

RUNTIMES_PATH="${RUNTIMES_PATH:-${HOME}/runtimes}"
ARCHIVES_PATH="${RUNTIMES_PATH}/archives"
INSTALL_PATH="${RUNTIMES_PATH}/python-${PYTHON_VERSION}"
ARCHIVE_PATH="${ARCHIVES_PATH}/${PYTHON_ARTIFACT}"

mkdir -p "${ARCHIVES_PATH}"

if [[ ! -f "${ARCHIVE_PATH}" ]]; then
  curl --fail --location --silent --show-error --retry 3 \
    --output "${ARCHIVE_PATH}" \
    "${PYTHON_DOWNLOAD_URL}"
fi

printf '%s  %s\n' "${PYTHON_SHA256}" "${ARCHIVE_PATH}" | sha256sum --check --status

if [[ -x "${INSTALL_PATH}/bin/python3.13" ]]; then
  "${INSTALL_PATH}/bin/python3.13" --version
  exit 0
fi

if [[ -e "${INSTALL_PATH}" ]]; then
  printf '[ERROR] Incomplete installation exists: %s\n' "${INSTALL_PATH}" >&2
  exit 1
fi

mkdir -p "${INSTALL_PATH}"
tar --extract --file "${ARCHIVE_PATH}" --strip-components=1 --directory "${INSTALL_PATH}"

"${INSTALL_PATH}/bin/python3.13" --version
printf '[INFO] Python %s installed at %s\n' "${PYTHON_VERSION}" "${INSTALL_PATH}"
