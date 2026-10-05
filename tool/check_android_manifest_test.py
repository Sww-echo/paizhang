"""Run without an Android SDK: python3 -m unittest discover -s tool -p '*_test.py'."""
from pathlib import Path
import tempfile
import unittest

from check_android_manifest import check_manifests


class ManifestCheckTest(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)

    def write_manifest(self, folder='merged_manifests/release/processReleaseManifest',
                       permission='<uses-permission android:name="android.permission.INTERNET"/>',
                       application='<application/>', package='com.example.paizhang.verification'):
        path = self.root / folder / 'AndroidManifest.xml'
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(
            f'<manifest xmlns:android="http://schemas.android.com/apk/res/android" '
            f'package="{package}">{permission}{application}</manifest>',
            encoding='utf-8',
        )
        return path

    def test_checks_all_generated_release_manifests(self):
        self.write_manifest()
        self.write_manifest(folder='packaged_manifests/release/processReleaseManifestForPackage')
        self.assertEqual(check_manifests(self.root, 'com.example.paizhang.verification'), 2)

    def test_debug_and_source_manifests_do_not_count(self):
        self.write_manifest(folder='merged_manifests/debug/processDebugManifest')
        self.write_manifest(folder='src/release')
        with self.assertRaisesRegex(ValueError, 'No merged release manifest'):
            check_manifests(self.root)

    def test_requires_unrestricted_internet_permission(self):
        for permission in ['', '<uses-permission android:name="android.permission.INTERNET" android:maxSdkVersion="28"/>']:
            with self.subTest(permission=permission):
                self.write_manifest(permission=permission)
                with self.assertRaisesRegex(ValueError, 'unrestricted INTERNET'):
                    check_manifests(self.root)

    def test_checks_expected_application_id(self):
        self.write_manifest(package='com.example.paizhang')
        with self.assertRaisesRegex(ValueError, 'applicationId'):
            check_manifests(self.root, 'com.example.paizhang.verification')

    def test_rejects_debuggable_release(self):
        self.write_manifest(application='<application android:debuggable="true"/>')
        with self.assertRaisesRegex(ValueError, 'must not be debuggable'):
            check_manifests(self.root)

    def test_requires_application(self):
        self.write_manifest(application='')
        with self.assertRaisesRegex(ValueError, 'missing application'):
            check_manifests(self.root)

    def test_does_not_pass_when_one_generated_manifest_is_invalid(self):
        self.write_manifest()
        self.write_manifest(folder='merged_manifest/release/processReleaseMainManifest', permission='')
        with self.assertRaisesRegex(ValueError, 'unrestricted INTERNET'):
            check_manifests(self.root)


if __name__ == '__main__':
    unittest.main()
