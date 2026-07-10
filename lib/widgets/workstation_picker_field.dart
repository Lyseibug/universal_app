import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'scan_input_field.dart';

/// Tap-to-open workstation selector. Replaces a plain DropdownButtonFormField
/// for workers with a large number of assigned workstations — scrolling a
/// native dropdown with 30+ entries (e.g. every CURING pot on Line 1+2) is
/// unusable, so this opens a sheet with live text-search plus barcode/keyboard
/// scan (via the same ScanInputField used for flowchart/tool scans elsewhere),
/// instead of a flat unscrollable-by-search list.
class WorkstationPickerField extends StatelessWidget {
  final List<String> availableWorkstations;
  final String? selectedWorkstation;
  final ValueChanged<String?>? onWorkstationChanged;
  final String label;
  final String hintText;

  const WorkstationPickerField({
    required this.availableWorkstations,
    this.selectedWorkstation,
    this.onWorkstationChanged,
    this.label = 'WORKSTATION ID',
    this.hintText = 'Select workstation',
    super.key,
  });

  Future<void> _openPicker(BuildContext context) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _WorkstationSearchSheet(
        workstations: availableWorkstations,
        selected: selectedWorkstation,
      ),
    );
    if (chosen != null && onWorkstationChanged != null) {
      onWorkstationChanged!(chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: hintText,
          suffixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
        ),
        isEmpty: selectedWorkstation == null,
        child: selectedWorkstation != null
            ? Text(selectedWorkstation!, style: const TextStyle(color: AppTheme.textPrimary))
            : null,
      ),
    );
  }
}

class _WorkstationSearchSheet extends StatefulWidget {
  final List<String> workstations;
  final String? selected;

  const _WorkstationSearchSheet({required this.workstations, this.selected});

  @override
  State<_WorkstationSearchSheet> createState() => _WorkstationSearchSheetState();
}

class _WorkstationSearchSheetState extends State<_WorkstationSearchSheet> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
  }

  void _onScanned(String value) {
    setState(() => _query = value);
    // An exact (case-insensitive) match — from a hardware/camera scan of a
    // workstation label — selects immediately rather than making the worker
    // tap it again in the filtered list below.
    final exact = widget.workstations
        .where((ws) => ws.toLowerCase() == value.trim().toLowerCase());
    if (exact.isNotEmpty) {
      Navigator.of(context).pop(exact.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.workstations
        : widget.workstations
            .where((ws) => ws.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.factory_outlined, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Select Workstation',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ScanInputField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              labelText: 'Search or Scan',
              hintText: 'Type or scan workstation ID',
              prefixIcon: Icons.search,
              onChanged: _onQueryChanged,
              onScanned: _onScanned,
              autofocus: true,
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No matching workstation',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final ws = filtered[i];
                      final isSelected = ws == widget.selected;
                      return ListTile(
                        title: Text(ws),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: AppTheme.success)
                            : null,
                        onTap: () => Navigator.of(context).pop(ws),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
