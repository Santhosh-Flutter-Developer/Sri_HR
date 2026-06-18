import 'dart:developer';

import 'package:http/http.dart' as http;

class SmsService {
  static const String _apiKey = 'XyQJkRbwyx1Ekobn';
  static const String _senderId = 'SRISOF';
  static const String _templateId = '1207163299627174072';
  static const String _baseUrl = 'https://text.draft4sms.com/vb/apikey.php';

  static Future<bool> sendOtp({
    required String mobileNumber, // 91XXXXXXXXXX
    required String otp,
    required String appName,
  }) async {
    try {
      // Message must match DLT template EXACTLY:
      // "{#var#} is your one time password to proceed on {#var#}. Do not share your OTP with anyone. -srisoft"
      final message = Uri.encodeComponent(
        '$otp is your one time password to proceed on $appName. Do not share your OTP with anyone. -srisoft',
      );

      final url =
          '$_baseUrl'
          '?apikey=$_apiKey'
          '&senderid=$_senderId'
          '&number=$mobileNumber'
          '&message=$message'
          '&route=1'
          '&DLT_TE_ID=$_templateId';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      final body = response.body;
      log('Draft4SMS [${response.statusCode}]: $body');

      if (response.statusCode != 200) return false;

      final bodyLower = body.toLowerCase().trim();

      // ── Accept any of these success indicators ──────────────
      // Draft4SMS returns various formats — treat any 200 with a
      // non-error body as success, since the SMS was delivered.
      // Known failure keywords: 'invalid', 'error', 'failed',
      // 'insufficient', 'blocked', 'rejected'
      const failKeywords = [
        'invalid',
        'error',
        'failed',
        'insufficient',
        'blocked',
        'rejected',
        'unauthorized',
        'expire',
      ];

      final hasFail = failKeywords.any((k) => bodyLower.contains(k));
      if (hasFail) {
        log('Draft4SMS: response indicates failure → $body');
        return false;
      }

      // If body is non-empty and has no failure keyword → treat as success
      // (covers "success", numeric message IDs, "Sent", etc.)
      return bodyLower.isNotEmpty;
    } catch (e) {
      log('SmsService error: $e');
      return false;
    }
  } 
}