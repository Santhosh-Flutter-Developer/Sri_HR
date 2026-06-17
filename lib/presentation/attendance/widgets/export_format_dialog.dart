import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';

enum ExportFormat { pdf, excel }

class ExportFormatDialog extends StatelessWidget {
  const ExportFormatDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 360,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.download_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Export Attendance Report',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Subtitle
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                'Choose your preferred export format',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // PDF Option
            _FormatTile(
              icon: Icons.picture_as_pdf_rounded,
              iconColor: const Color(0xFFEF4444),
              iconBg: const Color(0xFFFEF2F2),
              title: 'PDF Report',
              
              // badge: 'Recommended',
              badgeColor: AppColors.primary,
              onTap: () => Navigator.pop(context, ExportFormat.pdf),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 1, color: AppColors.border),
            ),

            // Excel Option
            _FormatTile(
              icon: Icons.table_chart_rounded,
              iconColor: const Color(0xFF22C55E),
              iconBg: const Color(0xFFF0FDF4),
              title: 'Excel Spreadsheet',
              
              // badge: 'Multi-sheet',
              badgeColor: const Color(0xFF22C55E),
              onTap: () => Navigator.pop(context, ExportFormat.excel),
            ),

            const SizedBox(height: 16),

            // Cancel
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  // final String subtitle;
  // final String badge;
  final Color badgeColor;
  final VoidCallback onTap;

  const _FormatTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    // required this.subtitle,
    // required this.badge,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      // const SizedBox(width: 8),
                      // Container(
                      //   padding: const EdgeInsets.symmetric(
                      //     horizontal: 7,
                      //     vertical: 2,
                      //   ),
                      //   decoration: BoxDecoration(
                      //     color: badgeColor.withOpacity(0.1),
                      //     borderRadius: BorderRadius.circular(20),
                      //   ),
                      //   child: Text(
                      //     badge,
                      //     style: TextStyle(
                      //       fontSize: 10,
                      //       color: badgeColor,
                      //       fontWeight: FontWeight.w600,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                  // const SizedBox(height: 3),
                  // Text(
                  //   subtitle,
                  //   style: const TextStyle(
                  //     fontSize: 11.5,
                  //     color: AppColors.textMuted,
                  //     height: 1.4,
                  //   ),
                  // ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
