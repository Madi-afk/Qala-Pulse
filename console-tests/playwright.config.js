import { defineConfig } from "@playwright/test";
import { existsSync } from "node:fs";
import path from "node:path";

const root = path.resolve(import.meta.dirname, "..");
const localPython = path.join(
  root,
  ".venv",
  process.platform === "win32" ? "Scripts/python.exe" : "bin/python",
);
const python =
  process.env.CONSOLE_TEST_PYTHON ||
  (existsSync(localPython) ? localPython : "python");
export default defineConfig({
  testDir: "./tests",
  timeout: 45000,
  workers: 1,
  fullyParallel: false,
  expect: { timeout: 10000 },
  use: {
    baseURL: "http://127.0.0.1:18765",
    viewport: { width: 1440, height: 1000 },
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    ...(process.env.CONSOLE_BROWSER_CHANNEL
      ? { channel: process.env.CONSOLE_BROWSER_CHANNEL }
      : {}),
  },
  webServer: {
    command: `"${python}" scripts/run_console_test_server.py --port 18765`,
    cwd: root,
    url: "http://127.0.0.1:18765/console/",
    reuseExistingServer: false,
    timeout: 60000,
  },
});
