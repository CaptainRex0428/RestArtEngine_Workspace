"""Read-only checks for this series' local Markdown and final image assets.

Requires Python 3 and Pillow. File checks do not replace visual/privacy review.
"""
import argparse
import json
import re
import sys
from pathlib import Path
from urllib.parse import unquote

from PIL import Image

GIF_LIMIT = 5_000_000  # Decimal MB, deliberately not PowerShell's binary 5MB.
FORMATS = {'.png': 'PNG', '.gif': 'GIF', '.jpg': 'JPEG', '.jpeg': 'JPEG'}


def check_article(article):
    article = article.resolve()
    errors, warnings, records = [], [], []
    name = re.match(r'^(\d{4}-\d{2}-\d{2})_第(\d{2})期_.+\.md$', article.name)
    if not name:
        raise ValueError('Use YYYY-MM-DD_第NN期_短标题.md for the article filename.')
    assets = article.parent / f'{name[1]}_第{name[2]}期_assets'
    if not assets.is_dir():
        errors.append(f'Missing assets directory: {assets.name}')
    source = article.read_text(encoding='utf-8-sig')
    # The series uses inline Markdown images, not HTML or reference-style embeds.
    source = re.sub(r'^(`{3,}|~{3,})[^\n]*\n.*?^\1\s*$', '', source, flags=re.M | re.S)
    embeds = re.findall(r'!\[([^\]]*)\]\((<[^>]+>|[^\n)]+)\)', source)
    if not embeds:
        errors.append('No inline media references found.')
    if re.search(r'<(?:img|video)\b|!\[[^\]]*\]\[', source, re.I):
        errors.append('Use inline Markdown image links so every publication asset can be checked.')
    referenced = set()
    for caption, target in embeds:
        target = target.strip()
        if target.startswith('<'):
            target = target[1:-1]
        else:
            target = re.sub(r'\s+[\"\'][^\"\']*[\"\']$', '', target)
        target = unquote(target)
        if re.match(r'^[a-zA-Z][a-zA-Z0-9+.-]*:', target) or target.startswith(('/', '\\')):
            errors.append(f'Image must use a relative local path: {target}')
            continue
        path = (article.parent / target).resolve()
        allowed_cover = path in {article.parent / 'head.png', article.parent / 'title.png'}
        if not path.is_relative_to(assets.resolve()) and not allowed_cover:
            errors.append(f'Image is outside the issue assets directory: {target}')
            continue
        if not caption.strip():
            errors.append(f'Caption/alt text is empty: {target}')
        if not path.is_file():
            errors.append(f'Missing image: {target}')
        referenced.add(path)
    candidates = referenced | {p.resolve() for p in assets.rglob('*') if p.is_file() and p.suffix.lower() in FORMATS}
    for path in sorted(candidates):
        if not path.is_file():
            continue
        relative = path.relative_to(article.parent).as_posix()
        record = {'file': relative, 'bytes': path.stat().st_size, 'referenced': path in referenced}
        if path.suffix.lower() not in FORMATS:
            errors.append(f'Unsupported final media format: {relative}')
            continue
        if path.suffix.lower() == '.gif' and record['bytes'] > GIF_LIMIT:
            errors.append(f'GIF exceeds {GIF_LIMIT} bytes: {relative} ({record["bytes"]})')
        try:
            with Image.open(path) as img:
                if img.format != FORMATS[path.suffix.lower()]:
                    errors.append(f'File extension does not match image format: {relative}')
                img.verify()
            with Image.open(path) as img:
                record.update(width=img.width, height=img.height, frames=getattr(img, 'n_frames', 1))
                duration = 0
                for frame in range(record['frames']):
                    img.seek(frame)
                    img.load()
                    duration += img.info.get('duration', 0)
                record['duration_ms'] = duration
                if img.format == 'GIF':
                    if record['frames'] < 2 or duration <= 0:
                        errors.append(f'GIF has no timed animation: {relative}')
                    if img.info.get('loop') != 0:
                        warnings.append(f'Check GIF looping manually: {relative}')
        except (OSError, ValueError, SyntaxError) as exc:
            errors.append(f'Cannot decode image {relative}: {exc}')
        if path not in referenced:
            warnings.append(f'Unreferenced asset (not an article illustration yet): {relative}')
        records.append(record)
    return {'passed_file_checks': not errors, 'gif_limit_bytes': GIF_LIMIT,
            'manual_review_required': ['caption and placement', 'readability', 'all-frame privacy', 'loop playback and truthful timing'],
            'media': records, 'errors': errors, 'warnings': warnings}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--article', required=True, type=Path)
    parser.add_argument('--report', type=Path, help='Optional JSON report, outside tracked article assets.')
    args = parser.parse_args()
    if args.report and (args.report.suffix.lower() != '.json' or args.report.resolve() == args.article.resolve()):
        parser.error('--report must be a separate .json file; never overwrite an article or image.')
    try:
        report = check_article(args.article)
    except (OSError, ValueError) as exc:
        report = {'passed_file_checks': False, 'errors': [str(exc)]}
    encoded = json.dumps(report, ensure_ascii=False, indent=2)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(encoded + '\n', encoding='utf-8')
    sys.stdout.reconfigure(encoding='utf-8')
    print(encoded)
    return 0 if report['passed_file_checks'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
