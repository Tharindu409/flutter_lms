import 'package:flutter/material.dart';
import 'package:flutter_lms/models/course.dart';

/// Reusable course card. [footer] can hold extra content such as a progress bar.
class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;
  final Widget? footer;

  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final grey = Colors.grey.shade600;
    final instructor = course.instructor?.fullName ?? '';
    final category = course.category?.name ?? '';

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _Thumbnail(url: course.thumbnailUrl),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (category.isNotEmpty) ...[
                    Text(
                      category,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium,
                  ),
                  if (course.shortDescription.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      course.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(color: grey),
                    ),
                  ],
                  if (instructor.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 16, color: grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            instructor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(color: grey),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (course.levelLabel.isNotEmpty)
                        _Pill(label: course.levelLabel),
                      if (course.reviewCount > 0)
                        _Pill(
                          icon: Icons.star_rounded,
                          label:
                              '${course.averageRating.toStringAsFixed(1)} (${course.reviewCount})',
                        ),
                      _Pill(
                        label: course.isFree ? 'Free' : course.price.toString(),
                      ),
                    ],
                  ),
                  if (footer != null) ...[const SizedBox(height: 12), footer!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String? url;

  const _Thumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      color: scheme.primaryContainer,
      child: Icon(Icons.menu_book_rounded, size: 48, color: scheme.primary),
    );

    final imageUrl = url;
    if (imageUrl == null) return placeholder;

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : placeholder,
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _Pill({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.amber.shade700),
            const SizedBox(width: 4),
          ],
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
