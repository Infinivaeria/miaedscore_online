#!/usr/bin/env bash
set -Eeuo pipefail

root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$root"

trap 'status=$?; printf "[%s] Update finished with status %s\n" "$(date -Is)" "$status"' EXIT
printf '[%s] Starting update in %s\n' "$(date -Is)" "$root"

apt update
apt upgrade -y
rustup update
gem update --system
gem update
bundle update
(cd "$root/wasm-client" && cargo update && cargo build --release)
"$root/bin/run-wasm-https"