import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database.dart';
import '../providers/feed_provider.dart';
import '../services/platform_service.dart';
import '../services/thumbnail_service.dart';
import '../widgets/month_header.dart';
import '../widgets/photo_fullscreen.dart';
import '../widgets/photo_grid_tile.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
  late ThumbnailService _thumbnailService;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _thumbnailService = ThumbnailService();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final feedProvider = context.read<FeedProvider>();
    if (feedProvider.photos.isEmpty) {
      await feedProvider.initialize();
    }
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      context.read<FeedProvider>().loadMore();
    }
  }

  void _openFullscreen(FeedProvider feedProvider, Photo photo) {
    final allPhotos = feedProvider.photos;
    final globalIndex = allPhotos.indexWhere((p) => p.path == photo.path);
    if (globalIndex < 0) return;

    final platformService = context.read<PlatformService>();
    PhotoFullscreen.show(
      context: context,
      photos: allPhotos,
      initialIndex: globalIndex,
      platformService: platformService,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<FeedProvider>();
    final photoCount = feedProvider.photos.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          photoCount > 0 ? 'PhotoFeed ($photoCount photos)' : 'PhotoFeed',
        ),
        actions: [
          IconButton(
            icon: Icon(
              feedProvider.newestFirst
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
            ),
            tooltip: feedProvider.newestFirst
                ? 'Showing newest first'
                : 'Showing oldest first',
            onPressed: () => feedProvider.toggleSortOrder(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Re-scan folders',
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed('/folders'),
          ),
        ],
      ),
      body: _buildBody(feedProvider),
    );
  }

  Widget _buildBody(FeedProvider feedProvider) {
    if (!_initialized || (feedProvider.isLoading && feedProvider.photos.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }

    if (feedProvider.photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No photos found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Try scanning different folders.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed('/folders'),
              icon: const Icon(Icons.folder_open),
              label: const Text('Select Folders'),
            ),
          ],
        ),
      );
    }

    final grouped = feedProvider.photosByYearMonth;
    final yearMonths = feedProvider.yearMonths
        .where((ym) => grouped.containsKey(ym))
        .toList();

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        for (final yearMonth in yearMonths) ...[
          SliverToBoxAdapter(
            child: MonthHeader(yearMonth: yearMonth),
          ),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final photos = grouped[yearMonth]!;
                final photo = photos[index];
                final thumbBytes = _thumbnailService.getThumbnail(
                  photoPath: photo.path,
                  thumbnailPath: photo.thumbnailPath,
                );
                return PhotoGridTile(
                  photo: photo,
                  thumbnailBytes: thumbBytes,
                  onTap: () => _openFullscreen(feedProvider, photo),
                );
              },
              childCount: grouped[yearMonth]!.length,
            ),
          ),
        ],
        if (feedProvider.isLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
