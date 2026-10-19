"""Regenerate the browser's embedded schema without requiring fetch/file access."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCHEMA = ROOT / 'tools/content_schema.json'
BROWSER = ROOT / 'tools/level-editor/modules/content-schema.js'

def expected():
    schema = json.loads(SCHEMA.read_text(encoding='utf-8'))
    return ('// Generated from tools/content_schema.json; run tools/sync_content_schema.py.\n'
            + 'globalThis.ThesisEditor.contentSchema = '
            + json.dumps(schema, ensure_ascii=False, indent=2) + ';\n')

if __name__ == '__main__':
    BROWSER.write_text(expected(), encoding='utf-8')
    print('SCHEMA SYNC ok')
