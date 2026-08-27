import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../widgets/placeholder_screen.dart';
import '../providers/student_provider.dart';
import '../models/absence_record.dart';

/// الغياب — تُفتح من قائمة الدرج (Drawer).
class AbsenceScreen extends StatefulWidget {
  const AbsenceScreen({super.key});

  @override
  State<AbsenceScreen> createState() => _AbsenceScreenState();
}

class _AbsenceScreenState extends State<AbsenceScreen> {
  static const _weekdays = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
  static const _months = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().fetchAbsences();
    });
  }

  String _formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';
  String _weekday(DateTime d) => _weekdays[d.weekday - 1];

  @override
  Widget build(BuildContext context) {
    return SectionScaffold(
      title: 'الغياب',
      body: Consumer<StudentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingAbsences && provider.absences.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.gold));
          }

          final absentOnly = provider.absences.where((a) => a.isAbsent).toList();

          if (absentOnly.isEmpty) {
            return RefreshIndicator(
              color: AppColors.green,
              onRefresh: () => provider.fetchAbsences(),
              child: ListView(
                children: const [
                  SizedBox(height: 60),
                  PlaceholderContent(
                    title: 'سجلّك نظيف! 🎉',
                    icon: Icons.verified_rounded,
                    accentColor: AppColors.green,
                    subtitle: 'ما في أي غياب مسجّل عليك لهلق، استمر هيك!',
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.gold,
            onRefresh: () => provider.fetchAbsences(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatsRow(stats: provider.absenceStats),
                const SizedBox(height: 20),
                Text(
                  'سجل الغياب',
                  style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navy),
                ),
                const SizedBox(height: 12),
                ...absentOnly.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AbsenceCard(
                    record: a,
                    dateLabel: _formatDate(a.date),
                    weekdayLabel: _weekday(a.date),
                  ),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final AbsenceStats stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'هالشهر',
            value: '${stats.thisMonthAbsences}',
            icon: Icons.calendar_month_rounded,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'إجمالي الغياب',
            value: '${stats.totalAbsences}',
            icon: Icons.event_busy_rounded,
            color: AppColors.red,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.navy)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.gray600, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _AbsenceCard extends StatelessWidget {
  final AbsenceRecord record;
  final String dateLabel;
  final String weekdayLabel;

  const _AbsenceCard({required this.record, required this.dateLabel, required this.weekdayLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: const BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.event_busy_rounded, color: AppColors.red, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateLabel,
                            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.navy),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            weekdayLabel,
                            style: GoogleFonts.cairo(fontSize: 12, color: AppColors.gray500, fontWeight: FontWeight.w600),
                          ),
                          if (record.reason != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.goldPale,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                record.reason!,
                                style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.gold, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'غائب',
                        style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
