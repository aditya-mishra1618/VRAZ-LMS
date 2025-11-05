import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../models/payment_model.dart';

class PaymentApi {
  /// Fetch payment plan for a specific child
  static Future<List<PaymentInstallment>> fetchPaymentPlan({
    required String authToken,
    required int childId,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/parentMobile/my/children/paymentPlan/$childId',
    );

    print('[PaymentApi] 💳 Fetching payment plan for child ID: $childId');
    print('[PaymentApi] GET $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      print('[PaymentApi] Response status: ${response.statusCode}');
      print('[PaymentApi] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different response structures
        List<dynamic> installmentsData;

        if (data is List) {
          installmentsData = data;
        } else if (data is Map<String, dynamic>) {
          installmentsData = data['installments'] ??
              data['data'] ??
              data['paymentPlan'] ??
              [];
        } else {
          print('[PaymentApi] ⚠️ Unexpected response format');
          return [];
        }

        if (installmentsData.isEmpty) {
          print('[PaymentApi] ℹ️ No payment installments found');
          return [];
        }

        final installments = installmentsData
            .map((e) => PaymentInstallment.fromJson(e as Map<String, dynamic>))
            .toList();

        // Sort by due date
        installments.sort((a, b) => a.dueDate.compareTo(b.dueDate));

        print('[PaymentApi] ✅ Parsed ${installments.length} installments');
        print('[PaymentApi] Paid: ${installments.where((i) => i.isPaid).length}');
        print('[PaymentApi] Pending: ${installments.where((i) => i.isPending).length}');

        return installments;
      } else if (response.statusCode == 401) {
        print('[PaymentApi] ❌ Unauthorized - token may be expired');
        return [];
      } else if (response.statusCode == 404) {
        print('[PaymentApi] ℹ️ No payment plan found for this child');
        return [];
      } else {
        print('[PaymentApi] ❌ Failed with status: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      print('[PaymentApi] ❌ ERROR: $e');
      print('[PaymentApi] Stack trace: $stackTrace');
      return [];
    }
  }

  /// Calculate payment summary
  static PaymentSummary calculateSummary(List<PaymentInstallment> installments) {
    return PaymentSummary.fromInstallments(installments);
  }
}