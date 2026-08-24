"""Regression tests for the standalone tool updater."""

import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]
UPDATER = REPOSITORY / "dot_local/bin/executable_update-standalone"


class UpdateStandaloneTests(unittest.TestCase):
    """Exercise configuration loading and contextual failure reporting."""

    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary_directory.cleanup)
        self.root = Path(self.temporary_directory.name)
        self.home = self.root / "home"
        self.home.mkdir()

    def run_updater(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        environment = os.environ.copy()
        environment["HOME"] = str(self.home)
        environment.pop("XDG_CONFIG_HOME", None)
        return subprocess.run(
            [sys.executable, str(UPDATER), *arguments],
            cwd=self.root,
            env=environment,
            check=False,
            capture_output=True,
            text=True,
        )

    def test_default_manifest_is_resolved_from_home(self) -> None:
        config = self.home / ".config/update-standalone/tools.toml"
        config.parent.mkdir(parents=True)
        config.write_text("[standalone]\ntools = []\n")

        completed = self.run_updater()

        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertIn("Standalone update completed.", completed.stdout)

    def test_manifest_read_error_contains_path(self) -> None:
        completed = self.run_updater("--config", str(self.root))

        self.assertEqual(completed.returncode, 2)
        self.assertIn(str(self.root), completed.stderr)
        self.assertIn("Could not read standalone tool manifest", completed.stderr)

    def test_command_failure_contains_tool_and_command(self) -> None:
        binary = self.home / "bin/broken-tool"
        binary.parent.mkdir(parents=True)
        binary.write_text("#!/bin/sh\nexit 0\n")
        binary.chmod(0o755)

        config = self.root / "tools.toml"
        config.write_text(
            """
[standalone]

[[standalone.tools]]
id = "broken"
name = "Broken Tool"
binary = "{home}/bin/broken-tool"

[standalone.tools.update]
method = "command"
command = ["{home}/bin/missing-command"]
""".lstrip()
        )

        completed = self.run_updater("--config", str(config))

        self.assertEqual(completed.returncode, 1)
        self.assertIn("Broken Tool", completed.stderr)
        self.assertIn("update command", completed.stderr)
        self.assertIn(str(self.home / "bin/missing-command"), completed.stderr)


if __name__ == "__main__":
    unittest.main()
