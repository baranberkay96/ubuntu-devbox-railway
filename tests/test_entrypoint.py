"""Regression checks for deploy-form handling without changing the host system."""
import os
from pathlib import Path
import subprocess
import unittest


ENTRYPOINT = Path(__file__).resolve().parents[1] / "services/devbox/rootfs/usr/local/bin/devbox-entrypoint"


def check_ports(http_port, ssh_port="22"):
    # Load the shipped functions, leaving the root-only startup sequence uncalled.
    source, separator, trailing = ENTRYPOINT.read_text().rpartition('\nmain "$@"')
    if not separator or trailing.strip():
        raise AssertionError("Cannot safely isolate entrypoint functions from startup")
    result = subprocess.run(
        ["bash", "-c", source + '\ncheck_ports\nprintf "%s %s\\n" "$HTTP_PORT" "$SSH_PORT"'],
        env={"PATH": os.defpath, "PORT": http_port, "SSH_PORT": ssh_port},
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip()


class PortInputTests(unittest.TestCase):
    def test_leading_zero_http_port_keeps_railway_probe_port(self):
        self.assertEqual(check_ports("09090"), "9090 22")

    def test_leading_zero_ssh_port_is_decimal(self):
        self.assertEqual(check_ports("9090", "002222"), "9090 2222")

    def test_fallback_ssh_port_cannot_collide_with_http(self):
        self.assertEqual(check_ports("22", "7681"), "8080 22")

    def test_invalid_ports_keep_safe_defaults(self):
        for value in ("0", "00000", "65536", "-1", "abc", "8080\ninvalid"):
            with self.subTest(value=value):
                self.assertEqual(check_ports(value, value), "8080 22")

    def test_valid_port_boundaries_and_defaults(self):
        for value in ("1", "8080", "9090", "65535"):
            with self.subTest(value=value):
                self.assertEqual(check_ports(value), f"{value} 22")


if __name__ == "__main__":
    unittest.main()
