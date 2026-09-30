import re

with open('D:/scrollMusic/lib/screens/lyrics/lyrics_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = '''    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            const Positioned.fill(
              child: DynamicSingleColorBackground(),
            ),
            Positioned.fill(
              child: Column('''

replacement = '''    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DynamicSingleColorBackground(),
          ),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Column('''

content = content.replace(target, replacement)

# Because we opened SafeArea inside Positioned.fill, we need to close it.
# The original structure:
#         child: Stack(
#           children: [
#             const Positioned.fill(
#               child: DynamicSingleColorBackground(),
#             ),
#             Positioned.fill(
#               child: Column( ... )
#             ),
#             Positioned( bottom: 32, ... )
#           ]
#         )
#       ) <- safe area close

# Let's just do a simple replacement for the safe area close if needed, but it's easier to just rebuild that block.
