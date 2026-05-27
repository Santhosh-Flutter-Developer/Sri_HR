import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/permission_request_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';
import 'package:sri_hr/data/utils/network_time.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/helper/helper.dart';
import 'package:sri_hr/presentation/permission_request/repository/permission_request_repository.dart';
import 'package:sri_hr/presentation/permission_request/ui/permission_form_dialog.dart';

AuthController get auth => Get.find<AuthController>();

class PermissionRequestController extends GetxController {
  final repo = PermissionRepository();
  final permission = <PermissionRequestModel>[].obs;
  final isLoading = false.obs;
  final filterStatus = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  List<PermissionRequestModel> get filteredPermission {
    if (filterStatus.value == null) return permission;
    return permission
        .where((p) => p.status.name == filterStatus.value)
        .toList();
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      permission.value = await repo.getPermissions(
        auth.companyId,
        employeeId: auth.isAdmin ? null : auth.employeeId,
      );
    } catch (e) {
      debugPrint('[PermCtrl] load error: $e');
      showError('Failed to load permissions');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      // Validate required fields
      if ((data['employee_id'] as String?)?.isEmpty != false) {
        throw Exception('Please select an employee');
      }
      if ((data['request_date'] as String?)?.isEmpty != false) {
        throw Exception('Please select a date');
      }
      if ((data['from_time'] as String?)?.isEmpty != false) {
        throw Exception('Please select From Time');
      }
      if ((data['to_time'] as String?)?.isEmpty != false) {
        throw Exception('Please select To Time');
      }

      data['company_id'] = auth.companyId;

      // Calculate minutes between from and to time
      late final DateTime from;
      late final DateTime to;
      try {
        from = parseTime(data['from_time'] as String);
        to = parseTime(data['to_time'] as String);
        if (to.isBefore(from) || to.isAtSameMomentAs(from)) {
          throw Exception('To Time must be after From Time');
        }
        data['minutes'] = to.difference(from).inMinutes;
      } catch (e) {
        if (e is Exception) rethrow;
      }

      // ── Overlap check (existing permission requests) ──────────
      final requestDate = data['request_date'] as String;
      final empId = data['employee_id'] as String;

      final conflict = permission.where((p) {
        // Same employee, same date, not rejected
        if (p.employeeId != empId) return false;
        final pDate = p.requestDate.toIso8601String().substring(0, 10);
        if (pDate != requestDate) return false;
        if (p.status.name == 'rejected') return false;

        // Check time overlap: existing [pFrom, pTo) vs new [from, to)
        final pFrom = parseTime(p.fromTime);
        final pTo = parseTime(p.toTime);
        // Overlap when: newFrom < pTo AND newTo > pFrom
        return from.isBefore(pTo) && to.isAfter(pFrom);
      }).firstOrNull;

      if (conflict != null) {
        throw Exception(
          'A permission request already exists for this time slot '
          '(${conflict.fromTime} – ${conflict.toTime}). '
          'Please choose a different time.',
        );
      }

      // ── Leave check: block if employee is on approved/pending leave ─
      final leaveConflict = await SupabaseService.client
          .from('leave_requests')
          .select('from_date, to_date, status')
          .eq('company_id', auth.companyId)
          .eq('employee_id', empId)
          .lte('from_date', requestDate)
          .gte('to_date', requestDate)
          .neq('status', 'rejected')
          .limit(1)
          .maybeSingle();

      if (leaveConflict != null) {
        final leaveStatus = leaveConflict['status'] as String;
        final fromDt = leaveConflict['from_date'] as String;
        final toDt = leaveConflict['to_date'] as String;
        final statusLabel = leaveStatus == 'approved' ? 'Approved' : 'Pending';
        throw Exception(
          '$statusLabel leave exists for $requestDate '
          '($fromDt to $toDt). Cannot apply permission on a leave day.',
        );
      }

      // ── Punch check: block if punched time overlaps with permission slot ─
      final punchRows = await SupabaseService.client
          .from('attendance_logs')
          .select('punch_time, punch_type')
          .eq('company_id', auth.companyId)
          .eq('employee_id', empId)
          .eq('date', requestDate);

      if (punchRows.isNotEmpty) {
        // Check if any punch time falls inside the requested permission window
        final fromMins = from.hour * 60 + from.minute;
        final toMins = to.hour * 60 + to.minute;

        for (final row in punchRows) {
          final punchTimeStr = row['punch_time'] as String? ?? '';
          final punchDt = DateTime.tryParse(punchTimeStr);
          if (punchDt == null) continue;
          final punchMins = punchDt.hour * 60 + punchDt.minute;
          if (punchMins >= fromMins && punchMins <= toMins) {
            final pType = (row['punch_type'] as String?) ?? 'punch';
            final punchLabel = pType == 'in' ? 'Punch In' : 'Punch Out';
            final punchDisplay =
                '${punchDt.hour.toString().padLeft(2, '0')}:${punchDt.minute.toString().padLeft(2, '0')}';
            throw Exception(
              '$punchLabel recorded at $punchDisplay on $requestDate '
              'overlaps with the requested permission time '
              '(${data['from_time']} – ${data['to_time']}). '
              'Cannot apply permission on an already punched time slot.',
            );
          }
        }
      }
      // ───────────────────────────────────────────────────────────

      debugPrint('[PermCtrl] creating: $data');
      final perm = await repo.createPermission(data);
      permission.insert(0, perm);
      showSuccess('Permission request submitted');
    } catch (e) {
      debugPrint('[PermCtrl] create error: $e');
      showError(e.toString().replaceAll('Exception: ', ''));
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  DateTime parseTime(String t) {
    final parts = t.split(':');
    final now = NetworkTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  Future<void> approve(String id) async {
    try {
      final updated = await repo.updatePermissionStatus(
        id,
        'approved',
        auth.userId,
      );
      updateLocal(id, updated);
      showSuccess('Permission approved');
    } catch (e) {
      showError('Failed to approve: $e');
    }
  }

  Future<void> reject(String id) async {
    try {
      final updated = await repo.updatePermissionStatus(
        id,
        'rejected',
        auth.userId,
      );
      updateLocal(id, updated);
      showSuccess('Permission rejected');
    } catch (e) {
      showError('Failed to reject: $e');
    }
  }

  void confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Permission'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              delete(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> delete(String id) async {
    try {
      await repo.deletePermission(id);
      permission.removeWhere((p) => p.id == id);
      showSuccess('Permission deleted');
    } catch (e) {
      showError('Failed to delete: $e');
    }
  }

  void updateLocal(String id, PermissionRequestModel updated) {
    final idx = permission.indexWhere((p) => p.id == id);
    if (idx != -1) permission[idx] = updated;
  }

  void showForm(BuildContext context, PermissionRequestController controller) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PermissionFormDialog(controller: controller),
    );
  }
}
