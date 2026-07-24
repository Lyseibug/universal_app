import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/models/direct_chat_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/pdt_scaffold.dart';
import 'contact_picker_screen.dart';
import 'direct_chat_repository.dart';
import 'direct_chat_thread_screen.dart';

class DirectChatListScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const DirectChatListScreen({required this.screen, super.key});

  @override
  ConsumerState<DirectChatListScreen> createState() => _DirectChatListScreenState();
}

class _DirectChatListScreenState extends ConsumerState<DirectChatListScreen> {
  List<DirectConversationSummary> _conversations = [];
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
      final convos = await ref.read(directChatRepositoryProvider).getConversations();
      convos.sort((a, b) {
        final at = a.lastMessageAt;
        final bt = b.lastMessageAt;
        if (at == null && bt == null) return a.otherUserName.compareTo(b.otherUserName);
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
      if (mounted) setState(() { _conversations = convos; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load conversations: $e'; _loading = false; });
    }
  }

  Future<void> _openConversation(DirectConversationSummary convo) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DirectChatThreadScreen(
        screen: widget.screen,
        withUser: convo.otherUser,
        withUserName: convo.otherUserName,
      ),
    ));
    _load();
  }

  Future<void> _openContactPicker() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ContactPickerScreen(screen: widget.screen),
    ));
    _load();
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
      floatingActionButton: widget.screen.can('message')
          ? FloatingActionButton(
              onPressed: _openContactPicker,
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.add_comment, color: Colors.white),
            )
          : null,
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
    if (_conversations.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(
            child: Text(
              'No conversations yet.\nTap + to start one.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _conversations.length,
      itemBuilder: (context, i) {
        final c = _conversations[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            child: Text(
              c.otherUserName.isNotEmpty ? c.otherUserName[0].toUpperCase() : '?',
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(c.otherUserName, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: c.lastMessage != null
              ? Text(c.lastMessage!, maxLines: 1, overflow: TextOverflow.ellipsis)
              : const Text('No messages yet', style: TextStyle(color: AppTheme.textSecondary)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (c.lastMessageAt != null)
                Text(_formatTime(c.lastMessageAt!),
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              if (c.unreadCount > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${c.unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          onTap: () => _openConversation(c),
        );
      },
    );
  }
}
