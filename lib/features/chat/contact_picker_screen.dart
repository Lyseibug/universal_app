import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/menu/menu_models.dart';
import '../../core/models/direct_chat_models.dart';
import '../../core/theme/app_theme.dart';
import 'direct_chat_repository.dart';
import 'direct_chat_thread_screen.dart';

/// "New Chat" contact picker — search/browse any PDT User, tap to open (or
/// start) a thread with them. Reachable from GroupChatListScreen's FAB.
class ContactPickerScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;
  const ContactPickerScreen({required this.screen, super.key});

  @override
  ConsumerState<ContactPickerScreen> createState() => _ContactPickerScreenState();
}

class _ContactPickerScreenState extends ConsumerState<ContactPickerScreen> {
  final _searchCtrl = TextEditingController();
  List<PdtContact> _contacts = [];
  bool _loading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? search}) async {
    setState(() => _loading = true);
    try {
      final contacts = await ref.read(directChatRepositoryProvider).listContacts(search: search);
      if (mounted) setState(() { _contacts = contacts; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _load(search: value.trim()));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgScaffold,
      appBar: AppBar(title: const Text('New Chat')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search people',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppTheme.bgSurface,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _contacts.isEmpty
                    ? const Center(
                        child: Text('No matching people', style: TextStyle(color: AppTheme.textSecondary)),
                      )
                    : ListView.builder(
                        itemCount: _contacts.length,
                        itemBuilder: (context, i) {
                          final c = _contacts[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                              child: Text(
                                c.fullName.isNotEmpty ? c.fullName[0].toUpperCase() : '?',
                                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(c.fullName),
                            subtitle: Text(c.email, style: const TextStyle(fontSize: 12)),
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => DirectChatThreadScreen(
                                  screen: widget.screen,
                                  withUser: c.email,
                                  withUserName: c.fullName,
                                ),
                              ));
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
