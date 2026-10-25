import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notification_provider.dart';

/// 通知中心：未读标记、点击已读、滑动删除、全部已读、下拉刷新。
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            '通知中心${state.unreadCount > 0 ? '（${state.unreadCount} 未读）' : ''}'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () => notifier.markAllAsRead(),
              child: const Text('全部已读'),
            ),
        ],
      ),
      body: state.loading && state.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.error!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      FilledButton(
                          onPressed: () => notifier.refresh(),
                          child: const Text('重试')),
                    ],
                  ),
                )
              : state.items.isEmpty
                  ? const Center(child: Text('暂无通知'))
                  : RefreshIndicator(
                      onRefresh: () => notifier.refresh(),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: state.items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final item = state.items[i];
                          return Dismissible(
                            key: ValueKey('notif-${item.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) => notifier.delete(item.id),
                            child: ListTile(
                              leading: _levelIcon(item.level),
                              title: Text(
                                item.title,
                                style: TextStyle(
                                  fontWeight: item.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.message,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text(item.createdAt,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                ],
                              ),
                              trailing: item.isRead
                                  ? null
                                  : const Badge(label: Text('新')),
                              onTap: () => notifier.markAsRead(item.id),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _levelIcon(String level) {
    final icon = switch (level) {
      'critical' => Icons.error,
      'error' => Icons.error_outline,
      'warning' => Icons.warning_amber_rounded,
      'success' => Icons.check_circle_outline,
      _ => Icons.info_outline,
    };
    final color = switch (level) {
      'critical' => Colors.red,
      'error' => Colors.redAccent,
      'warning' => Colors.orange,
      'success' => Colors.green,
      _ => Colors.blueGrey,
    };
    return Icon(icon, color: color);
  }
}
