import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../core/api/api_exceptions.dart';
import '../core/errors/error_mapper.dart';
import '../core/sync/write_queue_entry.dart';
import '../core/theme/app_theme.dart';
import '../providers/service_providers.dart';
import '../features/support/support_repository.dart';
import '../features/maintenance/maintenance_request_form.dart';
import 'custom_button.dart';
import 'custom_text_field.dart';

class PdtScaffold extends ConsumerStatefulWidget {
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  const PdtScaffold({
    required this.body,
    required this.title,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    super.key,
  });

  @override
  ConsumerState<PdtScaffold> createState() => _PdtScaffoldState();
}

class _PdtScaffoldState extends ConsumerState<PdtScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isFlushing = false;

  Future<void> _flushQueue() async {
    setState(() => _isFlushing = true);
    try {
      await ref.read(writeQueueProvider).flush();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offline queue synced successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Queue sync completed. Some items might still be pending.'),
          backgroundColor: AppTheme.warning,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isFlushing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final writeQueue = ref.watch(writeQueueProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.bgScaffold,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          ...?widget.actions,
          
          // Write Queue Sync Status Icon
          ValueListenableBuilder<Box<WriteQueueEntry>>(
            valueListenable: Hive.box<WriteQueueEntry>('write_queue').listenable(),
            builder: (context, box, child) {
              final pendingCount = box.values.where((e) => e.status == QueueStatus.pending).length;
              if (pendingCount == 0) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Badge(
                  label: Text('$pendingCount'),
                  child: IconButton(
                    icon: _isFlushing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    onPressed: _isFlushing ? null : _flushQueue,
                  ),
                ),
              );
            },
          ),

          // Support Drawer Trigger Button
          IconButton(
            icon: const Icon(Icons.support_agent_outlined),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: const Drawer(
        width: 320,
        child: _SupportDrawer(),
      ),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: widget.bottomNavigationBar,
    );
  }
}

class _SupportDrawer extends ConsumerStatefulWidget {
  const _SupportDrawer();

  @override
  ConsumerState<_SupportDrawer> createState() => _SupportDrawerState();
}

class _SupportDrawerState extends ConsumerState<_SupportDrawer> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Chat
  final _chatCtrl = TextEditingController();
  bool _sendingChat = false;

  // Issue Ticket
  final _issueTypeCtrl = TextEditingController();
  final _issueDescCtrl = TextEditingController();
  bool _sendingIssue = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatCtrl.dispose();
    _issueTypeCtrl.dispose();
    _issueDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendChat() async {
    final msg = _chatCtrl.text.trim();
    if (msg.isEmpty) return;

    setState(() => _sendingChat = true);
    try {
      await ref.read(supportRepositoryProvider).sendChat(message: msg);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat message sent to supervisor!'), backgroundColor: AppTheme.success),
      );
      _chatCtrl.clear();
      Navigator.of(context).pop(); // close drawer
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageFor(e)), backgroundColor: AppTheme.danger),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
      );
    } finally {
      if (mounted) setState(() => _sendingChat = false);
    }
  }

  Future<void> _raiseSupport() async {
    final type = _issueTypeCtrl.text.trim();
    final desc = _issueDescCtrl.text.trim();
    if (type.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter support type and description.')),
      );
      return;
    }

    setState(() => _sendingIssue = true);
    try {
      await ref.read(supportRepositoryProvider).raiseSupport(
            supportType: type,
            payload: {'description': desc},
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Support ticket raised successfully!'), backgroundColor: AppTheme.success),
      );
      _issueTypeCtrl.clear();
      _issueDescCtrl.clear();
      Navigator.of(context).pop(); // close drawer
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageFor(e)), backgroundColor: AppTheme.danger),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
      );
    } finally {
      if (mounted) setState(() => _sendingIssue = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Quick Support'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Chat'),
            Tab(text: 'Ticket'),
            Tab(text: 'Maint.'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Chat Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: _chatCtrl,
                  labelText: 'Notify Supervisor',
                  hintText: 'Type supervisor message...',
                  prefixIcon: const Icon(Icons.chat_bubble_outline),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Send Message',
                  isLoading: _sendingChat,
                  icon: Icons.send,
                  onPressed: _sendChat,
                ),
              ],
            ),
          ),
          // Issue Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: _issueTypeCtrl,
                  labelText: 'Category',
                  hintText: 'e.g. Printer, WiFi, App Error',
                  prefixIcon: const Icon(Icons.label_outline),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _issueDescCtrl,
                  labelText: 'Details',
                  hintText: 'Describe the issue...',
                  prefixIcon: const Icon(Icons.description_outlined),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Submit Ticket',
                  isLoading: _sendingIssue,
                  icon: Icons.confirmation_number_outlined,
                  onPressed: _raiseSupport,
                ),
              ],
            ),
          ),
          // Maintenance Tab -- shared form with the dedicated
          // maintenance_request screen (raise_maintenance_request_screen.dart);
          // closes the drawer on a successful submit, same as Chat/Ticket above.
          MaintenanceRequestForm(onSubmitted: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}
