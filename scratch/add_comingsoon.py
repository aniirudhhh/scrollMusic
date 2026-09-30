import re

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add the dialog method right before Widget _buildTile
dialog_method = '''  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1B1B1F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/comingsoon.png', height: 140, fit: BoxFit.contain),
                const SizedBox(height: 24),
                const Text(
                  'Coming Soon',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'The developer is currently busy crafting this feature. Stay tuned!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTile'''

content = content.replace("  Widget _buildTile", dialog_method)

# 2. Update the empty onTap methods
content = content.replace("onTap: () {}", "onTap: () => _showComingSoonDialog(context)")

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
