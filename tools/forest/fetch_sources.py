"""Fetch CC0 forest sources, retaining checksums and original metadata."""
import concurrent.futures
import hashlib
import json
from pathlib import Path
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
HEADERS = {'User-Agent': 'StuntcarAssetPreview/1.0 (local Godot evaluation)'}
MODELS = ['rock_moss_set_01', 'fern_02', 'grass_medium_01']
TREES = ['pine_tree_01', 'fir_tree_01']

def fetch(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS), timeout=120)

def download(job):
    target, entry = job
    target.parent.mkdir(parents=True, exist_ok=True)
    if not target.exists():
        temporary = target.with_suffix(target.suffix + '.part')
        with fetch(entry['url']) as response, temporary.open('wb') as out:
            while block := response.read(1024 * 1024):
                out.write(block)
        temporary.replace(target)
    digest = hashlib.md5(target.read_bytes()).hexdigest()
    if digest != entry['md5']:
        raise ValueError('Checksum mismatch: ' + str(target))
    print(target.relative_to(ROOT), target.stat().st_size, flush=True)
    return {'path': str(target.relative_to(ROOT)), 'url': entry['url'],
            'bytes': target.stat().st_size, 'md5': digest}

def main():
    (ROOT / 'assets/forest').mkdir(parents=True, exist_ok=True)
    (ROOT / '.tools/forest-sources').mkdir(parents=True, exist_ok=True)
    jobs = []
    for name in MODELS + TREES + ['forest_ground_04']:
        with fetch('https://api.polyhaven.com/files/' + name) as response:
            data = json.load(response)
        with fetch('https://api.polyhaven.com/info/' + name) as response:
            info = json.load(response)
        (ROOT / 'assets/forest' / (name + '-source.json')).write_text(json.dumps(info, indent=2) + '\n')
        (ROOT / '.tools/forest-sources' / (name + '-files.json')).write_text(json.dumps(data, indent=2) + '\n')
        if name in TREES:
            entry = data['blend']['1k']['blend']
            folder = ROOT / '.tools/forest-sources' / name
            jobs.append((folder / (name + '.blend'), entry))
            for path, included in entry.get('include', {}).items():
                jobs.append((folder / path, included))
        elif name in MODELS:
            folder = ROOT / 'assets/forest' / name
            entry = data['gltf']['1k']['gltf']
            jobs.append((folder / (name + '.gltf'), entry))
            for path, included in entry['include'].items():
                jobs.append((folder / path, included))
        else:
            for key, filename in [('Diffuse', 'color'), ('nor_gl', 'normal'), ('Rough', 'rough')]:
                jobs.append((ROOT / 'assets/forest/ground' / (filename + '.jpg'), data[key]['2k']['jpg']))
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        records = list(pool.map(download, jobs))
    (ROOT / 'assets/forest/manifest.json').write_text(json.dumps(records, indent=2) + '\n')

if __name__ == '__main__':
    main()
