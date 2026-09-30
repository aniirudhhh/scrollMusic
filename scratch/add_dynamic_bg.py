import re

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

if "dynamic_single_color_background.dart" not in content:
    content = "import '../../widgets/dynamic_single_color_background.dart';\n" + content

# Find Scaffold
scaffold_pattern = re.compile(r"Scaffold\(\s*backgroundColor: Colors\.black,\s*// Dark background\s*appBar: AppBar\(.*?\),\s*body: ListView\(", re.DOTALL)

def replace_scaffold(match):
    original = match.group(0)
    # Reconstruct it
    new_scaffold = '''Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Profile & Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: DynamicSingleColorBackground()),
          ListView('''
    return new_scaffold

content = scaffold_pattern.sub(replace_scaffold, content)

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
