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

  // Maintenance states
  final _maintEquipCtrl = TextEditingController();
  final _maintTypeCtrl = TextEditingController();
  final _maintDescCtrl = TextEditingController();
  String _maintUrgency = 'Normal';
  bool _sendingMaint = false;

  @override
  void dispose() {
    _chatCtrl.dispose();
    _issueTypeCtrl.dispose();
    _issueDescCtrl.dispose();
    _maintEquipCtrl.dispose();
    _maintTypeCtrl.dispose();
    _maintDescCtrl.dispose();
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

  Future<void> _submitMaintenance() async {
    final equip = _maintEquipCtrl.text.trim();
    final type = _maintTypeCtrl.text.trim();
    final desc = _maintDescCtrl.text.trim();

    if (equip.isEmpty || type.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all maintenance request fields.')),
      );
      return;
    }

    setState(() => _sendingMaint = true);
    try {
      await ref.read(supportRepositoryProvider).raiseMaintenanceRequest(
            equipment: equip,
            issueType: type,
            description: desc,
            urgency: _maintUrgency,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maintenance request submitted!'), backgroundColor: AppTheme.success),
      );
      _maintEquipCtrl.clear();
      _maintTypeCtrl.clear();
      _maintDescCtrl.clear();
      setState(() => _maintUrgency = 'Normal');
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageFor(e)), backgroundColor: AppTheme.danger),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
      );
    } finally {
      setState(() => _sendingMaint = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasChat = widget.screen.can('chat');
    final hasIssue = widget.screen.can('raise_issue');
    final hasMaint = widget.screen.can('maintenance_request');

    return Scaffold(
      backgroundColor: AppTheme.bgScaffold,
      appBar: AppBar(
        title: const Text('Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.horizontalPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!hasChat && !hasIssue && !hasMaint)
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

            // Maintenance Request Section
            if (hasMaint) ...[
              _buildSectionHeader('Maintenance Request'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomTextField(
                        controller: _maintEquipCtrl,
                        labelText: 'Equipment / Machine ID',
                        hintText: 'e.g. Forklift-03, Scanner-12',
                        prefixIcon: const Icon(Icons.precision_manufacturing_outlined),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _maintTypeCtrl,
                        labelText: 'Issue Type',
                        hintText: 'e.g. Battery dead, Wheel damaged, Motor overheating',
                        prefixIcon: const Icon(Icons.build_outlined),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _maintDescCtrl,
                        labelText: 'Description',
                        hintText: 'Provide details about maintenance needs...',
                        prefixIcon: const Icon(Icons.info_outline),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 14),
                      
                      // Urgency dropdown
                      DropdownButtonFormField<String>(
                        value: _maintUrgency,
                        decoration: const InputDecoration(
                          labelText: 'Urgency Level',
                          prefixIcon: Icon(Icons.priority_high_outlined),
                        ),
                        items: ['Normal', 'Medium', 'High', 'Critical'].map((String level) {
                          return DropdownMenuItem<String>(
                            value: level,
                            child: Text(level),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _maintUrgency = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      CustomButton(
                        text: 'Raise Maintenance Request',
                        isLoading: _sendingMaint,
                        icon: Icons.engineering_outlined,
                        onPressed: _submitMaintenance,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
