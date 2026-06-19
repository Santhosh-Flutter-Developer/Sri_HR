import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';

class SriPaginationBar extends StatelessWidget {
  final int currentPage; // 0-based
  final int totalItems;
  final int rowLimit;
  final List<int> rowLimitOptions;
  final void Function(int page) onPageChanged;
  final void Function(int limit) onLimitChanged;

  const SriPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalItems,
    required this.rowLimit,
    required this.onPageChanged,
    required this.onLimitChanged,
    this.rowLimitOptions = const [10, 20, 50, 100],
  });

  int get _totalPages => (totalItems / rowLimit).ceil().clamp(1, 999999);
  int get _start => currentPage * rowLimit + 1;
  int get _end => ((currentPage + 1) * rowLimit).clamp(0, totalItems);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    if (totalItems == 0) return const SizedBox.shrink();

    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (isWide)
            // ── Rows per page ────────────────────────────────
            const Text(
              'Rows per page:',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontFamily: 'Nunito',
              ),
            ),
          const SizedBox(width: 8),
          _LimitDropdown(
            value: rowLimit,
            options: rowLimitOptions,
            onChanged: onLimitChanged,
          ),

          const Spacer(),

          // ── Record range label ────────────────────────────
          Text(
            '$_start–$_end of $totalItems',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontFamily: 'Nunito',
            ),
          ),

          const SizedBox(width: 12),

          // ── Prev chevron ──────────────────────────────────
          _NavBtn(
            icon: Icons.chevron_left_rounded,
            enabled: currentPage > 0,
            onTap: () => onPageChanged(currentPage - 1),
          ),

          const SizedBox(width: 6),

          // ── Page indicator pill  "1 / 2" ─────────────────
          Container(
            height: 32,
            constraints: const BoxConstraints(minWidth: 60),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${currentPage + 1} / $_totalPages',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'Nunito',
              ),
            ),
          ),

          const SizedBox(width: 6),

          // ── Next chevron ──────────────────────────────────
          _NavBtn(
            icon: Icons.chevron_right_rounded,
            enabled: currentPage < _totalPages - 1,
            onTap: () => onPageChanged(currentPage + 1),
          ),
        ],
      ),
    );
  }
}

// ── Compact dropdown for row-limit ───────────────────────────────────────────
class _LimitDropdown extends StatelessWidget {
  final int value;
  final List<int> options;
  final void Function(int) onChanged;

  const _LimitDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isDense: true,
          borderRadius: BorderRadius.circular(10),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary,
            fontFamily: 'Nunito',
          ),
          items: options
              .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ── Chevron nav button ────────────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.surfaceVariant
              : AppColors.border.withOpacity(0.4),
          border: Border.all(
            color: enabled
                ? AppColors.border
                : AppColors.border.withOpacity(0.4),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.textSecondary : AppColors.textMuted,
        ),
      ),
    );
  }
}
