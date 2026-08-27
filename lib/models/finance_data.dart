/// نموذج بيانات تبويبة "المالية" بتطبيق الطالب — مطابق لاستجابة
/// get_student_finance.php (قراءة من نفس نظام محاسبة المدرسة).
class FinanceItem {
  final String sourceKey; // registration | transport | other | ...
  final String itemName;
  final double amountUsd;
  final double amountSyp;
  final double paidUsd;
  final double paidSyp;
  final double remainingUsd;
  final double remainingSyp;
  final double discountUsd;
  final double discountSyp;
  final String? note;
  final bool isPaid;

  // خاص ببند النقل فقط
  final bool? isSubscribed;
  final bool? priceNotSet;

  FinanceItem({
    required this.sourceKey,
    required this.itemName,
    required this.amountUsd,
    required this.amountSyp,
    required this.paidUsd,
    required this.paidSyp,
    required this.remainingUsd,
    required this.remainingSyp,
    required this.discountUsd,
    required this.discountSyp,
    this.note,
    required this.isPaid,
    this.isSubscribed,
    this.priceNotSet,
  });

  bool get hasDiscount => discountUsd > 0 || discountSyp > 0;

  factory FinanceItem.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) => v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0);
    return FinanceItem(
      sourceKey: json['source_key'] ?? '',
      itemName: json['item_name'] ?? '',
      amountUsd: d(json['amount_usd']),
      amountSyp: d(json['amount_syp']),
      paidUsd: d(json['paid_usd']),
      paidSyp: d(json['paid_syp']),
      remainingUsd: d(json['remaining_usd']),
      remainingSyp: d(json['remaining_syp']),
      discountUsd: d(json['discount_usd']),
      discountSyp: d(json['discount_syp']),
      note: (json['note'] == null || json['note'] == '') ? null : json['note'],
      isPaid: json['is_paid'] == true,
      isSubscribed: json['is_subscribed'] as bool?,
      priceNotSet: json['price_not_set'] as bool?,
    );
  }
}

class FinanceTotals {
  final double totalUsd;
  final double totalSyp;
  final double paidUsd;
  final double paidSyp;
  final double remainingUsd;
  final double remainingSyp;
  final bool isComplete;

  FinanceTotals({
    required this.totalUsd,
    required this.totalSyp,
    required this.paidUsd,
    required this.paidSyp,
    required this.remainingUsd,
    required this.remainingSyp,
    required this.isComplete,
  });

  factory FinanceTotals.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) => v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0);
    return FinanceTotals(
      totalUsd: d(json['total_usd']),
      totalSyp: d(json['total_syp']),
      paidUsd: d(json['paid_usd']),
      paidSyp: d(json['paid_syp']),
      remainingUsd: d(json['remaining_usd']),
      remainingSyp: d(json['remaining_syp']),
      isComplete: json['is_complete'] == true,
    );
  }

  factory FinanceTotals.empty() => FinanceTotals(
        totalUsd: 0, totalSyp: 0, paidUsd: 0, paidSyp: 0, remainingUsd: 0, remainingSyp: 0, isComplete: true,
      );
}

class FinancePayment {
  final String? receiptNo;
  final String type; // payment | advance | advance_usage | advance_refund | refund
  final String typeLabel;
  final String? method;
  final String methodLabel;
  final double amount;
  final String currencyCode;
  final double amountSyp;
  final double amountUsd;
  final String? itemName;
  final String? note;
  final DateTime? paymentDate;
  final DateTime? createdAt;

  FinancePayment({
    this.receiptNo,
    required this.type,
    required this.typeLabel,
    this.method,
    required this.methodLabel,
    required this.amount,
    required this.currencyCode,
    required this.amountSyp,
    required this.amountUsd,
    this.itemName,
    this.note,
    this.paymentDate,
    this.createdAt,
  });

  bool get isRefundLike => type == 'refund' || type == 'advance_refund';

  factory FinancePayment.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) => v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0);
    return FinancePayment(
      receiptNo: json['receipt_no'],
      type: json['type'] ?? '',
      typeLabel: json['type_label'] ?? '',
      method: json['method'],
      methodLabel: json['method_label'] ?? 'أخرى',
      amount: d(json['amount']),
      currencyCode: json['currency_code'] ?? 'SYP',
      amountSyp: d(json['amount_syp']),
      amountUsd: d(json['amount_usd']),
      itemName: json['item_name'],
      note: (json['note'] == null || json['note'] == '') ? null : json['note'],
      paymentDate: json['payment_date'] != null ? DateTime.tryParse(json['payment_date']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}

class FinanceAdvance {
  final double usd;
  final double syp;

  FinanceAdvance({required this.usd, required this.syp});

  bool get hasBalance => usd > 0.009 || syp > 0.9;

  factory FinanceAdvance.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) => v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0);
    return FinanceAdvance(usd: d(json['usd']), syp: d(json['syp']));
  }

  factory FinanceAdvance.empty() => FinanceAdvance(usd: 0, syp: 0);
}

class FinanceData {
  final bool hasRecord;
  final String? message;
  final int? yearId;
  final String? yearName;
  final String? gradeName;
  final bool isSynced;
  final FinanceItem? tuition;
  final FinanceItem? transport;
  final List<FinanceItem> items;
  final FinanceTotals totals;
  final FinanceAdvance advance;
  final List<FinancePayment> payments;

  FinanceData({
    required this.hasRecord,
    this.message,
    this.yearId,
    this.yearName,
    this.gradeName,
    required this.isSynced,
    this.tuition,
    this.transport,
    required this.items,
    required this.totals,
    required this.advance,
    required this.payments,
  });

  factory FinanceData.fromJson(Map<String, dynamic> json) {
    if (json['has_record'] != true) {
      return FinanceData(
        hasRecord: false,
        message: json['message'],
        isSynced: false,
        items: const [],
        totals: FinanceTotals.empty(),
        advance: FinanceAdvance.empty(),
        payments: const [],
      );
    }

    return FinanceData(
      hasRecord: true,
      yearId: json['year_id'] is int ? json['year_id'] : int.tryParse('${json['year_id']}'),
      yearName: json['year_name'],
      gradeName: json['grade_name'],
      isSynced: json['is_synced'] == true,
      tuition: json['tuition'] is Map ? FinanceItem.fromJson((json['tuition'] as Map).cast<String, dynamic>()) : null,
      transport: json['transport'] is Map ? FinanceItem.fromJson((json['transport'] as Map).cast<String, dynamic>()) : null,
      items: (json['items'] as List? ?? [])
          .map((e) => FinanceItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      totals: json['totals'] is Map
          ? FinanceTotals.fromJson((json['totals'] as Map).cast<String, dynamic>())
          : FinanceTotals.empty(),
      advance: json['advance'] is Map
          ? FinanceAdvance.fromJson((json['advance'] as Map).cast<String, dynamic>())
          : FinanceAdvance.empty(),
      payments: (json['payments'] as List? ?? [])
          .map((e) => FinancePayment.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  factory FinanceData.empty() => FinanceData(
        hasRecord: false,
        isSynced: false,
        items: const [],
        totals: FinanceTotals.empty(),
        advance: FinanceAdvance.empty(),
        payments: const [],
      );
}
