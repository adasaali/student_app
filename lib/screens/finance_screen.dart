import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/sibling_palette.dart';
import '../widgets/placeholder_screen.dart';
import '../providers/student_provider.dart';
import '../models/finance_data.dart';

/// المالية — تُفتح من قائمة الدرج (Drawer).
/// بتعرض: مبلغ الأقساط والخدمات، مبلغ النقل (أو "لم يحدد سعر النقل بعد")،
/// الإجمالي، المبلغ المتبقي، رصيد السلفة، وسجل الدفعات كامل.
class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  static const _months = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().fetchFinance();
    });
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '-';
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  String _fmtSyp(double v) {
    final s = v.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '$buf ل.س';
  }

  String _fmtUsd(double v) => '\$${v.toStringAsFixed(2)}';

  Map<String, Color> _palette(String name, {String? gender, int? studentId}) {
    final p = SiblingPalette.forStudent(name, gender: gender, studentId: studentId);
    return {'primary': p.primaryDark, 'light': p.primaryLight ?? p.primaryDark.withOpacity(0.8), 'gold': p.goldMain};
  }

  @override
  Widget build(BuildContext context) {
    final activeStudent = context.watch<StudentProvider>().student;
    final palette = _palette(activeStudent?.studentName ?? '', gender: activeStudent?.gender, studentId: activeStudent?.studentId);
    final primary = palette['primary']!;
    final light = palette['light']!;

    return SectionScaffold(
      title: 'المالية',
      body: Consumer<StudentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingFinance && !provider.finance.hasRecord) {
            return Center(child: CircularProgressIndicator(color: primary));
          }

          final finance = provider.finance;

          if (!finance.hasRecord) {
            if (provider.financeError != null) {
              return RefreshIndicator(
                color: primary,
                onRefresh: () => provider.fetchFinance(),
                child: ListView(
                  children: [
                    const SizedBox(height: 60),
                    PlaceholderContent(
                      title: 'تعذّر تحميل البيانات المالية',
                      icon: Icons.wifi_off_rounded,
                      accentColor: AppColors.red,
                      subtitle: provider.financeError!,
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              color: primary,
              onRefresh: () => provider.fetchFinance(),
              child: ListView(
                children: [
                  const SizedBox(height: 60),
                  PlaceholderContent(
                    title: 'ما في سجل مالي بعد',
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: primary,
                    subtitle: finance.message ?? 'لسا ما تم تجهيز الحالة المالية لهالطالب',
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: primary,
            onRefresh: () => provider.fetchFinance(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (finance.yearName != null || finance.gradeName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (finance.gradeName != null) _MetaChip(text: finance.gradeName!, color: primary),
                        if (finance.yearName != null) _MetaChip(text: 'العام ${finance.yearName!}', color: primary),
                      ],
                    ),
                  ),

                _TotalsCard(totals: finance.totals, fmtSyp: _fmtSyp, fmtUsd: _fmtUsd, primary: primary, light: light),

                const SizedBox(height: 16),

                if (finance.advance.hasBalance) ...[
                  _AdvanceCard(advance: finance.advance, fmtSyp: _fmtSyp, fmtUsd: _fmtUsd),
                  const SizedBox(height: 16),
                ],

                Text(
                  'تفاصيل الرسوم',
                  style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navy),
                ),
                const SizedBox(height: 12),

                if (finance.tuition != null)
                  _ItemCard(
                    item: finance.tuition!,
                    icon: Icons.school_rounded,
                    fmtSyp: _fmtSyp,
                    fmtUsd: _fmtUsd,
                  ),

                if (finance.transport != null) ...[
                  const SizedBox(height: 10),
                  _ItemCard(
                    item: finance.transport!,
                    icon: Icons.directions_bus_filled_rounded,
                    fmtSyp: _fmtSyp,
                    fmtUsd: _fmtUsd,
                  ),
                ],

                ...finance.items
                    .where((i) => i.sourceKey != 'registration' && i.sourceKey != 'transport')
                    .map((i) => Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: _ItemCard(item: i, icon: Icons.receipt_long_rounded, fmtSyp: _fmtSyp, fmtUsd: _fmtUsd),
                        )),

                const SizedBox(height: 24),

                Text(
                  'سجل الدفعات',
                  style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navy),
                ),
                const SizedBox(height: 12),

                if (finance.payments.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gray200),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long_outlined, color: AppColors.gray400, size: 32),
                        const SizedBox(height: 8),
                        Text('لسا ما في أي دفعة مسجّلة', style: GoogleFonts.cairo(fontSize: 13, color: AppColors.gray500)),
                      ],
                    ),
                  )
                else
                  ...finance.payments.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PaymentCard(payment: p, dateLabel: _formatDate(p.paymentDate ?? p.createdAt)),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String text;
  final Color color;
  const _MetaChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final FinanceTotals totals;
  final String Function(double) fmtSyp;
  final String Function(double) fmtUsd;
  final Color primary;
  final Color light;

  const _TotalsCard({required this.totals, required this.fmtSyp, required this.fmtUsd, required this.primary, required this.light});

  @override
  Widget build(BuildContext context) {
    final complete = totals.isComplete;
    final accent = complete ? AppColors.green : AppColors.gold;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [primary, light],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: primary.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(complete ? Icons.verified_rounded : Icons.account_balance_wallet_rounded, color: accent, size: 22),
              const SizedBox(width: 8),
              Text(
                complete ? 'الحساب مكتمل بالكامل' : 'الوضع المالي',
                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.white),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _totalsRow('الإجمالي', totals.totalSyp, totals.totalUsd, AppColors.white),
          const SizedBox(height: 12),
          _totalsRow('المدفوع', totals.paidSyp, totals.paidUsd, AppColors.goldLight),
          const Divider(color: Colors.white24, height: 26),
          _totalsRow('المتبقي', totals.remainingSyp, totals.remainingUsd, complete ? AppColors.green : AppColors.gold, big: true),
        ],
      ),
    );
  }

  Widget _totalsRow(String label, double syp, double usd, Color valueColor, {bool big = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: GoogleFonts.cairo(fontSize: big ? 14 : 12.5, color: Colors.white.withOpacity(0.75), fontWeight: FontWeight.w600)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(fmtSyp(syp), style: GoogleFonts.cairo(fontSize: big ? 20 : 14, fontWeight: FontWeight.w900, color: valueColor)),
            const SizedBox(height: 2),
            Text(fmtUsd(usd), style: GoogleFonts.cairo(fontSize: big ? 12.5 : 11, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.6))),
          ],
        ),
      ],
    );
  }
}

