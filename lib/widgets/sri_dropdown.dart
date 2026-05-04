import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';

class SriDropdown<T> extends StatefulWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final String label;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  final IconData? prefixIcon;
  final String? hint;

  const SriDropdown({
    super.key,
    this.value,
    required this.items,
    required this.label,
    required this.onChanged,
    this.validator,
    this.prefixIcon,
    this.hint,
  });

  @override
  State<SriDropdown<T>> createState() => _SriDropdownState<T>();
}

class _SriDropdownState<T> extends State<SriDropdown<T>> {
  // For form validation
  T? _selectedValue;
  final _fieldKey = GlobalKey<FormFieldState>();

  @override
  void initState() {
    super.initState();
    _selectedValue = _safeValue;
  }

  @override
  void didUpdateWidget(SriDropdown<T> old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value || old.items != widget.items) {
      setState(() => _selectedValue = _safeValue);
    }
  }

  T? get _safeValue {
    if (widget.value == null) return null;
    return widget.items.any((i) => i.value == widget.value)
        ? widget.value
        : null;
  }

  // Label of selected item
  String get _selectedLabel {
    if (_selectedValue == null) return '';
    final item = widget.items.firstWhere(
      (i) => i.value == _selectedValue,
      orElse: () => widget.items.first,
    );
    // Extract text from child widget
    final child = item.child;
    if (child is Text) return child.data ?? '';
    if (child is Row) {
      for (final w in child.children) {
        if (w is Text) return w.data ?? '';
        if (w is Expanded) {
          final inner = (w).child;
          if (inner is Text) return inner.data ?? '';
          if (inner is Column) {
            for (final c in inner.children) {
              if (c is Text && (c.data?.isNotEmpty ?? false)) return c.data!;
            }
          }
        }
      }
    }
    return _selectedValue.toString();
  }

  void _openSearch(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _SearchDialog<T>(
        items: widget.items,
        selectedValue: _selectedValue,
        label: widget.label,
        onSelected: (v) {
          setState(() => _selectedValue = v);
          _fieldKey.currentState?.didChange(v);
          widget.onChanged(v);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      key: _fieldKey,
      initialValue: _selectedValue,
      validator: widget.validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _openSearch(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: widget.label,
                  prefixIcon: widget.prefixIcon != null
                      ? Icon(
                          widget.prefixIcon,
                          size: 18,
                          color: AppColors.textMuted,
                        )
                      : null,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedValue != null)
                        GestureDetector(
                          onTap: () {
                            setState(() => _selectedValue = null);
                            _fieldKey.currentState?.didChange(null);
                            widget.onChanged(null);
                          },
                          child: const Icon(
                            Icons.clear_rounded,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                        ),
                      const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                  errorText: state.errorText,
                  errorStyle: const TextStyle(
                    fontSize: 11,
                    color: AppColors.error,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: state.hasError
                          ? AppColors.error
                          : AppColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
                child: Text(
                  _selectedValue != null
                      ? _selectedLabel
                      : (widget.hint ??
                            'Select ${widget.label.replaceAll(' *', '')}...'),
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Nunito',
                    color: _selectedValue != null
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SearchDialog<T> extends StatefulWidget {
  final List<DropdownMenuItem<T>> items;
  final T? selectedValue;
  final String label;
  final void Function(T?) onSelected;

  const _SearchDialog({
    required this.items,
    required this.selectedValue,
    required this.label,
    required this.onSelected,
  });

  @override
  State<_SearchDialog<T>> createState() => _SearchDialogState<T>();
}

class _SearchDialogState<T> extends State<_SearchDialog<T>> {
  final _searchCtrl = TextEditingController();
  List<DropdownMenuItem<T>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _itemLabel(DropdownMenuItem<T> item) {
    final child = item.child;
    if (child is Text) return child.data ?? '';
    if (child is Row) {
      for (final w in child.children) {
        if (w is Text) return w.data ?? '';
        if (w is Expanded) {
          final inner = (w).child;
          if (inner is Text) return inner.data ?? '';
          if (inner is Column) {
            final sb = StringBuffer();
            for (final c in inner.children) {
              if (c is Text && (c.data?.isNotEmpty ?? false)) sb.write(c.data);
            }
            return sb.toString();
          }
        }
      }
    }
    return item.value.toString();
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.items
          : widget.items
                .where((i) => _itemLabel(i).toLowerCase().contains(q))
                .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          children: [
            // ── Header ──────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Select ${widget.label.replaceAll(' *', '')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // ── Search box ───────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Type to search...',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            _filter();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),

            // ── Result count ──────────────────────────
            if (_searchCtrl.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Row(
                  children: [
                    Text(
                      '${_filtered.length} result${_filtered.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(height: 1, color: AppColors.border),

            // ── List ─────────────────────────────────
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 40,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No results for "${_searchCtrl.text}"',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: AppColors.border,
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (_, i) {
                        final item = _filtered[i];
                        final isSelected = item.value == widget.selectedValue;
                        final label = _itemLabel(item);

                        return InkWell(
                          onTap: () {
                            widget.onSelected(item.value);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.07)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                // Icon or avatar
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withOpacity(0.15)
                                        : AppColors.primary.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      label.isNotEmpty
                                          ? label[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Label
                                Expanded(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Checkmark
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // ── Clear selection ──────────────────────
            if (widget.selectedValue != null)
              Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: TextButton.icon(
                  onPressed: () {
                    widget.onSelected(null);
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.clear_rounded,
                    size: 16,
                    color: AppColors.error,
                  ),
                  label: const Text(
                    'Clear Selection',
                    style: TextStyle(color: AppColors.error),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
