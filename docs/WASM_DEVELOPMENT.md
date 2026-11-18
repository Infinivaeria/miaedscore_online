# WebAssembly Deployment

The Roda application continues to serve its existing routes. This deployment adds no Roda route and no standalone HTML page. The compiled module is published as the regular static asset `/assets/midscore_moon.wasm`.

## One-Time Setup

Install Caddy 2.8 or later with its systemd service using the
[official installation instructions](https://caddyserver.com/docs/install), then
allow inbound TCP ports 80 and 443 and UDP port 443 in the host/network firewall.
The deployment installs `Caddyfile` at `/etc/caddy/Caddyfile` and enables Caddy.
On the first deployment it replaces Puma's direct HTTPS listener with Caddy;
Caddy obtains and renews its own certificate for `miaedscore.online`.

Run these commands from the repository root:

```sh
bundle install
rustup target add wasm32-unknown-unknown
chmod +x bin/run-wasm-https bin/start-wasm-https-background.sh
```

## Start HTTPS In The Background

From an SSH shell, run this command every time the public service needs to be started or restarted:

```sh
cd /root/miaedscore
bin/start-wasm-https-background.sh
```

The background wrapper runs `bin/run-wasm-https` detached from the SSH session and writes progress to `log/run-wasm-https.log`. The deployment rebuilds the module, deploys it to `public/assets/midscore_moon.wasm`, and runs Puma on `127.0.0.1:9292`. Caddy terminates TLS on port 443 and proxies requests to Puma; it serves HTTP/2 and HTTP/3 while the browser can fetch the same WASM asset URL over either protocol. HTTP/3 requires inbound UDP port 443. The deployment verifies that the asset is served with `application/wasm` over HTTP/2 as well as that `/moon` responds. Concurrent deployments are rejected. Existing Roda routes and templates remain unchanged.

The scheduled `update.sh` runs from the repository root, stops on update or build errors, and runs the deployment synchronously. Its progress and final exit status are written to `update-cron.log`; Puma's own output remains in `log/stdout` and `log/stderr`.

The deployment must run as `root` to manage the Puma and Caddy services. Caddy manages HTTPS certificates independently from the old Certbot certificate. The existing Certbot renewal used the standalone authenticator on port 80, which conflicts with Caddy's HTTP listener. After Caddy's certificate was verified, the old Certbot timer was disabled (it managed only this host's certificate). Puma writes logs to `log/stdout` and `log/stderr`.

Verify the route and WASM asset over HTTP/2:

```sh
curl --fail --http2 --output /dev/null --write-out '%{http_version}\n' https://miaedscore.online/moon
curl --fail --http2 --output /dev/null --write-out '%{http_version} %{content_type}\n' https://miaedscore.online/assets/midscore_moon.wasm
```

The first command should report HTTP version `2`; the second should report `2 application/wasm`. HTTP/3 is advertised with `Alt-Svc`; a browser may use HTTP/2 for its first request while learning that alternative. If Chrome continues to report `http/2.0` on a fresh connection, ensure inbound UDP port 443 is allowed by the hosting/network firewall and that QUIC is enabled in the browser. A client with HTTP/3 support can also verify with `curl --http3-only`.

Follow a background deployment:

```sh
tail -f log/run-wasm-https.log
```