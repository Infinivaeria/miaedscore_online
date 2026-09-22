#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
pidfile="$root/tmp/run-wasm-https.pid"
logfile="$root/log/run-wasm-https.log"

mkdir -p "$root/tmp" "$root/log"

if [ -s "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
  printf '%s\n' "Wasm HTTPS deployment is already running (PID $(cat "$pidfile"))." >&2
  exit 1
fi

rm -f "$pidfile"
nohup "$root/bin/run-wasm-https" >"$logfile" 2>&1 < /dev/null &
printf '%s\n' "$!" > "$pidfile"
printf '%s\n' "Wasm HTTPS deployment started in the background (PID $!)."
printf '%s\n' "Follow progress with: tail -f $logfile"