import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/models/group_chat_models.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/service_providers.dart';
import '../../providers/socket_provider.dart';
import '../../widgets/pdt_scaffold.dart';
import 'group_chat_repository.dart';

class GroupChatThreadScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  final String groupId;
  final String groupName;

  const GroupChatThreadScreen({
    required this.screen,
    required this.groupId,
    required this.groupName,
    super.key,
  });

  @override
  ConsumerState<GroupChatThreadScreen> createState() => _GroupChatThreadScreenState();
}

class _GroupChatThreadScreenState extends ConsumerState<GroupChatThreadScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatGroupMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _myEmail;
  StreamSubscription<Map<String, dynamic>>? _sub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _myEmail = await ref.read(sessionRepositoryProvider).getUsername();
    await _load();
    ref.read(groupChatRepositoryProvider).markGroupRead(widget.groupId);
    _sub = ref.read(groupMessageStreamProvider).listen(_onLiveMessage);
  }

  Future<void> _load() async {
    try {
      final msgs = await ref.read(groupChatRepositoryProvider).getGroupMessages(widget.groupId);
      if (mounted) {
        setState(() { _messages = msgs; _loading = false; });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onLiveMessage(Map<String, dynamic> data) {
    if (data['group']?.toString() != widget.groupId) return;
    final msg = ChatGroupMessage.fromJson(data);
    if (!mounted) return;
    setState(() => _messages = [..._messages, msg]);
    _scrollToBottom();
    ref.read(groupChatRepositoryProvider).markGroupRead(widget.groupId);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final sent = await ref.read(groupChatRepositoryProvider).sendGroupMessage(widget.groupId, text);
      _messageCtrl.clear();
      setState(() => _messages = [..._messages, sent]);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _messageCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PdtScaffold(
      title: widget.groupName,
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text('No messages yet — say hello!',
                            style: TextStyle(color: AppTheme.textSecondary)),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) => _buildBubble(_messages[i]),
                      ),
          ),
          if (widget.screen.can('message')) _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatGroupMessage msg) {
    final isMine = msg.sender == _myEmail;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMine ? AppTheme.primary : AppTheme.bgElevated,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  msg.senderName,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
              ),
            Text(
              msg.message,
              style: TextStyle(color: isMine ? Colors.white : AppTheme.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              _formatTime(msg.sentAt),
              style: TextStyle(
                fontSize: 10,
                color: isMine ? Colors.white.withValues(alpha: 0.7) : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        border: Border(top: BorderSide(color: AppTheme.bgBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageCtrl,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Type a message',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send),
              style: IconButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}
