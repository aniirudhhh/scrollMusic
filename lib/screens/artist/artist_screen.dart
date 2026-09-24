import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/artist.dart';
import '../../models/song.dart';
import '../../data/library_manager.dart';
import '../../core/utils/app_toast.dart';
import '../../data/yt_music_sync_service.dart';
import '../../screens/home/home_controller.dart';

class ArtistScreen extends StatefulWidget {
  final Artist? passedArtist;
  
  const ArtistScreen({super.key, Artist? artist}) : passedArtist = artist;

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  bool _isLoading = true;
  bool _isBioExpanded = false;
  Artist? _artist;
  String _bio = '';
  List<Song> _topSongs = [];
  
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchData();
  }

  void _onScroll() {
    if (_scrollController.offset > 50 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 50 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final searchName = widget.passedArtist?.name ?? "Olivia Beits"; // fallback for dummy testing
    
    final details = await YTMusicSyncService.fetchArtistDetails(searchName);
    
    if (details != null && mounted) {
      setState(() {
        _artist = Artist(
          id: details['id'],
          name: details['name'],
          imageUrl: details['imageUrl'],
        );
        _bio = details['bio'];
        _topSongs = details['songs'] as List<Song>;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _artist = widget.passedArtist;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F13),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF2D55))),
      );
    }

    // Use fetched artist, or passed artist, or a complete dummy
    final artist = _artist ?? widget.passedArtist ?? const Artist(
      id: "dummy_artist_1",
      name: "Olivia Beits",
      imageUrl: "https://images.unsplash.com/photo-1526478806334-5fd488fcaabc?auto=format&fit=crop&q=80&w=1000",
    );
    
    final String artistName = artist.name;
    final String artistHandle = "@${artistName.replaceAll(' ', '').toLowerCase()}";
    final String artistImage = artist.imageUrl.isNotEmpty ? artist.imageUrl : "https://images.unsplash.com/photo-1526478806334-5fd488fcaabc?auto=format&fit=crop&q=80&w=1000";
    final String artistId = artist.id;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: Stack(
        children: [
          // 1. Background Image with Gradient Fade
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.65,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: artistImage,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: Colors.white10),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Color(0xFF0F0F13),
                      ],
                      stops: [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 2. Scrollable Content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Transparent App Bar
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                flexibleSpace: AnimatedOpacity(
                  opacity: _isScrolled ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        color: const Color(0xFF0F0F13).withOpacity(0.4),
                      ),
                    ),
                  ),
                ),
                leading: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, size: 20, color: Colors.white),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const HugeIcon(icon: HugeIcons.strokeRoundedMoreVertical, size: 20, color: Colors.white),
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).size.height * 0.35),
              ),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Text(
                        artistName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        artistHandle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: Consumer<LibraryManager>(
                                builder: (context, library, _) {
                                  final isFollowed = library.isArtistFollowed(artistId);
                                  return ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isFollowed ? Colors.transparent : Colors.white,
                                      foregroundColor: isFollowed ? Colors.white : Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                        side: isFollowed ? BorderSide(color: Colors.white.withOpacity(0.3)) : BorderSide.none,
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: () {
                                      library.toggleFollowArtist(artist);
                                      AppToast.show(context, isFollowed ? 'Unfollowed' : 'Following $artistName');
                                    },
                                    child: Text(
                                      isFollowed ? 'Following' : 'Follow',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            height: 56,
                            width: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: IconButton(
                              icon: const HugeIcon(icon: HugeIcons.strokeRoundedNotification02, size: 24, color: Colors.white),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                      
                      if (_bio.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isBioExpanded = !_isBioExpanded;
                            });
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1), // Translucent background
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _bio,
                                      maxLines: _isBioExpanded ? null : 4,
                                      overflow: _isBioExpanded ? TextOverflow.visible : TextOverflow.fade,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 15,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _isBioExpanded ? 'Show less' : 'Show more',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      
                      if (_topSongs.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Songs',
                            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._topSongs.map((song) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              context.read<HomeController>().playNewQueue([song]);
                              AppToast.show(context, 'Playing ${song.title}');
                            },
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: song.artwork,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        song.artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedMoreVerticalCircle01, color: Colors.white54, size: 24),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ),
                        )),
                      ],
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
