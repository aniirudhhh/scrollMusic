import re

with open('D:/scrollMusic/lib/screens/profile/faq_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old_sliver = '''          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: Colors.black.withAlpha(200),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 48, bottom: 16),
              title: const Text(
                'Help & FAQ',
                style: TextStyle(
                  fontFamily: 'GoogleSansFlex',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF5A32FA).withAlpha(80),
                          Colors.black,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -40,
                    top: -20,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedHelpCircle,
                      size: 200,
                      color: Colors.white.withAlpha(20),
                    ),
                  ),
                ],
              ),
            ),
          ),'''

new_sliver = '''          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 48, bottom: 16),
              title: const Text(
                'Help & FAQ',
                style: TextStyle(
                  fontFamily: 'GoogleSansFlex',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/confuse.jpg',
                    fit: BoxFit.cover,
                  ),
                  // Darken slightly so the back button is visible at the top
                  Container(
                    color: Colors.black.withAlpha(50),
                  ),
                  // Bottom fade gradient to blend with the black background
                  Positioned(
                    bottom: -1,
                    left: 0,
                    right: 0,
                    height: 120,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),'''

content = content.replace(old_sliver, new_sliver)

with open('D:/scrollMusic/lib/screens/profile/faq_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
