"""Regression: converting aerial/other providers must produce static-image choices."""
import importlib.machinery
import importlib.util
import pathlib
import plistlib
import tempfile
import unittest
from unittest.mock import patch

HELPER = pathlib.Path(__file__).resolve().parents[1] / 'home/.local/bin/wallpaper-all-spaces'
loader = importlib.machinery.SourceFileLoader('wallpaper_all_spaces', str(HELPER))
spec = importlib.util.spec_from_loader(loader.name, loader)
helper = importlib.util.module_from_spec(spec)
with patch('sys.dont_write_bytecode', True):
    loader.exec_module(helper)


class WallpaperTests(unittest.TestCase):
    def test_replaces_provider_and_all_choices_without_touching_idle(self):
        with tempfile.TemporaryDirectory() as temp:
            image = pathlib.Path(temp) / 'wallpaper with spaces.jpg'
            image.touch()
            store = pathlib.Path(temp) / 'Index.plist'
            aerial = {'Provider': 'com.apple.wallpaper.choice.aerials',
                      'Files': [], 'Configuration': b'old'}
            desktop = {'Content': {'Choices': [aerial, aerial.copy()],
                                  'EncodedOptionValues': b'aerial-options', 'Shuffle': '$null'}}
            idle = {'Content': {'Choices': [aerial]}}
            store.write_bytes(plistlib.dumps({
                'SystemDefault': {'Desktop': desktop, 'Idle': idle},
                'Spaces': {'space': {'Default': {'Desktop': desktop}}},
                'Displays': {'screen': {'Desktop': {'Content': {}}}},
            }))
            with patch.object(helper, 'PLIST_PATH', str(store)), \
                 patch.object(helper.sys, 'argv', ['wallpaper-all-spaces', str(image)]), \
                 patch.object(helper.subprocess, 'run'):
                helper.main()
            data = plistlib.loads(store.read_bytes())
            desktops = [data['SystemDefault']['Desktop'],
                        data['Spaces']['space']['Default']['Desktop'],
                        data['Displays']['screen']['Desktop']]
            for node in desktops:
                choices = node['Content']['Choices']
                self.assertEqual(choices[0]['Provider'], 'com.apple.wallpaper.choice.image')
                self.assertEqual(len(choices), 1)
                self.assertEqual(plistlib.loads(choices[0]['Configuration'])['url']['relative'],
                                 image.resolve().as_uri())
                self.assertNotIn('EncodedOptionValues', node['Content'])
            self.assertEqual(data['SystemDefault']['Idle'], idle)


if __name__ == '__main__':
    unittest.main()
