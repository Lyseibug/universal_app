import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/models/group_chat_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/pdt_scaffold.dart';
import 'group_chat_repository.dart';
import 'group_chat_thread_screen.dart';

class GroupChatListScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const GroupChatListScreen({required this.screen, super.key});

  @override
  ConsumerState<GroupChatListScreen> createState() => _GroupChatListScreenState();
}

class _GroupChatListScreenState extends ConsumerState<GroupChatListScreen> {
  List<ChatGroupSummary> _groups = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final groups = await ref.read(groupChatRepositoryProvider).getMyGroups();
      groups.sort((a, b) {
        final at = a.lastMessageAt;
        final bt = b.lastMessageAt;
        if (at == null && bt == null) return a.groupName.compareTo(b.groupName);
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
      if (mounted) setState(() { _groups = groups; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load groups: $e'; _loading = false; });
    }
  }

  Future<void> _openGroup(ChatGroupSummary group) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GroupChatThreadScreen(
        screen: widget.screen,
        groupId: group.name,
        groupName: group.groupName,
      ),
    ));
    _load(); // refresh unread counts / last message after returning
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return PdtScaffold(
      title: widget.screen.label,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(child: Icon(Icons.error_outline, size: 48, color: AppTheme.danger)),
          const SizedBox(height: 12),
          Center(child: Text(_error!, textAlign: TextAlign.center)),
        ],
      );
    }
    if (_groups.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(
            child: Text(
              "You're not in any groups yet.\nAsk your supervisor to add you.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _groups.length,
      itemBuilder: (context, i) {
        final g = _groups[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            child: const Icon(Icons.groups, color: AppTheme.primary),
          ),
          title: Text(g.groupName, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: g.lastMessage != null
              ? Text(g.lastMessage!, maxLines: 1, overflow: TextOverflow.ellipsis)
              : const Text('No messages yet', style: TextStyle(color: AppTheme.textSecondary)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (g.lastMessageAt != null)
                Text(_formatTime(g.lastMessageAt!),
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              if (g.unreadCount > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${g.unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          onTap: () => _openGroup(g),
        );
      },
    );
  }
}
