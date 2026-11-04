import 'package:flutter/material.dart';
import 'package:flutter_lms/features/admin/core/admin_paged_provider.dart';
import 'package:flutter_lms/widgets/state_views.dart';

Widget adminPagedBody<T>({
  required AdminPagedProvider<T> provider,
  required String title,
  required Future<void> Function() onRefresh,
  required Widget Function(T item) itemBuilder,
}) {
  if (provider.isLoading && provider.items.isEmpty) {
    return const LoadingView(message: 'Loading...');
  }
  if (provider.errorMessage != null && provider.items.isEmpty) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 320,
            child: ErrorView(
              message: provider.errorMessage!,
              onRetry: onRefresh,
            ),
          ),
        ],
      ),
    );
  }
  if (provider.items.isEmpty) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [SizedBox(height: 320, child: EmptyView(title: title))],
      ),
    );
  }
  final showError = provider.errorMessage != null;
  final showFooter = provider.hasMore || provider.loadMoreError != null;
  return RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount:
          provider.items.length + (showError ? 1 : 0) + (showFooter ? 1 : 0),
      itemBuilder: (context, index) {
        if (showError && index == 0) {
          return MaterialBanner(
            content: Text(provider.errorMessage!),
            leading: const Icon(Icons.error_outline),
            actions: [
              TextButton(onPressed: onRefresh, child: const Text('Retry')),
            ],
          );
        }
        final itemIndex = index - (showError ? 1 : 0);
        if (itemIndex >= provider.items.length) {
          if (provider.loadMoreError != null) {
            return TextButton(
              onPressed: provider.loadMore,
              child: Text('${provider.loadMoreError} Tap to retry.'),
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: provider.isLoadingMore
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: provider.loadMore,
                      child: const Text('Load more'),
                    ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: itemBuilder(provider.items[itemIndex]),
        );
      },
    ),
  );
}

class AdminHeader extends StatelessWidget {
  const AdminHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.leading,
  });
  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
    child: Row(
      children: [
        ?leading,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 24,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        ?action,
      ],
    ),
  );
}

class AdminMetricCard extends StatelessWidget {
  const AdminMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.index,
  });

  final String label;
  final String value;
  final IconData icon;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedOpacity(
      opacity: 1,
      duration: Duration(milliseconds: 220 + index * 35),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 21),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 25,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget adminMoreButton(VoidCallback onPressed) => IconButton(
  onPressed: onPressed,
  icon: const Icon(Icons.more_vert),
  tooltip: 'More',
);

class AdminFilterRow extends StatelessWidget {
  const AdminFilterRow({
    super.key,
    required this.value,
    required this.values,
    required this.labels,
    required this.onChanged,
  });

  final String value;
  final List<String> values;
  final List<String> labels;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var index = 0; index < values.length; index++)
            FilterChip(
              showCheckmark: false,
              avatar: value == values[index]
                  ? const Icon(Icons.check_rounded, size: 16)
                  : null,
              label: Text(labels[index]),
              selected: value == values[index],
              onSelected: (_) => onChanged(values[index]),
            ),
        ],
      ),
    ),
  );
}

class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({super.key, required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    final color = switch (value.toUpperCase()) {
      'ACTIVE' || 'PUBLISHED' || 'COMPLETED' => const Color(0xFF2563EB),
      'SUSPENDED' || 'ARCHIVED' || 'CANCELLED' => const Color(0xFF374151),
      'INACTIVE' || 'DRAFT' => const Color(0xFF6B7280),
      _ => const Color(0xFF2563EB),
    };
    final icon = switch (value.toUpperCase()) {
      'ACTIVE' || 'PUBLISHED' || 'COMPLETED' => Icons.check_circle_outline,
      'SUSPENDED' || 'ARCHIVED' || 'CANCELLED' => Icons.block_outlined,
      'INACTIVE' || 'DRAFT' => Icons.schedule_outlined,
      _ => Icons.circle_outlined,
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

void showAdminMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
