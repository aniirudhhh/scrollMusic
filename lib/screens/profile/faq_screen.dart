import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
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
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                const _FaqItem(
                  question: 'What is Scroll Music?',
                  answer: 'Scroll Music is a sleek, modern music player that lets you stream your favorite tracks, sync with YouTube Music, and enjoy an immersive edge-to-edge UI designed exclusively for you.',
                ),
                const _FaqItem(
                  question: 'How do I download songs for offline listening?',
                  answer: "Currently, downloads are a work in progress! Soon, you'll be able to tap the download icon on any song or playlist to save it directly to your device for anytime playback.",
                ),
                const _FaqItem(
                  question: 'How do I sync my YouTube Music library?',
                  answer: 'Head over to Profile Settings and tap "YouTube Music" (or "Connect Account"). Once logged in securely, your liked songs and playlists will sync with the app instantly.',
                ),
                const _FaqItem(
                  question: 'Is my data private?',
                  answer: 'Absolutely. We do not store your passwords or track your data. YouTube syncing is handled securely through official login cookies stored strictly on your local device.',
                ),
                const _FaqItem(
                  question: 'Can I change the audio quality?',
                  answer: 'The app dynamically adjusts audio quality based on your network connection to prevent buffering. Manual quality toggles and equalizer settings are brewing in the lab!',
                ),
                const _FaqItem(
                  question: 'Why does the background change colors?',
                  answer: 'Scroll Music features a dynamic background engine that extracts the dominant colors from the artwork of the currently playing track to create an immersive, fluid visual experience.',
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _iconTurns;
  late Animation<double> _heightFactor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _iconTurns = Tween<double>(begin: 0.0, end: 0.5).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));
    _heightFactor = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isExpanded ? Colors.white.withAlpha(20) : Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isExpanded ? Colors.white.withAlpha(30) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: TextStyle(
                      color: _isExpanded ? Colors.white : Colors.white.withAlpha(200),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                RotationTransition(
                  turns: _iconTurns,
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowDown01,
                    color: _isExpanded ? Colors.white : Colors.white.withAlpha(100),
                    size: 20,
                  ),
                ),
              ],
            ),
            SizeTransition(
              sizeFactor: _heightFactor,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  widget.answer,
                  style: TextStyle(
                    color: Colors.white.withAlpha(150),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
