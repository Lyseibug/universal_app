import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/menu/menu_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'support_repository.dart';

class SupportScreen extends ConsumerStatefulWidget {
  final MenuScreen screen;

  const SupportScreen({required this.screen, super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  // Chat form states
  final _chatCtrl = TextEditingController();
  bool _sendingChat = false;

  // Issue ticket states
  final _issueTypeCtrl = TextEditingController();
  final _issueDescCtrl = TextEditingController();
  bool _sendingIssue = false;

  @override
  void dispose() {
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
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageFor(e)), backgroundColor: AppTheme.danger),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
      );
    } finally {
      setState(() => _sendingChat = false);
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
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageFor(e)), backgroundColor: AppTheme.danger),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
      );
    } finally {
      setState(() => _sendingIssue = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasChat = widget.screen.can('chat');
    final hasIssue = widget.screen.can('raise_issue');

    return Scaffold(
      backgroundColor: AppTheme.bgScaffold,
      appBar: AppBar(
        title: Text(widget.screen.label),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.horizontalPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!hasChat && !hasIssue)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 64),
                  child: Text(
                    'No support actions authorized for your account.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Supervisor Chat Section
            if (hasChat) ...[
              _buildSectionHeader('Supervisor Notification / Chat'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomTextField(
                        controller: _chatCtrl,
                        labelText: 'Message Text',
                        hintText: 'Type message to supervisor...',
                        prefixIcon: const Icon(Icons.chat_bubble_outline),
                      ),
                      const SizedBox(height: 14),
                      CustomButton(
                        text: 'Send to Supervisor',
                        isLoading: _sendingChat,
                        icon: Icons.send,
                        onPressed: _sendChat,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Support Ticket Section
            if (hasIssue) ...[
              _buildSectionHeader('Raise Support Ticket'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomTextField(
                        controller: _issueTypeCtrl,
                        labelText: 'Issue Category',
                        hintText: 'e.g. Printer, Wi-Fi connectivity, App error',
                        prefixIcon: const Icon(Icons.label_outline),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _issueDescCtrl,
                        labelText: 'Description',
                        hintText: 'Describe details of the issue...',
                        prefixIcon: const Icon(Icons.description_outlined),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      CustomButton(
                        text: 'Submit Support Ticket',
                        isLoading: _sendingIssue,
                        icon: Icons.confirmation_number_outlined,
                        onPressed: _raiseSupport,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: AppTheme.primary,
        fontSize: 12,
        letterSpacing: 1.0,
      ),
    );
  }
}
