"""Install the pinned Windows Godot toolchain inside the checkout.

Uses official release downloads and Godot's documented self-contained mode:
https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html#self-contained-mode
"""
import json
from pathlib import Path
import shutil
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]

def install():
    config = json.loads((ROOT / 'tools/toolchain.json').read_text(encoding='utf-8'))
    version = config['godot_version']
    cache = ROOT / '.tools'
    engine = cache / 'godot'
    engine.mkdir(parents=True, exist_ok=True)
    (engine / '_sc_').touch()
    (engine / '.gdignore').touch()
    base = f'https://github.com/godotengine/godot/releases/download/{version}-stable/'

    def unpack(asset, destination, names):
        destination.mkdir(parents=True, exist_ok=True)
        if all((destination / name).is_file() for name in names):
            return
        archive = cache / asset
        if not archive.exists():
            print('Downloading ' + asset, flush=True)
            pending = archive.with_suffix('.download')
            with urllib.request.urlopen(base + asset, timeout=60) as source, pending.open('wb') as output:
                shutil.copyfileobj(source, output)
            pending.replace(archive)
        with zipfile.ZipFile(archive) as source:
            for name in names:
                matches = [member for member in source.namelist() if Path(member).name == name]
                if len(matches) != 1:
                    raise RuntimeError(f'{asset}: missing or ambiguous {name}')
                with source.open(matches[0]) as data, (destination / name).open('wb') as output:
                    shutil.copyfileobj(data, output)

    console = f'Godot_v{version}-stable_win64_console.exe'
    unpack(f'Godot_v{version}-stable_win64.exe.zip', engine,
           [f'Godot_v{version}-stable_win64.exe', console])
    unpack(f'Godot_v{version}-stable_export_templates.tpz',
           engine / 'editor_data/export_templates' / f'{version}.stable',
           ['windows_debug_x86_64.exe', 'windows_release_x86_64.exe',
            'windows_debug_x86_64_console.exe', 'windows_release_x86_64_console.exe', 'version.txt'])
    (ROOT / 'tools/toolchain.local.json').write_text(json.dumps({
        'godot': f'.tools/godot/{console}'}, indent=2) + '\n', encoding='utf-8')
    print(f'TOOLCHAIN ok Godot {version} with Windows export templates', flush=True)

if __name__ == '__main__':
    install()
