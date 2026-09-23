import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../extraction/extraction_service.dart';
import '../home/home_controller.dart';
import '../main_screen.dart';

class ExploreCategory {
  final String title;
  final String query;
  final List<Color> gradientColors;
  final IconData icon;

  const ExploreCategory({
    required this.title,
    required this.query,
    required this.gradientColors,
    required this.icon,
  });
}

const List<ExploreCategory> _categories = [
  ExploreCategory(
    title: 'Top 50 India',
    query: 'Top 50 India Bollywood hit songs',
    gradientColors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    icon: Icons.trending_up_rounded,
  ),
  ExploreCategory(
    title: 'Viral Hits',
    query: 'Latest viral hits trending shorts songs',
    gradientColors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
    icon: Icons.local_fire_department_rounded,
  ),
  ExploreCategory(
    title: 'Chill / Lofi',
    query: 'Lofi chill beats bollywood lofi',
    gradientColors: [Color(0xFF1CB5E0), Color(0xFF000851)],
    icon: Icons.coffee_rounded,
  ),
  ExploreCategory(
    title: 'Workout',
    query: 'Gym workout motivation energetic songs',
    gradientColors: [Color(0xFFF7971E), Color(0xFFFFD200)],
    icon: Icons.fitness_center_rounded,
  ),
  ExploreCategory(
    title: 'Party',
    query: 'Bollywood party dance club hits',
    gradientColors: [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
    icon: Icons.celebration_rounded,
  ),
  ExploreCategory(
    title: 'Focus',
    query: 'Deep focus study instrumental music',
    gradientColors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
    icon: Icons.headphones_rounded,
  ),
  ExploreCategory(
    title: 'Devotional',
    query: 'Bhajan aarti devotional songs',
    gradientColors: [Color(0xFFf83600), Color(0xFFf9d423)],
    icon: Icons.self_improvement_rounded,
  ),
  ExploreCategory(
    title: '90s Hits',
    query: '90s bollywood classic hits udit narayan',
    gradientColors: [Color(0xFF00b09b), Color(0xFF96c93d)],
    icon: Icons.album_rounded,
  )
];

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  bool _isLoading = false;
  String? _loadingCategory;

  Future<void> _onCategoryTapped(ExploreCategory category) async {
    setState(() {
      _isLoading = true;
      _loadingCategory = category.title;
    });

    try {
      final extractor = context.read<ExtractionService>();
      final results = await extractor.search(category.query);

      if (results.isNotEmpty && mounted) {
        // Load into home controller and start playing
        await context.read<HomeController>().playNewQueue(results);
        
        // Switch to the home tab to see the feed
        mainScreenKey.currentState?.switchToTab(0);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No songs found for this category.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingCategory = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Text(
                      'Explore',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final category = _categories[index];
                        return _CategoryCard(
                          category: category,
                          onTap: () => _onCategoryTapped(category),
                        );
                      },
                      childCount: _categories.length,
                    ),
                  ),
                ),
                // Padding for floating navbar
                const SliverToBoxAdapter(
                  child: SizedBox(height: 120),
                ),
              ],
            ),
            
            // Loading Overlay
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        'Loading $_loadingCategory...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ExploreCategory category;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: category.gradientColors,
          ),
          boxShadow: [
            BoxShadow(
              color: category.gradientColors.first.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background Icon Decoration
              Positioned(
                right: -16,
                bottom: -16,
                child: Icon(
                  category.icon,
                  size: 100,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      category.icon,
                      color: Colors.white,
                      size: 28,
                    ),
                    const Spacer(),
                    Text(
                      category.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
