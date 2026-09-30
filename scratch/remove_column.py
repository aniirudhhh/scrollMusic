import os

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
skip = False
i = 0
while i < len(lines):
    line = lines[i]
    if 'return Column(' in line and 'mainAxisSize: MainAxisSize.min,' in lines[i+1]:
        # Check if the next few lines contain Center(child: IconButton(
        if 'Center(' in lines[i+3] and 'IconButton(' in lines[i+4]:
            # This is the bad block!
            # We want to skip everything until we hit _ProgressBar(
            while i < len(lines) and '_ProgressBar(' not in lines[i]:
                i += 1
            # Now lines[i] is _ProgressBar(. We want to prepend eturn 
            new_lines.append(lines[i].replace('_ProgressBar(', 'return _ProgressBar('))
            
            # Continue appending until we hit the matching closing bracket for Column
            # Actually, _ProgressBar has ); at the end, and then the Column has ], and );.
            # Let's just manually process the rest of _ProgressBar.
            i += 1
            while i < len(lines):
                new_lines.append(lines[i])
                if lines[i].strip() == ');':
                    # End of ProgressBar
                    break
                i += 1
            
            # Now skip the ], and ); of the Column
            i += 1
            while i < len(lines) and (lines[i].strip() == '],' or lines[i].strip() == ');'):
                i += 1
            continue

    new_lines.append(line)
    i += 1

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
