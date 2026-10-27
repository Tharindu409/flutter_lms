import 'package:flutter/material.dart';
import 'package:flutter_lms/models/student_notification.dart';
import 'package:flutter_lms/providers/notification_provider.dart';
import 'package:flutter_lms/widgets/confirm_dialog.dart';
import 'package:flutter_lms/widgets/message_banner.dart';
import 'package:flutter_lms/widgets/section_header.dart';
import 'package:flutter_lms/widgets/state_views.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _scrollController = ScrollController();
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<NotificationProvider>();
      provider.refresh();
      provider.refreshUnreadCount();
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 240) {
      context.read<NotificationProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _delete(StudentNotification notification) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete notification',
      message: 'Are you sure you want to delete this notification?',
      confirmLabel: 'Delete',
    );
    if (!mounted || !confirmed) return;
    final error = await context.read<NotificationProvider>().deleteNotification(
      notification,
    );
    if (!mounted || error == null) return;
    _showMessage(error);
  }

  Future<void> _markRead(StudentNotification notification) async {
    final error = await context.read<NotificationProvider>().markRead(
      notification,
    );
    if (!mounted || error == null) return;
    _showMessage(error);
  }

  Future<void> _markAllRead() async {
    final error = await context.read<NotificationProvider>().markAllRead();
    if (!mounted || error == null) return;
    _showMessage(error);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) => TextButton(
              onPressed: provider.isMutating || provider.unreadCount == 0
                  ? null
                  : _markAllRead,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: const Text('Mark all read'),
            ),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SectionHeader(
                    title: 'Your updates',
                    subtitle: 'Stay up to date with your learning.',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: !provider.unreadOnly,
                      onSelected: (_) => provider.setUnreadOnly(false),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Unread'),
                      selected: provider.unreadOnly,
                      onSelected: (_) => provider.setUnreadOnly(true),
                    ),
                    const Spacer(),
                    if (provider.unreadCount != null)
                      Text('${provider.unreadCount} unread'),
                  ],
                ),
              ),
              if (provider.unreadCountError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: MessageBanner(
                          message: provider.unreadCountError!,
                          type: MessageType.info,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Retry unread count',
                        onPressed: provider.refreshUnreadCount,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
              if (provider.errorMessage != null &&
                  provider.notifications.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: MessageBanner(
                          message: provider.errorMessage!,
                          type: MessageType.error,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Retry notifications',
                        onPressed: provider.refresh,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
              Expanded(child: _buildBody(provider)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(NotificationProvider provider) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      return const LoadingView();
    }
    if (provider.errorMessage != null && provider.notifications.isEmpty) {
      return ErrorView(
        message: provider.errorMessage!,
        onRetry: provider.refresh,
      );
    }
    if (provider.notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.55,
              child: EmptyView(
                title: provider.unreadOnly
                    ? 'No unread notifications'
                    : 'No notifications yet',
                message: provider.unreadOnly
                    ? 'You are all caught up.'
                    : 'New updates will appear here.',
                icon: Icons.notifications_none_outlined,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            itemCount:
                provider.notifications.length +
                (provider.isLoadingMore || provider.loadMoreError != null
                    ? 1
                    : 0),
            itemBuilder: (context, index) {
              if (index == provider.notifications.length) {
                if (provider.loadMoreError != null) {
                  return TextButton.icon(
                    onPressed: provider.loadMore,
                    icon: const Icon(Icons.refresh),
                    label: Text('Retry: ${provider.loadMoreError}'),
                  );
                }
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final notification = provider.notifications[index];
              return _NotificationCard(
                notification: notification,
                isBusy: provider.isMutating,
                onTap: () => _markRead(notification),
                onDelete: () => _delete(notification),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.isBusy,
    required this.onTap,
    required this.onDelete,
  });

  final StudentNotification notification;
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final unread = notification.isRead == false;
    final title =
        notification.title ??
        notification.type?.replaceAll('_', ' ') ??
        'Notification';
    final message = notification.message ?? 'You have a new update.';
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      color: unread
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: .3)
          : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: isBusy || notification.isRead == true ? null : onTap,
        leading: Icon(
          unread ? Icons.mark_email_unread_outlined : Icons.notifications_none,
          color: unread ? Theme.of(context).colorScheme.primary : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleSmall),
            ),
            if (unread)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(message),
            if (notification.createdAt != null) ...[
              const SizedBox(height: 6),
              Text(
                MaterialLocalizations.of(context)
                    .formatMediumDate(notification.createdAt!.toLocal()),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        trailing: IconButton(
          tooltip: 'Delete notification',
          onPressed: isBusy ? null : onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}
