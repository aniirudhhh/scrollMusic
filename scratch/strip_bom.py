import codecs

filename = 'D:/scrollMusic/lib/screens/search/search_screen.dart'
with open(filename, 'rb') as f:
    content = f.read()

# Remove UTF-8 BOM if present
if content.startswith(codecs.BOM_UTF8):
    content = content[len(codecs.BOM_UTF8):]

with open(filename, 'wb') as f:
    f.write(content)
