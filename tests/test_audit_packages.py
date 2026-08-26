"""Regression tests for package profile selection in audit-packages."""

import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]
AUDITOR = REPOSITORY / "dot_local/bin/executable_audit-packages"
MANIFEST = REPOSITORY / ".chezmoidata/packages.toml"


class AuditPackagesTests(unittest.TestCase):
    """Verify that audits use only the packages selected for this machine."""

    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary_directory.cleanup)
        self.root = Path(self.temporary_directory.name)
        self.bin_directory = self.root / "bin"
        self.bin_directory.mkdir()

        chezmoi = self.bin_directory / "chezmoi"
        chezmoi.write_text(
            "#!/bin/sh\n"
            "printf '%s\\n' "
            '\'{"packageProfile":"full","optionalPackageExcludes":[]}\'\n'
        )
        chezmoi.chmod(0o755)

        pacman = self.bin_directory / "pacman"
        pacman.write_text('#!/bin/sh\nif [ "$1" = -Qtdq ]; then exit 1; fi\nexit 0\n')
        pacman.chmod(0o755)

    def run_auditor(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        environment = os.environ.copy()
        environment["PATH"] = str(self.bin_directory)
        return subprocess.run(
            [
                sys.executable,
                str(AUDITOR),
                "--manifest",
                str(MANIFEST),
                *arguments,
            ],
            cwd=self.root,
            env=environment,
            check=False,
            capture_output=True,
            text=True,
        )

    def missing_pacman_section(self, output: str) -> str:
        marker = "Missing declared pacman packages"
        return output.split(marker, 1)[1].split("\n\n", 1)[0]

    def test_minimal_profile_contains_only_core_packages(self) -> None:
        completed = self.run_auditor("--profile", "minimal")

        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertIn("Package profile: minimal", completed.stdout)
        missing = self.missing_pacman_section(completed.stdout)
        self.assertIn("  base-devel", missing)
        self.assertNotIn("  alacritty", missing)
        self.assertNotIn("  obsidian", missing)
        self.assertNotIn("  docker", missing)

    def test_work_profile_honors_individual_exclusion(self) -> None:
        completed = self.run_auditor(
            "--profile", "work", "--exclude", "visual-studio-code-bin"
        )

        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertIn("Package profile: work", completed.stdout)
        missing = self.missing_pacman_section(completed.stdout)
        self.assertIn("  alacritty", missing)
        self.assertIn("  docker", missing)
        self.assertNotIn("  obsidian", missing)
        self.assertNotIn("  visual-studio-code-bin", missing)


if __name__ == "__main__":
    unittest.main()
