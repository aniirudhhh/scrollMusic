import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/search_models.dart';
import '../../data/search_repository.dart';
import '../../data/download_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum SearchScreenState { idle, loading, results, error, empty }

class SearchScreenController extends ChangeNotifier {
  final SearchRepository repository;
  final DownloadManager downloadManager;

  SearchScreenState state = SearchScreenState.idle;
  bool isEditing = true;
  String currentQuery = '';
  SearchFilter? selectedFilter;

  List<String> suggestions = [];
  final List<String> history = [];
  Timer? _debounceTimer;

  SearchPage? currentPage;
  bool isPaginating = false;
  
  int _searchGeneration = 0;
  int _suggestionGeneration = 0;
  
  bool isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final Connectivity _connectivity = Connectivity();

  SearchScreenController({required this.repository, required this.downloadManager}) {
    suggestions = List.from(history);
    
    _connectivity.checkConnectivity().then((result) {
      isOffline = result.contains(ConnectivityResult.none);
      notifyListeners();
    });
    
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      isOffline = result.contains(ConnectivityResult.none);
      notifyListeners();
    });
  }

  void onQueryChanged(String query) {
    if (!isEditing) {
      isEditing = true;
      state = SearchScreenState.idle;
      notifyListeners();
    }

    if (query.trim().isEmpty) {
      suggestions = List.from(history);
      notifyListeners();
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final generation = ++_suggestionGeneration;
      
      if (isOffline) {
        final lowerQuery = query.toLowerCase();
        final matching = downloadManager.downloadedSongs
            .where((d) => d.song.title.toLowerCase().contains(lowerQuery) || 
                          d.song.artist.toLowerCase().contains(lowerQuery))
            .map((d) => d.song.title)
            .take(5)
            .toList();
        if (isEditing && generation == _suggestionGeneration) {
          suggestions = matching;
          notifyListeners();
        }
        return;
      }
      
      try {
        final results = await repository.suggestions(query);
        if (isEditing && generation == _suggestionGeneration) {
          suggestions = results;
          notifyListeners();
        }
      } catch (e) {
        // ignore suggestion failures
      }
    });
  }

  Future<void> submitSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    currentQuery = q;
    isEditing = false;
    state = SearchScreenState.loading;

    history.remove(q);
    history.insert(0, q);
    if (history.length > 20) history.removeLast();

    final generation = ++_searchGeneration;

    notifyListeners();

    try {
      if (isOffline) {
        final lowerQuery = q.toLowerCase();
        final matchingSongs = downloadManager.downloadedSongs
            .where((d) => d.song.title.toLowerCase().contains(lowerQuery) || 
                          d.song.artist.toLowerCase().contains(lowerQuery))
            .map((d) => SongItem(
                  id: d.song.id,
                  title: d.song.title,
                  thumbnailUrl: d.song.artwork,
                  artist: d.song.artist,
                  duration: null,
                ))
            .toList();
        currentPage = SearchPage(items: matchingSongs, topResult: null, continuation: null);
      } else {
        currentPage = await repository.search(q, filter: selectedFilter);
      }
      
      if (generation == _searchGeneration) {
        state = currentPage!.items.isEmpty
            ? SearchScreenState.empty
            : SearchScreenState.results;
        notifyListeners();
      }
    } catch (e) {
      if (generation == _searchGeneration) {
        state = SearchScreenState.error;
        notifyListeners();
      }
    }
  }

  Future<void> setFilter(SearchFilter? filter) async {
    selectedFilter = filter;
    if (!isEditing && currentQuery.isNotEmpty) {
      await submitSearch(currentQuery);
    } else {
      notifyListeners();
    }
  }

  void setEditing(bool editing) {
    isEditing = editing;
    if (editing && currentQuery.isEmpty) {
      suggestions = List.from(history);
    }
    notifyListeners();
  }

  Future<void> loadNextPage() async {
    if (isPaginating ||
        state != SearchScreenState.results ||
        currentPage?.continuation == null)
      return;

    isPaginating = true;
    notifyListeners();

    final generation = _searchGeneration;

    try {
      final nextPage = await repository.search(
        currentQuery,
        filter: selectedFilter,
        continuation: currentPage!.continuation,
      );

      if (generation != _searchGeneration) return;

      // Dedupe by id
      final existingIds = currentPage!.items.map((e) => e.id).toSet();
      final newItems = nextPage.items
          .where((e) => !existingIds.contains(e.id))
          .toList();

      currentPage = SearchPage(
        items: [...currentPage!.items, ...newItems],
        topResult: currentPage!.topResult,
        continuation: nextPage.continuation,
      );
    } catch (e) {
      // Leave currentPage unchanged when request fails
    } finally {
      if (generation == _searchGeneration) {
        isPaginating = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
