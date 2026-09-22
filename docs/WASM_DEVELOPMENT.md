# WebAssembly Deployment

The Roda application continues to serve its existing routes. This deployment adds no Roda route and no standalone HTML page. The compiled module is published as the regular static asset `/assets/midscore_moon.wasm`.

## One-Time Setup

Run these commands from the repository root:

```sh
bundle install
rustup target add wasm32-unknown-unknown
chmod +x bin/run-wasm-https bin/start-wasm-https-background
```

## Start HTTPS In The Background

From an SSH shell, run this command every time the public service needs to be started or restarted:

```sh
cd /root/miaedscore
bin/start-wasm-https-background
```

The background wrapper runs `bin/run-wasm-https` detached from the SSH session and writes progress to `log/run-wasm-https.log`. The deployment rebuilds the module, deploys it to `public/assets/midscore_moon.wasm`, stops the Puma instance recorded in `config/puma.state` when it is running, and starts Puma detached from the SSH session. Existing Roda routes and templates remain unchanged. The application loads its databases at boot, so allow about 30 seconds before sending requests.

The command must run as `root` because port `443` is privileged. SSH continues to use port `22`; HTTPS cannot run on port `22` at the same time. Puma writes logs to `log/stdout` and `log/stderr`.

Verify the existing Roda route and the static asset:

```sh
curl --fail --insecure --output /dev/null https://127.0.0.1/moon
curl --fail --insecure --output /dev/null https://127.0.0.1/assets/midscore_moon.wasm
```

Follow a background deployment:

```sh
tail -f log/run-wasm-https.log
```