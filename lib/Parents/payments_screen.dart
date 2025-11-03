import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vraz_application/Parents/service/payment_service.dart';

import 'models/payment_model.dart';
import 'parent_app_drawer.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // State variables
  List<PaymentInstallment> _installments = [];
  PaymentSummary? _summary;
  bool _isLoading = true;

  String? _authToken;
  int? _selectedChildId;
  String? _selectedChildName;

  @override
  void initState() {
    super.initState();
    _loadPaymentData();
  }

  Future<void> _loadPaymentData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Get auth token and selected child
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('parent_auth_token');
      _selectedChildId = prefs.getInt('selected_child_id');
      _selectedChildName = prefs.getString('selected_child_name');

      print('[PaymentsScreen] Auth Token: ${_authToken != null ? "Found" : "Missing"}');
      print('[PaymentsScreen] Selected Child ID: $_selectedChildId');

      if (_authToken == null || _authToken!.isEmpty) {
        _showError('Session expired. Please login again.');
        return;
      }

      if (_selectedChildId == null) {
        _showError('No child selected. Please select a child from dashboard.');
        return;
      }

      // 2. Fetch payment plan from API
      print('[PaymentsScreen] 🔄 Fetching payment plan...');
      _installments = await PaymentApi.fetchPaymentPlan(
        authToken: _authToken!,
        childId: _selectedChildId!,
      );

      if (_installments.isNotEmpty) {
        _summary = PaymentApi.calculateSummary(_installments);
        print('[PaymentsScreen] ✅ Loaded ${_installments.length} installments');
        print('[PaymentsScreen] 📊 Summary: ${_summary}');
      } else {
        print('[PaymentsScreen] ℹ️ No payment installments found');
        _showInfo('No payment plan available.');
      }
    } catch (e, stackTrace) {
      print('[PaymentsScreen] ❌ Error: $e');
      print('[PaymentsScreen] Stack trace: $stackTrace');
      _showError('Failed to load payment data. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showInfo(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black54),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'Payments',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _isLoading ? null : _loadPaymentData,
            tooltip: 'Refresh',
          ),
        ],
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      drawer: const ParentAppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadPaymentData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStudentInfoCard(),
              const SizedBox(height: 24),
              if (_summary != null) ...[
                _buildInstallmentPlanCard(),
                const SizedBox(height: 12),
                if (_summary!.nextDue != null) _buildNextInstallmentCard(),
                const SizedBox(height: 24),
              ],
              _buildTransactionHistorySection(),
              const SizedBox(height: 12),
              if (_installments.isEmpty)
                _buildEmptyState()
              else
                ..._installments.map((installment) => _buildTransactionCard(installment)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage('assets/profile.png'),
            backgroundColor: Colors.blueGrey,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedChildName ?? 'Student',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (_summary != null)
                  Text(
                    'Paid: ${_summary!.formattedTotalPaid} of ${_summary!.formattedTotalFee}',
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentPlanCard() {
    if (_summary == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20.0), // ✅ FIXED: Added padding
      constraints: const BoxConstraints(minHeight: 180), // ✅ FIXED: Min height instead of fixed
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade100, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // ✅ FIXED: Use min size
        children: [
          const Text(
            'Installment Plan',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Total Fee',
            style: TextStyle(color: Colors.black87, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            _summary!.formattedTotalFee,
            style: const TextStyle(
              color: Colors.blueAccent,
              fontSize: 36, // ✅ FIXED: Reduced from 40
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatChip('Paid', _summary!.paidCount, Colors.green),
              const SizedBox(width: 8),
              _buildStatChip('Pending', _summary!.pendingCount, Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _summary!.paymentProgress / 100,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            '${_summary!.paymentProgress.toStringAsFixed(1)}% Completed',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    final textColor = color == Colors.green ? const Color(0xFF2E7D32) : const Color(0xFFE65100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildNextInstallmentCard() {
    if (_summary?.nextDue == null) return const SizedBox.shrink();
    final nextInstallment = _summary!.nextDue!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nextInstallment.formattedAmount,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nextInstallment.installmentName,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    Text(
                      'Due: ${nextInstallment.formattedDueDate}',
                      style: TextStyle(
                        color: nextInstallment.isOverdue ? Colors.red : Colors.black54,
                        fontWeight: nextInstallment.isOverdue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _showPaymentConfirmationDialog(context, nextInstallment);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Pay Now',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPaymentConfirmationDialog(BuildContext context, PaymentInstallment installment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to pay:',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text(
                installment.formattedAmount,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 4),
              Text(installment.installmentName),
              const SizedBox(height: 16),
              const Text('By proceeding, you will be redirected to the payment gateway.'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              child: const Text('Proceed to Pay', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔜 Payment gateway integration coming soon...'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionHistorySection() {
    return const Text(
      'Payment History',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No payment history',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(PaymentInstallment installment) {
    final isPaid = installment.isPaid;
    final statusColor = isPaid ? Colors.green : (installment.isOverdue ? Colors.red : Colors.orange);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    installment.installmentName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Due: ${installment.formattedDueDate}',
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  if (installment.transactions.isNotEmpty)
                    Text(
                      'Paid on: ${installment.transactions.first.formattedPaymentDate}',
                      style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  installment.formattedAmount,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: statusColor, size: 8),
                      const SizedBox(width: 4),
                      Text(
                        installment.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isPaid && installment.transactions.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.receipt, color: Colors.blueAccent, size: 20),
                onPressed: () {
                  _showReceiptModal(context, installment);
                },
                tooltip: 'View Receipt',
              ),
          ],
        ),
      ),
    );
  }

  void _showReceiptModal(BuildContext context, PaymentInstallment installment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ReceiptsModal(installment: installment, childName: _selectedChildName ?? 'Student');
      },
    );
  }
}

class ReceiptsModal extends StatelessWidget {
  final PaymentInstallment installment;
  final String childName;

  const ReceiptsModal({
    super.key,
    required this.installment,
    required this.childName,
  });

  @override
  Widget build(BuildContext context) {
    final transaction = installment.transactions.isNotEmpty ? installment.transactions.first : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF0F4F8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Payment Receipt',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      _buildReceiptCard(transaction),
                      const SizedBox(height: 24),
                      _buildActionButtons(context),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiptCard(Transaction? transaction) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fee Receipt',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (transaction != null)
                Text(
                  transaction.formattedPaymentDate,
                  style: TextStyle(color: Colors.grey[600]),
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (transaction != null && transaction.referenceNumber.isNotEmpty)
            Text(
              'Ref: ${transaction.referenceNumber}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          const Divider(height: 30),
          _buildStudentInfo(),
          const SizedBox(height: 24),
          const Text(
            'Payment Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildFeeItem('Installment', installment.installmentName),
          _buildFeeItem('Amount', installment.formattedAmount),
          if (transaction != null) ...[
            _buildFeeItem('Payment Method', transaction.paymentMethod),
            _buildFeeItem('Status', transaction.status),
          ],
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Paid',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                installment.formattedAmount,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'This is a computer-generated receipt and does not require a signature.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfo() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundImage: AssetImage('assets/profile.png'),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              childName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'Installment Payment',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeeItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📤 Sharing receipt...')),
              );
            },
            icon: const Icon(Icons.share, color: Colors.blueAccent),
            label: const Text('Share', style: TextStyle(color: Colors.blueAccent)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: Colors.blueAccent),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📥 Downloading receipt...')),
              );
            },
            icon: const Icon(Icons.download, color: Colors.white),
            label: const Text('Download', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}