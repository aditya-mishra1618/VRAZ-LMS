import 'package:intl/intl.dart';

class PaymentInstallment {
  final int id;
  final int admissionId;
  final String installmentName;
  final String amountDue;
  final DateTime dueDate;
  final String status;
  final List<Transaction> transactions;

  PaymentInstallment({
    required this.id,
    required this.admissionId,
    required this.installmentName,
    required this.amountDue,
    required this.dueDate,
    required this.status,
    required this.transactions,
  });

  factory PaymentInstallment.fromJson(Map<String, dynamic> json) {
    return PaymentInstallment(
      id: json['id'] ?? 0,
      admissionId: json['admissionId'] ?? 0,
      installmentName: json['installmentName']?.toString() ?? '',
      amountDue: json['amountDue']?.toString() ?? '0',
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'].toString())
          : DateTime.now(),
      status: (json['status'] ?? 'PENDING').toString().toUpperCase(),
      transactions: (json['transactions'] as List<dynamic>?)
          ?.map((t) => Transaction.fromJson(t as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admissionId': admissionId,
      'installmentName': installmentName,
      'amountDue': amountDue,
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
  }

  bool get isPaid => status == 'PAID';
  bool get isPending => status == 'PENDING';
  bool get isOverdue => isPending && dueDate.isBefore(DateTime.now());

  String get formattedDueDate => DateFormat('dd MMM yyyy').format(dueDate);
  String get formattedAmount => '₹${_formatCurrency(amountDue)}';

  String _formatCurrency(String amount) {
    final value = double.tryParse(amount) ?? 0;
    final formatter = NumberFormat('#,##,###');
    return formatter.format(value);
  }

  @override
  String toString() {
    return 'PaymentInstallment(id: $id, name: $installmentName, amount: $amountDue, status: $status)';
  }
}

class Transaction {
  final int id;
  final int installmentId;
  final String amountPaid;
  final DateTime paymentDate;
  final String paymentMethod;
  final String referenceNumber;
  final String status;
  final DateTime? realizedAt;
  final String? realizedByUserId;
  final int? paidByParentId;

  Transaction({
    required this.id,
    required this.installmentId,
    required this.amountPaid,
    required this.paymentDate,
    required this.paymentMethod,
    required this.referenceNumber,
    required this.status,
    this.realizedAt,
    this.realizedByUserId,
    this.paidByParentId,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? 0,
      installmentId: json['installmentId'] ?? 0,
      amountPaid: json['amountPaid']?.toString() ?? '0',
      paymentDate: json['paymentDate'] != null
          ? DateTime.parse(json['paymentDate'].toString())
          : DateTime.now(),
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      referenceNumber: json['referenceNumber']?.toString() ?? '',
      status: (json['status'] ?? 'PENDING').toString().toUpperCase(),
      realizedAt: json['realizedAt'] != null
          ? DateTime.parse(json['realizedAt'].toString())
          : null,
      realizedByUserId: json['realizedByUserId']?.toString(),
      paidByParentId: json['paidByParentId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'installmentId': installmentId,
      'amountPaid': amountPaid,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      'referenceNumber': referenceNumber,
      'status': status,
      'realizedAt': realizedAt?.toIso8601String(),
      'realizedByUserId': realizedByUserId,
      'paidByParentId': paidByParentId,
    };
  }

  String get formattedPaymentDate =>
      DateFormat('dd MMM yyyy').format(paymentDate);
  String get formattedAmount => '₹${_formatCurrency(amountPaid)}';

  String _formatCurrency(String amount) {
    final value = double.tryParse(amount) ?? 0;
    final formatter = NumberFormat('#,##,###');
    return formatter.format(value);
  }
}

class PaymentSummary {
  final List<PaymentInstallment> installments;
  final double totalFee;
  final double totalPaid;
  final double totalPending;
  final int paidCount;
  final int pendingCount;
  final PaymentInstallment? nextDue;

  PaymentSummary({
    required this.installments,
    required this.totalFee,
    required this.totalPaid,
    required this.totalPending,
    required this.paidCount,
    required this.pendingCount,
    this.nextDue,
  });

  factory PaymentSummary.fromInstallments(List<PaymentInstallment> installments) {
    double totalFee = 0;
    double totalPaid = 0;
    int paidCount = 0;
    int pendingCount = 0;

    for (var installment in installments) {
      final amount = double.tryParse(installment.amountDue) ?? 0;
      totalFee += amount;

      if (installment.isPaid) {
        totalPaid += amount;
        paidCount++;
      } else {
        pendingCount++;
      }
    }

    // Find next due installment
    final pendingInstallments = installments
        .where((i) => i.isPending)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return PaymentSummary(
      installments: installments,
      totalFee: totalFee,
      totalPaid: totalPaid,
      totalPending: totalFee - totalPaid,
      paidCount: paidCount,
      pendingCount: pendingCount,
      nextDue: pendingInstallments.isNotEmpty ? pendingInstallments.first : null,
    );
  }

  String get formattedTotalFee => '₹${_formatCurrency(totalFee)}';
  String get formattedTotalPaid => '₹${_formatCurrency(totalPaid)}';
  String get formattedTotalPending => '₹${_formatCurrency(totalPending)}';

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##,###');
    return formatter.format(amount);
  }

  double get paymentProgress {
    if (totalFee == 0) return 0;
    return (totalPaid / totalFee) * 100;
  }

  @override
  String toString() {
    return 'PaymentSummary(total: $formattedTotalFee, paid: $formattedTotalPaid, pending: $formattedTotalPending)';
  }
}