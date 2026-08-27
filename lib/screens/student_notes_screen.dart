import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/behavior_note.dart';
import '../providers/student_provider.dart';
import '../theme/app_colors.dart';
import '../theme/sibling_palette.dart';

/// ملاحظات الطالب — تبويب بالشريط السفلي.
/// بتعرض الملاحظات (إيجابية / سلبية) اللي أضافها المشرف عن الطالب من
/// تطبيق المشرف (خاصية "الملاحظات") — عبر StudentProvider.fetchBehaviorNotes()
/// و ApiService.fetchBehaviorNotes() (get_student_notes.php).
class StudentNotesScreen extends StatefulWidget {
  const StudentNotesScreen({super.key});

  @override
  State<StudentNotesScreen> createState() => _StudentNotesScreenState();
}

class _StudentNotesScreenState extends State<StudentNotesScreen> {
  static const _months = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  String _filter = 'all'; // all | positive | negative

  // 🔧 نفس الحل المعتمد بـ WeeklyScheduleScreen بالضبط: initState()
  // القديم كان بيجيب الملاحظات مرة وحدة بس (أول ما تنفتح الشاشة)، فلما
  // نبدّل لأخ من شريط تبديل الحسابات وإحنا واقفين على تبويب الملاحظات،
  // ما كانت تتحدّث فوراً — لأن initState ما بيعاد استدعاؤه أبداً طول
  // عمر الشاشة (تبويبات الشريط السفلي بتضل حيّة بالذاكرة، ما بتنبني من
  // جديد). هلق منراقب activeStudentId عبر didChangeDependencies ومنعيد
  // الجلب تلقائياً كل ما يتغيّر (تبديل حساب) — تحديث فوري بدل ما ينتظر
  // المستخدم يسحب لتحديث يدوي أو يطلع ويرجع عالتبويب.
  int? _loadedForStudentId;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activeId = context.watch<StudentProvider>().activeStudentId;
    if (!_initialized || _loadedForStudentId != activeId) {
      _initialized = true;
      _loadedForStudentId = activeId;
      // بتمر من StudentProvider (مش ApiService مباشرة) عشان تضمن إن
      // التوكن معبّى قبل الطلب — نفس ملاحظة WeeklyScheduleScreen.
      context.read<StudentProvider>().fetchBehaviorNotes();
    }
  }

  String _formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  Map<String, Color> _palette(String name, {String? gender, int? studentId}) {
    final p = SiblingPalette.forStudent(name, gender: gender, studentId: studentId);
    return {'primary': p.primaryDark, 'light': p.primaryLight ?? p.primaryDark.withOpacity(0.8), 'gold': p.goldMain};
  }

  List<BehaviorNote> _filtered(List<BehaviorNote> notes) {
    if (_filter == 'all') return notes;
    return notes.where((n) => n.noteType == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final activeStudent = context.watch<StudentProvider>().student;
    final palette = _palette(activeStudent?.studentName ?? '', gender: activeStudent?.gender, studentId: activeStudent?.studentId);
    final primary = palette['primary']!;

    return Consumer<StudentProvider>(
      builder: (context, provider, _) {
        final notes = provider.behaviorNotes;

        if (provider.isLoadingBehaviorNotes && notes.isEmpty) {
          return Center(child: CircularProgressIndicator(color: primary));
        }

        if (provider.behaviorNotesError != null && notes.isEmpty) {
          return _ErrorView(
            message: provider.behaviorNotesError!,
            onRetry: () => provider.fetchBehaviorNotes(),
          );
        }

        final filtered = _filtered(notes);

        return RefreshIndicator(
          color: primary,
          onRefresh: () => provider.fetchBehaviorNotes(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              Text(
                'ملاحظات المدرّسين والإدارة',
                style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: primary),
              ),
              const SizedBox(height: 14),
              _StatsRow(
                stats: provider.behaviorNoteStats,
                filter: _filter,
                onSelect: (f) => setState(() => _filter = _filter == f ? 'all' : f),
              ),
              const SizedBox(height: 18),
              if (notes.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: _EmptyNotes(primary: primary),
                )
              else if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      'ما في ملاحظات من هالنوع',
                      style: GoogleFonts.cairo(fontSize: 13.5, color: AppColors.gray500, fontWeight: FontWeight.w600),
                    ),
                  ),
                )
              else
                ...filtered.map((n) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _NoteCard(note: n, dateLabel: _formatDate(n.createdAt)),
                    )),
            ],
          ),
        );
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  final BehaviorNoteStats stats;
  final String filter;
  final ValueChanged<String> onSelect;

  const _StatsRow({required this.stats, required this.filter, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'إيجابية',
            value: '${stats.positiveCount}',
            icon: Icons.thumb_up_alt_rounded,
            color: AppColors.green,
            selected: filter == 'positive',
            onTap: () => onSelect('positive'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'سلبية',
            value: '${stats.negativeCount}',
            icon: Icons.thumb_down_alt_rounded,
            color: AppColors.red,
            selected: filter == 'negative',
            onTap: () => onSelect('negative'),
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
  final bool selected;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? color : color.withOpacity(0.18), width: selected ? 1.6 : 1),
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
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final BehaviorNote note;
  final String dateLabel;

  const _NoteCard({required this.note, required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    final color = note.isPositive ? AppColors.green : AppColors.red;
    final icon = note.isPositive ? Icons.thumb_up_alt_rounded : Icons.thumb_down_alt_rounded;

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
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                dateLabel,
                                style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.navy),
                              ),
                              if (note.subjectName != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.navy.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    note.subjectName!,
                                    style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.navy),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            note.noteText,
                            style: GoogleFonts.cairo(fontSize: 13, color: AppColors.gray700, height: 1.5, fontWeight: FontWeight.w600),
                          ),
                          if (note.createdByName != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              note.createdByName!,
                              style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.gray400, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
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

class _EmptyNotes extends StatelessWidget {
  final Color primary;
  const _EmptyNotes({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(Icons.note_alt_rounded, color: primary, size: 42),
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد ملاحظات بعد',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: primary),
            ),
            const SizedBox(height: 8),
            Text(
              'رح تظهر هون ملاحظات المدرّسين والإدارة عن الطالب أول ما تنضاف',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.gray500, fontWeight: FontWeight.w600, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 13.5, color: AppColors.gray600, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
              child: Text('إعادة المحاولة', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
