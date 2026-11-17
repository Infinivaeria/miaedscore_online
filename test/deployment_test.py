import fcntl
import os
import signal
import subprocess
import tempfile
import threading
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

MOCK_COMMAND = """#!/bin/sh
name=${0##*/}
printf '%s|%s|%s\\n' "$name" "$*" "$PWD" >> "$TEST_LOG"
if [ "${FAIL_COMMAND:-}" = "$name $*" ]; then exit 1; fi
case "$name $*" in
  "id -u") echo 0 ;;
  "rustup target list --installed") echo wasm32-unknown-unknown ;;
  "bundle exec puma -C config/puma.rb")
    echo $$ > config/puma.pid
    exec /bin/sleep 120
    ;;
  "bundle exec pumactl -S config/puma.state stop")
    if [ "${STOP_PUMA:-}" = 1 ]; then kill "$(cat config/puma.pid)"; fi
    ;;
  "curl "*)
    if [ "${FAIL_HEALTH:-}" = 1 ]; then exit 1; fi
    ;;
  "sleep "*) exec /bin/sleep 0.02 ;;
esac
"""


class DeploymentTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        for directory in ("bin", "config", "log", "mock", "wasm-client",
                          "wasm-client/target/wasm32-unknown-unknown/release"):
            (self.root / directory).mkdir(parents=True, exist_ok=True)
        self.log = self.root / "commands.log"
        self.env = os.environ.copy()
        self.env.update(PATH=f"{self.root / 'mock'}:/usr/bin:/bin", TEST_LOG=str(self.log))
        for command in ("apt", "rustup", "gem", "bundle", "cargo", "id", "curl", "sleep"):
            path = self.root / "mock" / command
            path.write_text(MOCK_COMMAND)
            path.chmod(0o755)
        (self.root / "wasm-client/target/wasm32-unknown-unknown/release/midscore_wasm_client.wasm").touch()
        self.cert = self.root / "cert"
        self.cert.touch()
        self.puma = None

    def tearDown(self):
        if self.puma:
            if self.puma.poll() is None:
                self.puma.terminate()
            self.puma.wait(timeout=5)
        pidfile = self.root / "config/puma.pid"
        if pidfile.exists():
            pid = int(pidfile.read_text())
            if not self.puma or pid != self.puma.pid:
                try:
                    os.kill(pid, signal.SIGTERM)
                except ProcessLookupError:
                    pass
        self.temp.cleanup()

    def commands(self):
        return self.log.read_text().splitlines() if self.log.exists() else []

    def install_update(self):
        update = self.root / "update.sh"
        update.write_text((ROOT / "update.sh").read_text())
        update.chmod(0o755)
        deploy = self.root / "bin/run-wasm-https"
        deploy.write_text('#!/bin/sh\nprintf "deploy|%s\\n" "$PWD" >> "$TEST_LOG"\n')
        deploy.chmod(0o755)

    def install_deploy(self):
        script = (ROOT / "bin/run-wasm-https").read_text()
        script = script.replace("/etc/letsencrypt/live/miaedscore.online/privkey.pem", str(self.cert))
        script = script.replace("/etc/letsencrypt/live/miaedscore.online/fullchain.pem", str(self.cert))
        deploy = self.root / "bin/run-wasm-https"
        deploy.write_text(script)
        deploy.chmod(0o755)

    def run_script(self, script, **env):
        return subprocess.run(
            [str(script)], cwd="/", env={**self.env, **env},
            text=True, capture_output=True, timeout=15,
        )

    def test_update_uses_correct_directories_and_stops_on_failure(self):
        self.install_update()
        result = self.run_script(self.root / "update.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(f"bundle|update|{self.root}", self.commands())
        self.assertIn(f"cargo|update|{self.root / 'wasm-client'}", self.commands())
        self.assertIn(f"deploy|{self.root}", self.commands())
        self.log.unlink()
        result = self.run_script(self.root / "update.sh", FAIL_COMMAND="apt update")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(self.commands()), 1)
        self.assertIn("finished with status 1", result.stdout)
        self.log.unlink()
        result = self.run_script(self.root / "update.sh", FAIL_COMMAND="cargo build --release")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(any(line.startswith("deploy|") for line in self.commands()))

    def test_deploy_waits_for_puma_and_checks_health(self):
        self.install_deploy()
        result = self.run_script(self.root / "bin/run-wasm-https")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Puma is serving", result.stdout)
        self.assertTrue(any(line.startswith("curl|") for line in self.commands()))
        lock = self.root / "tmp/run-wasm-https.lock"
        self.assertEqual(subprocess.run(["flock", "-n", str(lock), "true"]).returncode, 0)

    def test_deploy_reports_unhealthy_server(self):
        self.install_deploy()
        result = self.run_script(self.root / "bin/run-wasm-https", FAIL_HEALTH="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("did not become ready", result.stderr)

    def test_deploy_rejects_concurrent_run(self):
        self.install_deploy()
        (self.root / "tmp").mkdir()
        with (self.root / "tmp/run-wasm-https.lock").open("w") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            result = self.run_script(self.root / "bin/run-wasm-https")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("already running", result.stderr)
        self.assertFalse(any(line.startswith("cargo|") for line in self.commands()))

    def test_deploy_stops_existing_server_before_starting(self):
        self.install_deploy()
        self.puma = subprocess.Popen(["/bin/sleep", "120"])
        (self.root / "config/puma.pid").write_text(str(self.puma.pid))
        waiter = threading.Thread(target=self.puma.wait)
        waiter.start()
        result = self.run_script(self.root / "bin/run-wasm-https", STOP_PUMA="1")
        waiter.join(timeout=5)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIsNotNone(self.puma.poll())
        commands = self.commands()
        stop = next(i for i, line in enumerate(commands) if "exec pumactl" in line)
        start = next(i for i, line in enumerate(commands) if "exec puma -C" in line)
        self.assertLess(stop, start)

    def test_deploy_does_not_start_if_stop_fails(self):
        self.install_deploy()
        self.puma = subprocess.Popen(["/bin/sleep", "120"])
        (self.root / "config/puma.pid").write_text(str(self.puma.pid))
        result = self.run_script(
            self.root / "bin/run-wasm-https",
            FAIL_COMMAND="bundle exec pumactl -S config/puma.state stop",
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(any("exec puma -C" in line for line in self.commands()))
        self.assertIsNone(self.puma.poll())


if __name__ == "__main__":
    unittest.main()