class _AdvanceCard extends StatelessWidget {
  final FinanceAdvance advance;
  final String Function(double) fmtSyp;
  final String Function(double) fmtUsd;

  const _AdvanceCard({required this.advance, required this.fmtSyp, required this.fmtUsd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.goldPale,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.16), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.savings_rounded, color: AppColors.gold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('رصيد السلفة', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.navy)),
                const SizedBox(height: 2),
                Text('مبلغ مسبق مدفوع، بينخصم تلقائياً من الرسوم القادمة',
                    style: GoogleFonts.cairo(fontSize: 11, color: AppColors.gray600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (advance.syp > 0.9) Text(fmtSyp(advance.syp), style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.navy)),
              if (advance.usd > 0.009) Text(fmtUsd(advance.usd), style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gray600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final FinanceItem item;
  final IconData icon;
  final String Function(double) fmtSyp;
  final String Function(double) fmtUsd;

  const _ItemCard({required this.item, required this.icon, required this.fmtSyp, required this.fmtUsd});

  @override
  Widget build(BuildContext context) {
    final notSet = item.priceNotSet == true;
    final notSubscribed = item.sourceKey == 'transport' && item.isSubscribed == false;

    Color accent;
    if (notSet || notSubscribed) {
      accent = AppColors.gray500;
    } else if (item.isPaid) {
      accent = AppColors.green;
    } else {
      accent = AppColors.gold;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.itemName, style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.navy)),
                    if (item.hasDiscount) ...[
                      const SizedBox(height: 3),
                      Text('فيه خصم مطبّق على هالبند', style: GoogleFonts.cairo(fontSize: 11, color: AppColors.green, fontWeight: FontWeight.w600)),
                    ],
                    if (item.note != null) ...[
                      const SizedBox(height: 3),
                      Text(item.note!, style: GoogleFonts.cairo(fontSize: 11, color: AppColors.gray500)),
                    ],
                  ],
                ),
              ),
              if (!notSet && !notSubscribed)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(fmtSyp(item.amountSyp), style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.navy)),
                    Text(fmtUsd(item.amountUsd), style: GoogleFonts.cairo(fontSize: 11, color: AppColors.gray500)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (notSubscribed)
            const _StatusPill(text: 'غير مشترك بالنقل', color: AppColors.gray500)
          else if (notSet)
            const _StatusPill(text: 'لم يحدد سعر النقل بعد', color: AppColors.gold)
          else if (item.isPaid)
            const _StatusPill(text: 'مسدد بالكامل', color: AppColors.green)
          else
            Row(
              children: [
                Expanded(
                  child: _miniStat('المدفوع', fmtSyp(item.paidSyp), AppColors.green),
                ),
                Container(width: 1, height: 28, color: AppColors.gray200, margin: const EdgeInsets.symmetric(horizontal: 10)),
                Expanded(
                  child: _miniStat('المتبقي', fmtSyp(item.remainingSyp), AppColors.red),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.cairo(fontSize: 10.5, color: AppColors.gray500, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final FinancePayment payment;
  final String dateLabel;

  const _PaymentCard({required this.payment, required this.dateLabel});

  IconData get _icon {
    switch (payment.type) {
      case 'advance':
        return Icons.savings_rounded;
      case 'advance_usage':
        return Icons.remove_circle_rounded;
      case 'advance_refund':
      case 'refund':
        return Icons.replay_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  Color get _color {
    if (payment.isRefundLike) return AppColors.red;
    if (payment.type == 'advance') return AppColors.gold;
    return AppColors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: _color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(_icon, color: _color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.typeLabel, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.navy)),
                const SizedBox(height: 2),
                Text(
                  [
                    if (payment.itemName != null) payment.itemName!,
                    payment.methodLabel,
                    dateLabel,
                  ].join(' · '),
                  style: GoogleFonts.cairo(fontSize: 11, color: AppColors.gray500),
                ),
                if (payment.note != null) ...[
                  const SizedBox(height: 3),
                  Text(payment.note!, style: GoogleFonts.cairo(fontSize: 11, color: AppColors.gray500)),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${payment.isRefundLike ? '-' : '+'}${payment.currencyCode == 'USD' ? '\$${payment.amount.toStringAsFixed(2)}' : '${payment.amount.round()} ل.س'}',
                style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.w900, color: _color),
              ),
              if (payment.receiptNo != null) ...[
                const SizedBox(height: 2),
                Text('#${payment.receiptNo}', style: GoogleFonts.cairo(fontSize: 10, color: AppColors.gray400)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
