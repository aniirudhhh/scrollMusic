import json
import urllib.request

def yt_music_browse(browse_id):
    url = 'https://music.youtube.com/youtubei/v1/browse?prettyPrint=false'
    headers = {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
    }
    
    payload = {
        "context": {
            "client": {
                "clientName": "WEB_REMIX",
                "clientVersion": "1.20231214.01.00",
                "hl": "en"
            }
        },
        "browseId": browse_id
    }
    
    req = urllib.request.Request(url, data=json.dumps(payload).encode(), headers=headers)
    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
            with open('artist_songs.json', 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2)
            print("Saved artist_songs.json")
    except Exception as e:
        print("Error:", e)

yt_music_browse("VLOLAK5uy_m9NcLauVzADCRC6rfmtow_Z6a6TuIO8g8")
