import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/health_content_model.dart';
import '../../core/constants.dart';

class HealthArticleCard extends StatelessWidget {
  final HealthContentModel content;
  final String languageCode;
  final VoidCallback? onTap;
  final VoidCallback? onBookmark;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final bool isBookmarked;
  final bool isCompact;

  const HealthArticleCard({
    super.key,
    required this.content,
    required this.languageCode,
    this.onTap,
    this.onBookmark,
    this.onLike,
    this.onShare,
    this.isBookmarked = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingSmall,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (content.hasMedia) _buildMediaSection(),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  _buildTitle(),
                  const SizedBox(height: 6),
                  _buildDescription(),
                  const SizedBox(height: 12),
                  _buildMetadata(),
                  const SizedBox(height: 12),
                  _buildActions(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    if (content.imageUrl != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        child: AspectRatio(
          aspectRatio: isCompact ? 2.5 : 16 / 9,
          child: CachedNetworkImage(
            imageUrl: content.imageUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: const Icon(
                Icons.image_not_supported,
                color: Colors.grey,
                size: 48,
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getCategoryColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            content.categoryDisplayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getCategoryColor(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          content.type.icon,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 4),
        Text(
          content.type.displayName,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const Spacer(),
        if (content.isVerified)
          const Icon(
            Icons.verified,
            size: 16,
            color: Colors.blue,
          ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      content.getLocalizedTitle(languageCode),
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
      maxLines: isCompact ? 2 : 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription() {
    if (isCompact) return const SizedBox.shrink();
    
    return Text(
      content.getLocalizedDescription(languageCode),
      style: const TextStyle(
        fontSize: 14,
        color: Colors.grey,
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMetadata() {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: Colors.grey[300],
          child: content.authorImageUrl != null
              ? CachedNetworkImage(
                  imageUrl: content.authorImageUrl!,
                  imageBuilder: (context, imageProvider) => CircleAvatar(
                    radius: 12,
                    backgroundImage: imageProvider,
                  ),
                  placeholder: (context, url) => const Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey,
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey,
                  ),
                )
              : const Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.grey,
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            content.author,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          Icons.schedule,
          size: 14,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          content.readTime,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getDifficultyColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            content.difficulty.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _getDifficultyColor(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        _buildActionButton(
          icon: Icons.visibility,
          count: content.views,
          onPressed: null,
        ),
        const SizedBox(width: 16),
        _buildActionButton(
          icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          count: null,
          onPressed: onBookmark,
          color: isBookmarked ? Colors.orange : null,
        ),
        const SizedBox(width: 16),
        _buildActionButton(
          icon: Icons.favorite_border,
          count: content.likes,
          onPressed: onLike,
        ),
        const SizedBox(width: 16),
        _buildActionButton(
          icon: Icons.share,
          count: null,
          onPressed: onShare,
        ),
        const Spacer(),
        if (content.rating > 0) ...[
          const Icon(
            Icons.star,
            size: 16,
            color: Colors.amber,
          ),
          const SizedBox(width: 4),
          Text(
            content.rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    int? count,
    VoidCallback? onPressed,
    Color? color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: color ?? Colors.grey[600],
            ),
            if (count != null) ...[
              const SizedBox(width: 4),
              Text(
                _formatCount(count),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    switch (content.category.toLowerCase()) {
      case 'diabetes':
        return Colors.purple;
      case 'hypertension':
        return Colors.red;
      case 'heart_health':
        return Colors.pink;
      case 'nutrition':
        return Colors.green;
      case 'exercise':
        return Colors.orange;
      case 'mental_health':
        return Colors.teal;
      case 'medication':
        return Colors.indigo;
      case 'prevention':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getDifficultyColor() {
    switch (content.difficulty) {
      case HealthContentDifficulty.beginner:
        return Colors.green;
      case HealthContentDifficulty.intermediate:
        return Colors.orange;
      case HealthContentDifficulty.advanced:
        return Colors.red;
    }
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '\${(count / 1000).toStringAsFixed(1)}K';
    return '\${(count / 1000000).toStringAsFixed(1)}M';
  }
}

// Compact version for horizontal lists
class CompactHealthCard extends StatelessWidget {
  final HealthContentModel content;
  final String languageCode;
  final VoidCallback? onTap;
  final bool isBookmarked;

  const CompactHealthCard({
    super.key,
    required this.content,
    required this.languageCode,
    this.onTap,
    this.isBookmarked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: AppDimensions.paddingMedium),
      child: HealthArticleCard(
        content: content,
        languageCode: languageCode,
        onTap: onTap,
        isBookmarked: isBookmarked,
        isCompact: true,
      ),
    );
  }
}
