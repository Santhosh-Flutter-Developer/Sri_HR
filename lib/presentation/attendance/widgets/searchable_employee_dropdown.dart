import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/employee_model.dart';

class SearchableEmployeeDropdown extends StatefulWidget {
  final List<EmployeeModel> employees;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool isAdmin;

  const SearchableEmployeeDropdown({
    super.key,
    required this.employees,
    required this.value,
    required this.onChanged,
    required this.isAdmin,
  });

  @override
  State<SearchableEmployeeDropdown> createState() =>
      _SearchableEmployeeDropdownState();
}

class _SearchableEmployeeDropdownState
    extends State<SearchableEmployeeDropdown> {
  String get _displayLabel {
    if (widget.value == null) return 'All Employees';
    final emp = widget.employees.firstWhereOrNull((e) => e.id == widget.value);
    return emp != null
        ? '${emp.employeeCode} – ${emp.fullName}'
        : 'All Employees';
  }

  void _openSearch() async {
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmployeeSearchSheet(
        employees: widget.employees,
        selectedId: widget.value,
        isAdmin: widget.isAdmin,
      ),
    );

    if (result != null) {
      widget.onChanged(result == '__all__' ? null : result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.isAdmin ? _openSearch : null,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Employee (optional)',
          prefixIcon: Icon(
            Icons.person_rounded,
            size: 18,
            color: AppColors.textMuted,
          ),
          suffixIcon: Icon(Icons.arrow_drop_down),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
        child: Text(
          _displayLabel,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _EmployeeSearchSheet extends StatefulWidget {
  final List<EmployeeModel> employees;
  final String? selectedId;
  final bool isAdmin;

  const _EmployeeSearchSheet({
    required this.employees,
    required this.selectedId,
    required this.isAdmin,
  });

  @override
  State<_EmployeeSearchSheet> createState() => _EmployeeSearchSheetState();
}

class _EmployeeSearchSheetState extends State<_EmployeeSearchSheet> {
  final _searchCtrl = TextEditingController();
  List<EmployeeModel> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.employees;
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = widget.employees.where((e) {
        return '${e.employeeCode} ${e.fullName}'.toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    // ✅ Material with color + borderRadius directly — no Container/BoxDecoration between
    // Material and ListTile, so ink splashes render correctly
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search employee...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              // Employee list
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (widget.isAdmin)
                      ListTile(
                        leading: const Icon(Icons.people_outline, size: 18),
                        title: const Text(
                          'All Employees',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        selected: widget.selectedId == null,
                        onTap: () => Navigator.pop(context, '__all__'),
                      ),
                    ..._filtered.map(
                      (e) => ListTile(
                        leading: const Icon(Icons.person_outline, size: 18),
                        title: Text(
                          '${e.employeeCode} – ${e.fullName}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        selected: e.id == widget.selectedId,
                        onTap: () => Navigator.pop(context, e.id),
                      ),
                    ),
                    if (_filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No employees found',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}