"""Download the free source assets used by the isolated Godot quality probe."""
import concurrent.futures
import hashlib
import json
from pathlib import Path
import urllib.request

ROOT = Path(__file__).resolve().parents[2] / 'quality_probe'
HEADERS = {'User-Agent': 'StuntcarAssetPreview/1.0 (local Godot evaluation)'}

def fetch(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS), timeout=90).read()

jobs = []
car_base = 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/CarConcept/'
files = json.loads(fetch('https://api.github.com/repos/KhronosGroup/glTF-Sample-Assets/contents/Models/CarConcept/glTF'))
for f in files:
    jobs.append(('assets/car/' + f['name'], f['download_url'], None))
jobs.append(('assets/car/SOURCE.md', car_base + 'README.md', None))
jobs.append(('assets/car/CC-BY-4.0.txt', 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/LICENSES/CC-BY-4.0.txt', None))
jobs.append(('assets/car/KHRONOS-MARKS.txt', 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/LICENSES/LicenseRef-LegalMark-Khronos.txt', None))
for asset, folder in [('pine_sapling_small', 'tree'), ('asphalt_track', 'road'), ('forest_floor', 'ground'), ('kloofendal_48d_partly_cloudy', 'sky')]:
    data = json.loads(fetch('https://api.polyhaven.com/files/' + asset))
    if folder == 'tree':
        gltf = data['gltf']['1k']['gltf']
        jobs.append(('assets/tree/tree.gltf', gltf['url'], gltf['md5']))
        for path, f in gltf['include'].items():
            jobs.append(('assets/tree/' + path, f['url'], f['md5']))
    elif folder == 'sky':
        f = data['hdri']['2k']['hdr']
        jobs.append(('assets/sky/environment.hdr', f['url'], f['md5']))
    else:
        for key, name in [('Diffuse', 'color'), ('nor_gl', 'normal'), ('arm', 'arm')]:
            f = data[key]['2k']['jpg']
            jobs.append(('assets/' + folder + '/' + name + '.jpg', f['url'], f['md5']))

def download(job):
    path, url, expected = job
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    content = target.read_bytes() if target.exists() else fetch(url)
    if expected and hashlib.md5(content).hexdigest() != expected:
        raise ValueError('Checksum mismatch: ' + path)
    target.write_bytes(content)
    print(path, len(content), flush=True)
    return {'path': path, 'source': url, 'bytes': len(content), 'sha256': hashlib.sha256(content).hexdigest()}

with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
    records = list(pool.map(download, jobs))
(ROOT / 'assets' / 'manifest.json').write_text(json.dumps(records, indent=2) + '\n')
print('Downloaded', len(records), 'files:', sum(x['bytes'] for x in records), 'bytes')
