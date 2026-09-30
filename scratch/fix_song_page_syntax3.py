import os

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

out = []
i = 0
while i < len(lines):
    line = lines[i]
    if 'return Column(' in line and 'mainAxisSize: MainAxisSize.min,' in lines[i+1]:
        # we found it. Skip down to _ProgressBar(
        while '_ProgressBar(' not in lines[i]:
            i += 1
        # output the return _ProgressBar(
        out.append(lines[i].replace('_ProgressBar(', 'return _ProgressBar('))
        i += 1
        
        # Keep copying until ),;
        while '),;' not in lines[i]:
            out.append(lines[i])
            i += 1
            
        # output the corrected line without ,;
        out.append(lines[i].replace('),;', ');'))
        i += 1
        continue
    
    out.append(line)
    i += 1

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'w', encoding='utf-8') as f:
    f.writelines(out)
