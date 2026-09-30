with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Instead of re.sub, just find the index of "  @override\n  Widget build(BuildContext context) {"
split_text = "  @override\n  Widget build(BuildContext context) {"
parts = content.split(split_text)

if len(parts) == 2:
    new_build = '''  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fallback background
      body: Stack(
        children: [
          const Positioned.fill(child: DynamicSingleColorBackground()),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: Colors.black.withAlpha(50),
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    _accountName ?? (_isLoggedIn ? 'YouTube Music User' : 'Profile & Settings'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                    ),
                  ),
                  titlePadding: const EdgeInsets.only(left: 48, bottom: 16, right: 16),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_avatarUrl != null)
                        CachedNetworkImage(
                          imageUrl: _avatarUrl!.replaceAll(RegExp(r'=s\\d+-c'), '=s600-c'), // upscale yt avatar
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Center(
                            child: HugeIcon(icon: HugeIcons.strokeRoundedUserCircle, color: Colors.white54, size: 80),
                          ),
                        )
                      else
                        Container(
                          color: Colors.white.withAlpha(12),
                          child: const Center(
                            child: HugeIcon(icon: HugeIcons.strokeRoundedUserCircle, color: Colors.white54, size: 100),
                          ),
                        ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withAlpha(76),
                              Colors.transparent,
                              Colors.black.withAlpha(178),
                              Colors.black,
                            ],
                            stops: const [0.0, 0.4, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // YouTube Music Sync Section
                    Material(
                      color: Colors.white.withAlpha(12),
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
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
                    Material(
                      color: Colors.white.withAlpha(12),
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
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
                    Material(
                      color: Colors.white.withAlpha(12),
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
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
                    
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
'''
    with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'w', encoding='utf-8') as f:
        f.write(parts[0] + new_build)
