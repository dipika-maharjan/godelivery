import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_theme.dart';
import '../data/media_repository.dart';
import '../models/order.dart';

/// Thumbnails for a package's uploaded photos, resolved through the
/// presigned media download URL and opening full-screen on tap.
class PackageImagesRow extends StatelessWidget {
  const PackageImagesRow({super.key, required this.images});

  final List<MediaAsset> images;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) =>
            _PackageImageThumb(asset: images[index]),
      ),
    );
  }
}

class _PackageImageThumb extends ConsumerWidget {
  const _PackageImageThumb({required this.asset});

  final MediaAsset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(mediaDownloadUrlProvider(asset.id));
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: url.when(
        data: (value) => GestureDetector(
          onTap: () => _openFullscreen(context, value),
          child: Image.network(
            value,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _placeholder(context),
          ),
        ),
        loading: () => Container(
          width: 60,
          height: 60,
          color: context.colors.cardAlt,
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (_, _) => _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) => Container(
    width: 60,
    height: 60,
    color: context.colors.cardAlt,
    child: Icon(
      LucideIcons.imageOff,
      size: 18,
      color: context.colors.textMuted,
    ),
  );

  void _openFullscreen(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(child: InteractiveViewer(child: Image.network(url))),
        ),
      ),
    );
  }
}
