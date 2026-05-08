import 'dart:developer';

import 'package:http/http.dart' as http;

class SmsService {
  static const String _apiKey = 'XyQJkRbwyx1Ekobn';
  static const String _senderId =
      'SRISOF'; // ✅ Exact Sender ID from template list
  static const String _templateId =
      '1207163299627174072'; // ✅ Template ID from row 6
  static const String _baseUrl = 'https://text.draft4sms.com/vb/apikey.php';

  static Future<bool> sendOtp({
    required String mobileNumber, // 91XXXXXXXXXX
    required String otp,
    required String appName, // second {#var#} in template
  }) async {
    try {
      // ✅ Message must match DLT template EXACTLY:
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
          '&DLT_TE_ID=$_templateId'; // ✅ DLT Template ID parameter

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      log('Draft4SMS [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200) {
        final body = response.body.toLowerCase();
        return body.contains('success') || body.contains('"status":"true"');
      }
      return false;
    } catch (e) {
      log('SmsService error: $e');
      return false;
    }
  }
}
