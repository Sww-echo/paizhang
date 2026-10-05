"""Check generated release manifests, never debug/source manifests."""
from __future__ import annotations

import argparse
from pathlib import Path
import xml.etree.ElementTree as ET

ANDROID = '{http://schemas.android.com/apk/res/android}'
MANIFEST_DIRS = {'merged_manifest', 'merged_manifests', 'packaged_manifests'}


def check_manifests(root: Path, expected_application_id: str | None = None) -> int:
    files = sorted(
        path for path in root.rglob('AndroidManifest.xml')
        if 'release' in path.relative_to(root).parts
        and MANIFEST_DIRS.intersection(path.relative_to(root).parts)
    )
    if not files:
        raise ValueError('No merged release manifest found; compile a release/verification build first.')
    for path in files:
        manifest = ET.parse(path).getroot()
        internet = [item for item in manifest.findall('uses-permission')
                    if item.get(f'{ANDROID}name') == 'android.permission.INTERNET'
                    and item.get(f'{ANDROID}maxSdkVersion') is None]
        if not internet:
            raise ValueError(f'Release manifest is missing unrestricted INTERNET: {path}')
        if expected_application_id and manifest.get('package') != expected_application_id:
            raise ValueError(f'Release manifest applicationId differs from expected value: {path}')
        application = manifest.find('application')
        if application is None:
            raise ValueError(f'Release manifest is missing application: {path}')
        if application.get(f'{ANDROID}debuggable', 'false') != 'false':
            raise ValueError(f'Release manifest must not be debuggable: {path}')
    return len(files)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path,
                        default=Path(__file__).resolve().parents[1] / 'build/app/intermediates')
    parser.add_argument('--expected-application-id')
    args = parser.parse_args()
    try:
        count = check_manifests(args.root, args.expected_application_id)
    except (ValueError, ET.ParseError) as error:
        raise SystemExit(str(error)) from error
    print(f'Validated INTERNET, non-debuggable application and requested identity in {count} release manifest(s).')


if __name__ == '__main__':
    main()
