#!/usr/bin/env bash

set -Eeuo pipefail

# Install Azure Functions Core Tools v4 on Ubuntu 24.04 amd64 under WSL2.
if command -v func >/dev/null 2>&1; then
  func --version
  exit 0
fi

for command_name in curl gpg sudo; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    printf '[ERROR] Required command is not installed: %s\n' "${command_name}" >&2
    exit 1
  fi
done

architecture="$(dpkg --print-architecture)"
if [[ "${architecture}" != "amd64" ]]; then
  printf '[ERROR] Unsupported architecture for this installer: %s\n' "${architecture}" >&2
  exit 1
fi

source /etc/os-release
if [[ "${ID}" != "ubuntu" || "${VERSION_ID}" != "24.04" ]]; then
  printf '[ERROR] This installer requires Ubuntu 24.04.\n' >&2
  exit 1
fi

keyring_path="/etc/apt/trusted.gpg.d/microsoft.gpg"
source_list_path="/etc/apt/sources.list.d/azure-functions.list"

curl --fail --location --silent --show-error \
  https://packages.microsoft.com/keys/microsoft.asc \
  | gpg --dearmor \
  | sudo tee "${keyring_path}" >/dev/null

printf '%s\n' \
  'deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-noble-prod noble main' \
  | sudo tee "${source_list_path}" >/dev/null
sudo apt-get update
sudo apt-get install --yes azure-functions-core-tools-4

func --version
