import codecs

filename = 'D:/scrollMusic/lib/screens/search/search_screen.dart'
with open(filename, 'r', encoding='utf-8', errors='ignore') as f:
    text = f.read()

# Remove the BOM character explicitly
text = text.replace('\ufeff', '')
text = text.replace('\uFEFF', '')

with open(filename, 'w', encoding='utf-8') as f:
    f.write(text)