"""Regression checks using real child processes, without opening network ports."""
import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import signal
import time
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).with_name('md-preview')
loader = importlib.machinery.SourceFileLoader('md_preview', str(SCRIPT))
spec = importlib.util.spec_from_loader(loader.name, loader)
module = importlib.util.module_from_spec(spec)
loader.exec_module(module)


class LifecycleTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.bin = self.root / ('bin-' + 'long-name-' * 10)
        self.bin.mkdir()
        binary = self.bin / 'mdserve'
        binary.write_text('#!' + sys.executable + '\nimport time\ntime.sleep(120)\n')
        binary.chmod(0o755)
        self.config = self.root / 'config.json'
        self.config.write_text(json.dumps({'services': {
            'one': {'directory': '.', 'port': 18741},
            'two': {'directory': '.', 'port': 18742},
        }}))
        self.env = dict(os.environ, PATH=str(self.bin) + os.pathsep + os.environ['PATH'],
                        XDG_STATE_HOME=str(self.root / 'state'), COLUMNS='300')

    def run_cli(self, *args, expected=0, columns='300'):
        result = subprocess.run([sys.executable, str(SCRIPT), '-c', str(self.config), *args],
                                env=dict(self.env, COLUMNS=columns), capture_output=True, text=True)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return result.stdout + result.stderr

    def states(self):
        return list((self.root / 'state').rglob('state.json'))

    def tearDown(self):
        # Stop even if the state record was deliberately corrupted by a test.
        for path in self.states():
            state = json.loads(path.read_text())
            if module.identity(state['pid']):
                os.kill(state['pid'], 9)
        self.temp.cleanup()

    def check_foreground(self, selection, expected_names, existing=False):
        if existing:
            self.run_cli('start', '-b', '--service', 'one')
        proc = subprocess.Popen(
            [sys.executable, str(SCRIPT), '-c', str(self.config), 'start', *selection],
            env=self.env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            deadline = time.monotonic() + 5
            expected_count = len(expected_names | ({'one'} if existing else set()))
            while time.monotonic() < deadline:
                if len(self.states()) == expected_count or proc.poll() is not None:
                    break
                time.sleep(0.05)
            states = [json.loads(path.read_text()) for path in self.states()]
            self.assertEqual({s['service'] for s in states},
                             expected_names | ({'one'} if existing else set()))
            self.assertIsNone(proc.poll())
            self.assertTrue(all(module.running(s) for s in states))
            proc.send_signal(signal.SIGINT)
            proc.communicate(timeout=8)
            self.assertEqual(proc.returncode, 130)
            for state in states:
                self.assertEqual(bool(module.identity(state['pid'])),
                                 existing and state['service'] == 'one')
        finally:
            if proc.poll() is None:
                proc.terminate()
                proc.communicate(timeout=8)

    def test_foreground_starts_all_by_default(self):
        self.check_foreground([], {'one', 'two'})

    def test_foreground_explicit_all(self):
        self.check_foreground(['--all'], {'one', 'two'})

    def test_foreground_single_service(self):
        self.check_foreground(['--service', 'two'], {'two'})

    def test_foreground_keeps_existing_service_on_interrupt(self):
        self.check_foreground([], {'two'}, existing=True)

    def test_independent_stop_with_different_terminal_width(self):
        self.run_cli('start', '-b')
        self.assertEqual(len(self.states()), 2)
        self.run_cli('status', columns='40')
        self.run_cli('stop', '--service', 'one', columns='40')
        self.run_cli('status', '--service', 'one', expected=1)
        self.run_cli('status', '--service', 'two')
        self.run_cli('stop')
        self.assertEqual(self.states(), [])

    def test_legacy_truncated_record(self):
        self.run_cli('start', '-b', '--service', 'one')
        path = self.states()[0]
        state = json.loads(path.read_text())
        state['identity'] = module.legacy_identity(state['pid'])[:75]
        path.write_text(json.dumps(state))
        self.run_cli('stop', '--service', 'one', columns='40')
        self.assertFalse(module.identity(state['pid']))

    def test_wrong_identity_does_not_kill_process(self):
        self.run_cli('start', '-b', '--service', 'one')
        path = self.states()[0]
        state = json.loads(path.read_text())
        state['identity'] = 'linux:wrong-boot:123'
        path.write_text(json.dumps(state))
        output = self.run_cli('stop', '--service', 'one', expected=1)
        self.assertIn('身份不匹配', output)
        self.assertTrue(module.identity(state['pid']))

    def test_legacy_wall_clock_change(self):
        self.run_cli('start', '-b', '--service', 'one')
        path = self.states()[0]
        state = json.loads(path.read_text())
        legacy = module.legacy_identity(state['pid'])
        state['identity'] = 'Mon Jan  1 00:00:00 2001 ' + legacy.split(None, 5)[5]
        path.write_text(json.dumps(state))
        self.run_cli('stop', '--service', 'one')
        self.assertFalse(module.identity(state['pid']))

    def test_force_stop_unresponsive_process(self):
        (self.bin / 'mdserve').write_text('#!' + sys.executable + '\nimport signal, time\nsignal.signal(signal.SIGTERM, signal.SIG_IGN)\ntime.sleep(120)\n')
        self.run_cli('start', '-b', '--service', 'one')
        pid = json.loads(self.states()[0].read_text())['pid']
        self.run_cli('stop', '--service', 'one')
        self.assertFalse(module.identity(pid))
        self.assertEqual(self.states(), [])


if __name__ == '__main__':
    unittest.main()
