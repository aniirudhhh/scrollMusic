import os
import re

with open('D:/scrollMusic/lib/screens/lyrics/lyrics_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target_str = '''class _LyricsScreenState extends State<LyricsScreen> {
  final _lyricsService = LyricsService();
  final ScrollController _scrollController = ScrollController();
  
  List<LyricLine>? _lyrics;
  bool _isLoading = true;
  String _error = '';
  
  bool _isSynced = true;
  int _activeIndex = -1;
  List<GlobalKey> _lineKeys = [];

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.watch<HomeController>();
    controller.positionNotifier.addListener(_onPositionChanged);
  }

  @override
  void didUpdateWidget(LyricsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) {
      _fetchLyrics();
    }
  }
  
  Future<void> _fetchLyrics() async {'''

replacement_str = '''class _LyricsScreenState extends State<LyricsScreen> {
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
    final targetSong = _currentSong;'''

if target_str in content:
    content = content.replace(target_str, replacement_str)
else:
    print("Target string not found!")

# Now fix the reference to widget.song in _fetchLyrics
content = content.replace('await _lyricsService.getLyrics(widget.song)', 'await _lyricsService.getLyrics(targetSong)')

# And fix widget.song.title and widget.song.artist and widget.song.artwork in the build method!
content = content.replace('widget.song.title', '_currentSong.title')
content = content.replace('widget.song.artist', '_currentSong.artist')
content = content.replace('widget.song.artwork', '_currentSong.artwork')

with open('D:/scrollMusic/lib/screens/lyrics/lyrics_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
