#!/bin/sh
set -eu
repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
python3 - "$repo_root" <<'PY'
from pathlib import Path
import runpy
import sys
import tempfile
import unittest

repo = Path(sys.argv.pop())
render = runpy.run_path(str(repo / 'scripts/common/render-agent-instructions.py'))['render']


class InstructionsTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / 'source'
        self.source.mkdir()
        self.output = self.root / 'output'

    def test_render_preserves_body_and_code_examples(self):
        body = ('## Policy\n\nKeep this.\n\n'
                '````markdown\n## Inside code\n```\n# Still inside\n````\n'
                '~~~sh\n# A comment\n~~~\n'
                '## Next\n\n```markdown\n---\nauthor: Example\n---\n```\n')
        (self.source / 'z.md').write_text('---\nauthor: Koki Aoyagi\n---\n\n' + body)
        (self.source / 'a.md').write_text('First rule.\n')
        render(self.source, self.output)
        self.assertEqual((self.output / '.claude/rules/z.md').read_text(), body)
        codex = (self.output / '.codex/AGENTS.md').read_text()
        self.assertLess(codex.index('## a\n'), codex.index('## z\n'))
        self.assertIn(body.replace('## Policy', '### Policy').replace('## Next', '### Next'), codex)
        self.assertNotIn('author: Koki Aoyagi', codex)
        (self.source / 'a.md').unlink()
        (self.source / 'new.md').write_text('New rule.\n')
        second = self.root / 'second'
        render(self.source, second)
        self.assertEqual(sorted(p.name for p in (second / '.claude/rules').iterdir()), ['new.md', 'z.md'])

    def test_invalid_input_does_not_produce_partial_instructions(self):
        with self.assertRaises(ValueError):
            render(self.source, self.output)
        (self.source / 'a.md').write_text('Valid.\n')
        (self.source / 'broken.md').write_text('---\nauthor: Missing delimiter\n')
        with self.assertRaises(ValueError):
            render(self.source, self.output)
        self.assertFalse(self.output.exists())

    def test_refuses_to_overwrite_existing_output(self):
        (self.source / 'a.md').write_text('Rule.\n')
        self.output.mkdir()
        existing = self.output / 'user-file'
        existing.write_text('Keep me.\n')
        with self.assertRaises(ValueError):
            render(self.source, self.output)
        self.assertEqual(existing.read_text(), 'Keep me.\n')


unittest.main()
PY
