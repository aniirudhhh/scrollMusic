import re

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the entire build method
build_pattern = re.compile(r'  @override\n  Widget build\(BuildContext context\) \{.*', re.DOTALL)

new_build = '''  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fallback background
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
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              physics: const BouncingScrollPhysics(),
              children: [
                // Profile section
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white.withAlpha(25),
                        backgroundImage: _avatarUrl != null ? CachedNetworkImageProvider(_avatarUrl!) : null,
                        child: _avatarUrl == null
                            ? const HugeIcon(icon: HugeIcons.strokeRoundedUserCircle, color: Colors.white, size: 50)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _accountName ?? (_isLoggedIn ? 'YouTube Music User' : 'Guest'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // YouTube Music Sync Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const HugeIcon(icon: HugeIcons.strokeRoundedYoutube, color: Color(0xFFFF2D55), size: 24),
                        title: Text(
                          _isLoggedIn ? 'YouTube Music' : 'Connect Account',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          _isLoggedIn ? 'Library is synced' : 'Sync playlists and liked songs',
                          style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 13),
                        ),
                        trailing: _isSyncing 
                            ? const SizedBox(
                                width: 20, height: 20, 
                                child: CircularProgressIndicator(color: Color(0xFFFF2D55), strokeWidth: 2)
                              )
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isLoggedIn ? Colors.white.withAlpha(25) : const Color(0xFFFF2D55),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                  minimumSize: const Size(0, 32),
                                ),
                                onPressed: _handleSync,
                                child: Text(_isLoggedIn ? 'Sync Now' : 'Connect'),
                              ),
                      ),
                      if (_isLoggedIn) ...[
                        Divider(height: 1, color: Colors.white.withAlpha(25), indent: 56),
                        _buildTile(
                          'Disconnect Account', 
                          HugeIcons.strokeRoundedLogout01, 
                          color: Colors.redAccent, 
                          onTap: _handleDisconnect,
                          trailing: const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
                
                _buildSectionHeader('PERSONALIZE'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildTile('Audio Quality', HugeIcons.strokeRoundedMusicNote01, onTap: () {}),
                      Divider(height: 1, color: Colors.white.withAlpha(25), indent: 52),
                      _buildTile('Playback Settings', HugeIcons.strokeRoundedSettings01, onTap: () {}),
                      Divider(height: 1, color: Colors.white.withAlpha(25), indent: 52),
                      _buildTile('Downloads', HugeIcons.strokeRoundedDownload04, onTap: () {}),
                    ],
                  ),
                ),

                _buildSectionHeader('NEED HELP?'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildTile('Tips and Tricks', HugeIcons.strokeRoundedIdea01, onTap: () {}),
                      Divider(height: 1, color: Colors.white.withAlpha(25), indent: 52),
                      _buildTile('Frequently Asked Questions', HugeIcons.strokeRoundedHelpCircle, onTap: () {}),
                      Divider(height: 1, color: Colors.white.withAlpha(25), indent: 52),
                      _buildTile('Contact Us', HugeIcons.strokeRoundedMail01, onTap: () {}),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
'''

content = build_pattern.sub(new_build, content)

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
