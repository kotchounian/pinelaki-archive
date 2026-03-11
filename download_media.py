import os, re, json, urllib.request

pages_dir = r'C:\Users\User\Documents\Antigravity\pinelaki-content-backup\pages'
media_dir = r'C:\Users\User\Documents\Antigravity\pinelaki-content-backup\media'
map_file  = r'C:\Users\User\Documents\Antigravity\pinelaki-content-backup\media-map.json'

os.makedirs(media_dir, exist_ok=True)

wp_pat = re.compile(r'https?://(?:www\.)?pinelaki\.com/wp-content/uploads/[^\s)\]"\']+')

media_map = {}
all_images = {}  # url -> local_abs

md_files = [f for f in os.listdir(pages_dir) if f.endswith('.md')]
print(f'Processing {len(md_files)} pages...')

for fname in sorted(md_files):
    fpath = os.path.join(pages_dir, fname)
    with open(fpath, 'r', encoding='utf-8', errors='replace') as f:
        content = f.read()

    page_url = ''
    m = re.search(r'^url: (.+)', content, re.MULTILINE)
    if m:
        page_url = m.group(1).strip()

    urls = set()
    for m in wp_pat.finditer(content):
        u = m.group(0).rstrip(')]\'"., ')
        urls.add(u)

    page_images = []
    for u in sorted(urls):
        try:
            # Extract path after /wp-content/uploads/
            part = u.split('/wp-content/uploads/', 1)[1]
            part = re.sub(r'[\\:*?<>|]', '_', part)
            local_rel = 'media/wp-content/uploads/' + part
            local_abs = os.path.join(media_dir, 'wp-content', 'uploads', *part.split('/'))
            page_images.append({'url': u, 'localPath': local_rel})
            if u not in all_images:
                all_images[u] = local_abs
        except Exception as e:
            print(f'  SKIP bad URL: {u} ({e})')

    if page_images and page_url:
        media_map[page_url] = page_images

print(f'Found {len(all_images)} unique images')

# Download each image
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
    'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
    'Referer': 'https://pinelaki.com/',
}

ok = 0
fail = 0
for i, (url, local_abs) in enumerate(sorted(all_images.items()), 1):
    fname = url.split('/')[-1]
    os.makedirs(os.path.dirname(local_abs), exist_ok=True)
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = resp.read()
        with open(local_abs, 'wb') as f:
            f.write(data)
        ok += 1
        print(f'  [{i}/{len(all_images)}] OK  {fname}')
    except Exception as e:
        fail += 1
        print(f'  [{i}/{len(all_images)}] ERR {fname} -- {e}')

# Save media-map.json
with open(map_file, 'w', encoding='utf-8') as f:
    json.dump(media_map, f, ensure_ascii=False, indent=2)

print(f'\n=== Done ===')
print(f'Pages processed  : {len(md_files)}')
print(f'Unique images    : {len(all_images)}')
print(f'Downloaded OK    : {ok}')
print(f'Failed           : {fail}')
print(f'Media map saved  : {map_file}')
