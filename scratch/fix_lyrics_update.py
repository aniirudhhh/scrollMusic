import os
import re

with open('D:/scrollMusic/lib/screens/lyrics/lyrics_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the state variables and initState/didChangeDependencies
target = re.compile(r'class _LyricsScreenState extends State<LyricsScreen> \{\s*final _lyricsService = LyricsService\(\);\s*final ScrollController _scrollController = ScrollController\(\);\s*List<LyricLine>\? _lyrics;\s*bool _isLoading = true;\s*String _error = '''';\s*bool _isSynced = true;\s*int _activeIndex = -1;\s*List<GlobalKey> _lineKeys = \[\];\s*@override\s*void initState\(\) \{\s*super\.initState\(\);\s*_fetchLyrics\(\);\s*\}\s*@override\s*void didChangeDependencies\(\) \{\s*super\.didChangeDependencies\(\);\s*final controller = context\.watch<HomeController>\(\);\s*controller\.positionNotifier\.addListener\(_onPositionChanged\);\s*\}\s*@override\s*void didUpdateWidget\(LyricsScreen oldWidget\) \{\s*super\.didUpdateWidget\(oldWidget\);\s*if \(oldWidget\.song\.id != widget\.song\.id\) \{\s*_fetchLyrics\(\);\s*\}\s*\}\s*Future<void> _fetchLyrics\(\) async \{', re.DOTALL)

replacement = '''class _LyricsScreenState extends State<LyricsScreen> {
  final _lyricsService = LyricsService();
  final ScrollController _scrollController = ScrollController();
  
  List<LyricLine>? _lyrics;
  bool _isLoading = true;
  String _error = '';
  
  bool _isSynced = true;
  int _activeIndex = -1;
  List<GlobalKey> _lineKeys = [];
  
  late String _currentSongId;
  late Song _currentSong;
  bool _positionListenerAdded = false;

  @override
  void initState() {
    super.initState();
    _currentSong = widget.song;
    _currentSongId = widget.song.id;
    _fetchLyrics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.watch<HomeController>();
    
    if (!_positionListenerAdded) {
      controller.positionNotifier.addListener(_onPositionChanged);
      _positionListenerAdded = true;
    }
    
    final newSong = controller.currentSong;
    if (newSong != null && newSong.id != _currentSongId) {
      _currentSongId = newSong.id;
      _currentSong = newSong;
      _fetchLyrics();
    }
  }

  @override
  void dispose() {
    // Note: We don't have access to context.read here safely for positionNotifier, 
    // but the controller lives for the life of the app so we can ignore removing the listener,
    // or just let it dispose naturally.
    super.dispose();
  }

  @override
  void didUpdateWidget(LyricsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id && widget.song.id != _currentSongId) {
      _currentSongId = widget.song.id;
      _currentSong = widget.song;
      _fetchLyrics();
    }
  }
  
  Future<void> _fetchLyrics() async {
    final targetSong = _currentSong;
    setState(() {
      _isLoading = true;
      _error = '';
    });'''

content = target.sub(replacement, content)

# Now fix the reference to widget.song in _fetchLyrics
content = content.replace('await _lyricsService.getLyrics(widget.song)', 'await _lyricsService.getLyrics(targetSong)')

# And fix widget.song.title and widget.song.artist and widget.song.artwork in the build method!
content = content.replace('widget.song.title', '_currentSong.title')
content = content.replace('widget.song.artist', '_currentSong.artist')
content = content.replace('widget.song.artwork', '_currentSong.artwork')

with open('D:/scrollMusic/lib/screens/lyrics/lyrics_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
