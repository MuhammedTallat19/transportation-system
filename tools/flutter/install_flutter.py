import json
import pathlib
import urllib.request
import zipfile

root = pathlib.Path(r'E:\Transportation project\gstms-transportation-system\transport-management-system\tools\flutter')
root.mkdir(parents=True, exist_ok=True)

manifest_url = 'https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json'
with urllib.request.urlopen(manifest_url, timeout=60) as r:
    data = json.load(r)

stable = next(rel for rel in data['releases'] if rel.get('channel') == 'stable' and 'windows' in rel.get('archive', ''))
archive_name = stable['archive']
archive_url = f'https://storage.googleapis.com/flutter_infra_release/releases/{archive_name}'
archive_path = root / 'flutter_sdk_download.zip'

print('Downloading', archive_url)
urllib.request.urlretrieve(archive_url, archive_path)
print('Downloaded to', archive_path)

print('Extracting archive...')
with zipfile.ZipFile(archive_path, 'r') as z:
    z.extractall(root)
print('Extraction done')

archive_path.unlink()
print('Removed archive')
print('Extracted folders:', [p.name for p in root.iterdir() if p.is_dir()])
