import json

d = json.load(open('d:/scrollMusic/artist_browse.json'))

def find_keys(data, target, res):
    if isinstance(data, dict):
        if target in data:
            res.append(data)
        for v in data.values():
            find_keys(v, target, res)
    elif isinstance(data, list):
        for item in data:
            find_keys(item, target, res)

header = []
find_keys(d, 'musicImmersiveHeaderRenderer', header)
if header:
    print("Header title:", header[0]['musicImmersiveHeaderRenderer']['title']['runs'][0]['text'])
    print("Thumbnail:", header[0]['musicImmersiveHeaderRenderer']['thumbnail']['musicThumbnailRenderer']['thumbnail']['thumbnails'][-1]['url'])
    print("Description:", header[0]['musicImmersiveHeaderRenderer'].get('description', {}).get('runs', [{'text': ''}])[0]['text'])

songs = []
find_keys(d, 'musicResponsiveListItemRenderer', songs)
print(f"Found {len(songs)} songs/items")
if songs:
    print(songs[0])

