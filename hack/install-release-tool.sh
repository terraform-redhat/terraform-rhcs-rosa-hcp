#!/usr/bin/env bash
# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0
#
# Install a pinned CLI into LOCALBIN. Invoked from the Makefile only.
# Usage: install-release-tool.sh <addlicense|tflint|terraform-docs|vale|checkov|gitleaks> <version> <dest_dir>

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

tool="${1:?tool name required (addlicense, tflint, terraform-docs, vale, checkov, or gitleaks)}"
version="${2:?version required (e.g. v0.58.1)}"
dest_dir="${3:?destination directory required}"

version_no_v="${version#v}"
arch="$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')"
os="$(uname | tr '[:upper:]' '[:lower:]')"

sha256_verify() {
  local archive_path=$1
  local checksum_path=$2
  local archive_name
  archive_name=$(basename "$archive_path")

  if command -v sha256sum >/dev/null 2>&1; then
    (cd "$(dirname "$archive_path")" && grep -F " ${archive_name}" "$checksum_path" | sha256sum -c -)
  elif command -v shasum >/dev/null 2>&1; then
    (cd "$(dirname "$archive_path")" && grep -F " ${archive_name}" "$checksum_path" | shasum -a 256 -c -)
  else
    echo "sha256sum or shasum is required to verify ${archive_name}" >&2
    return 1
  fi
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$dest_dir"

case "$tool" in
  addlicense)
    case "${os}_${arch}" in
      linux_amd64) platform_label="Linux_x86_64" archive_ext="tar.gz" ;;
      linux_arm64) platform_label="Linux_arm64" archive_ext="tar.gz" ;;
      darwin_amd64) platform_label="macOS_x86_64" archive_ext="tar.gz" ;;
      darwin_arm64) platform_label="macOS_arm64" archive_ext="tar.gz" ;;
      windows_amd64) platform_label="Windows_x86_64" archive_ext="zip" ;;
      windows_arm64) platform_label="Windows_arm64" archive_ext="zip" ;;
      *)
        echo "Unsupported platform for addlicense: ${os}_${arch}" >&2
        exit 1
        ;;
    esac
    asset="addlicense_${version}_${platform_label}.${archive_ext}"
    url="https://github.com/google/addlicense/releases/download/${version}/${asset}"
    checksums_url="https://github.com/google/addlicense/releases/download/${version}/checksums.txt"
    dest_bin="${dest_dir}/addlicense"

    curl -fsSL -o "${tmp}/${asset}" "$url"
    curl -fsSL -o "${tmp}/checksums.txt" "$checksums_url"
    sha256_verify "${tmp}/${asset}" "${tmp}/checksums.txt"

    if [ "$archive_ext" = "zip" ]; then
      unzip -o "${tmp}/${asset}" -d "$tmp"
    else
      tar -xzf "${tmp}/${asset}" -C "$tmp" addlicense
    fi
    install -m 0755 "${tmp}/addlicense" "$dest_bin"
    ;;

  tflint)
    asset="tflint_${os}_${arch}.zip"
    url="https://github.com/terraform-linters/tflint/releases/download/${version}/${asset}"
    checksums_url="https://github.com/terraform-linters/tflint/releases/download/${version}/checksums.txt"
    dest_bin="${dest_dir}/tflint"

    curl -fsSL -o "${tmp}/${asset}" "$url"
    curl -fsSL -o "${tmp}/checksums.txt" "$checksums_url"
    sha256_verify "${tmp}/${asset}" "${tmp}/checksums.txt"

    unzip -o "${tmp}/${asset}" -d "$tmp"
    install -m 0755 "${tmp}/tflint" "$dest_bin"
    ;;

  terraform-docs)
    asset="terraform-docs-v${version_no_v}-${os}-${arch}.tar.gz"
    url="https://terraform-docs.io/dl/v${version_no_v}/${asset}"
    checksums_url="https://terraform-docs.io/dl/v${version_no_v}/terraform-docs-v${version_no_v}.sha256sum"
    dest_bin="${dest_dir}/terraform-docs"

    curl -fsSL -o "${tmp}/${asset}" "$url"
    curl -fsSL -o "${tmp}/checksums.txt" "$checksums_url"
    sha256_verify "${tmp}/${asset}" "${tmp}/checksums.txt"

    tar -xzf "${tmp}/${asset}" -C "$tmp" terraform-docs
    install -m 0755 "${tmp}/terraform-docs" "$dest_bin"
    ;;

  vale)
    case "${os}_${arch}" in
      linux_amd64) platform_label="Linux_64-bit" archive_ext="tar.gz" ;;
      linux_arm64) platform_label="Linux_arm64" archive_ext="tar.gz" ;;
      darwin_amd64) platform_label="macOS_64-bit" archive_ext="tar.gz" ;;
      darwin_arm64) platform_label="macOS_arm64" archive_ext="tar.gz" ;;
      windows_amd64) platform_label="Windows_64-bit" archive_ext="zip" ;;
      *)
        echo "Unsupported platform for vale: ${os}_${arch}" >&2
        exit 1
        ;;
    esac
    asset="vale_${version_no_v}_${platform_label}.${archive_ext}"
    url="https://github.com/vale-cli/vale/releases/download/${version}/${asset}"
    checksums_url="https://github.com/vale-cli/vale/releases/download/${version}/vale_${version_no_v}_checksums.txt"
    dest_bin="${dest_dir}/vale"

    curl -fsSL -o "${tmp}/${asset}" "$url"
    curl -fsSL -o "${tmp}/checksums.txt" "$checksums_url"
    sha256_verify "${tmp}/${asset}" "${tmp}/checksums.txt"

    if [ "$archive_ext" = "zip" ]; then
      unzip -o "${tmp}/${asset}" -d "$tmp"
    else
      tar -xzf "${tmp}/${asset}" -C "$tmp" vale
    fi
    install -m 0755 "${tmp}/vale" "$dest_bin"
    ;;

  checkov)
    # bridgecrewio/checkov GitHub releases do not publish checksum files; verify against
    # repo-pinned hack/checksums/checkov-<version>.sha256sums instead.
    case "${os}_${arch}" in
      linux_amd64) asset="checkov_linux_X86_64.zip" ;;
      linux_arm64) asset="checkov_linux_arm64.zip" ;;
      darwin_amd64) asset="checkov_darwin_X86_64.zip" ;;
      windows_amd64) asset="checkov_windows_X86_64.zip" ;;
      *)
        echo "Unsupported platform for checkov: ${os}_${arch}" >&2
        exit 1
        ;;
    esac
    url="https://github.com/bridgecrewio/checkov/releases/download/${version}/${asset}"
    checksums_file="${script_dir}/checksums/checkov-${version}.sha256sums"
    dest_bin="${dest_dir}/checkov"

    if [ ! -f "${checksums_file}" ]; then
      echo "Missing pinned checksums: ${checksums_file}" >&2
      echo "bridgecrewio/checkov releases do not publish upstream checksum files; add SHA256 sums for each platform zip when bumping CHECKOV_VERSION (see CONTRIBUTING.md)." >&2
      exit 1
    fi

    curl -fsSL -o "${tmp}/${asset}" "$url"
    sha256_verify "${tmp}/${asset}" "${checksums_file}"
    unzip -o "${tmp}/${asset}" -d "$tmp"
    install -m 0755 "${tmp}/dist/checkov" "$dest_bin"
    ;;

  gitleaks)
    case "${os}_${arch}" in
      linux_amd64) platform_suffix="linux_x64" archive_ext="tar.gz" ;;
      linux_arm64) platform_suffix="linux_arm64" archive_ext="tar.gz" ;;
      darwin_amd64) platform_suffix="darwin_x64" archive_ext="tar.gz" ;;
      darwin_arm64) platform_suffix="darwin_arm64" archive_ext="tar.gz" ;;
      windows_amd64) platform_suffix="windows_x64" archive_ext="zip" ;;
      *)
        echo "Unsupported platform for gitleaks: ${os}_${arch}" >&2
        exit 1
        ;;
    esac
    asset="gitleaks_${version_no_v}_${platform_suffix}.${archive_ext}"
    url="https://github.com/gitleaks/gitleaks/releases/download/${version}/${asset}"
    checksums_url="https://github.com/gitleaks/gitleaks/releases/download/${version}/gitleaks_${version_no_v}_checksums.txt"
    curl -fsSL -o "${tmp}/${asset}" "$url"
    curl -fsSL -o "${tmp}/checksums.txt" "$checksums_url"
    sha256_verify "${tmp}/${asset}" "${tmp}/checksums.txt"

    if [ "$archive_ext" = "zip" ]; then
      unzip -o "${tmp}/${asset}" -d "$tmp"
      dest_bin="${dest_dir}/gitleaks.exe"
      install -m 0755 "${tmp}/gitleaks.exe" "$dest_bin"
    else
      tar -xzf "${tmp}/${asset}" -C "$tmp" gitleaks
      dest_bin="${dest_dir}/gitleaks"
      install -m 0755 "${tmp}/gitleaks" "$dest_bin"
    fi
    ;;

  *)
    echo "Unsupported tool: ${tool}" >&2
    exit 1
    ;;
esac

echo "Installed ${tool} ${version} at ${dest_bin}"
