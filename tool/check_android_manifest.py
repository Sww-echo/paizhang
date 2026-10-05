"""Check the generated release manifest, never the debug source manifest."""
from pathlib import Path
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1] / 'build/app/intermediates'
files = sorted(p for p in root.rglob('AndroidManifest.xml')
               if 'release' in str(p).lower() and
               any(part in ('merged_manifest', 'merged_manifests', 'packaged_manifests') for part in p.parts))
if not files:
    raise SystemExit('No merged release manifest found; compile a release/verification build first.')
name = '{http://schemas.android.com/apk/res/android}name'
for path in files:
    manifest = ET.parse(path).getroot()
    permissions = {item.get(name) for item in manifest.findall('uses-permission')}
    if 'android.permission.INTERNET' not in permissions:
        raise SystemExit(f'Release manifest is missing INTERNET: {path}')
print(f'INTERNET is present in {len(files)} generated release manifest(s).')
