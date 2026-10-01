import urllib.request
import json
import sys

def test_browse_id(browse_id):
    url = "https://music.youtube.com/youtubei/v1/browse"
    
    # We spoof the Android YT Music app since Samples is mobile-only
    payload = {
        "context": {
            "client": {
                "clientName": "ANDROID_MUSIC",
                "clientVersion": "6.02.53", 
                "androidSdkVersion": 33,
                "osName": "Android",
                "osVersion": "13",
                "hl": "en",
                "gl": "US"
            }
        },
        "browseId": browse_id
    }
    
    headers = {
        "Content-Type": "application/json",
        "User-Agent": "com.google.android.apps.youtube.music/6.02.53 (Linux; U; Android 13; en_US) gzip",
        "X-Goog-Api-Format-Version": "1"
    }
    
    req = urllib.request.Request(url, data=json.dumps(payload).encode('utf-8'), headers=headers, method='POST')
    
    try:
        with urllib.request.urlopen(req, timeout=15) as response:
            data = json.loads(response.read().decode('utf-8'))
            print(f"[{browse_id}] Success! Response keys: {list(data.keys())}")
            
            # Try to see what kind of content is inside
            if 'contents' in data:
                print(f"  -> Has contents.")
                # We can dump a tiny snippet to see if it looks like shorts
                dump = json.dumps(data['contents'])[:200]
                print(f"  -> Snippet: {dump}")
                return data
            else:
                print(f"  -> No 'contents' found.")
                return None
    except urllib.error.HTTPError as e:
        print(f"[{browse_id}] HTTP Error {e.code}")
    except Exception as e:
        print(f"[{browse_id}] Error: {e}")

def run_tests():
    candidates = [
        "FEmusic_samples",
        "FEmusic_shorts",
        "FEmusic_immersive",
        "FEmusic_explore_samples",
        "FEmusic_bottom_tab_samples",
        "FEmusic_sample"
    ]
    
    for c in candidates:
        test_browse_id(c)

if __name__ == "__main__":
    run_tests()
