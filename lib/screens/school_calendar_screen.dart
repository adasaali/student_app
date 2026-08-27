import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/calendar_event.dart';
import '../providers/student_provider.dart';
import '../theme/app_colors.dart';
import '../theme/sibling_palette.dart';

/// التقويم المدرسي — مربوط فعلياً بـ StudentProvider.fetchCalendarEvents()
/// (get_calendar_events.php)، يلي بيرجّع نفس الأحداث يلي بيديرها الأدمن من
/// admin/calendar/school_calendar.php. ما عاد في بيانات ثابتة بالشاشة.
class SchoolCalendarScreen extends StatefulWidget {
  const SchoolCalendarScreen({super.key});

  @override
  State<SchoolCalendarScreen> createState() => _SchoolCalendarScreenState();
}

class _SchoolCalendarScreenState extends State<SchoolCalendarScreen> {
  late DateTime _visibleMonth;
  DateTime? _selectedDay;

  static const _months = [
    'كانون الثاني', 'شباط', 'آذار', 'نيسان', 'أيار', 'حزيران',
    'تموز', 'آب', 'أيلول', 'تشرين الأول', 'تشرين الثاني', 'كانون الأول',
  ];

  static const _weekDays = ['أحد', 'إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month, 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().fetchCalendarEvents();
    });
  }

  Future<void> _reload() => context.read<StudentProvider>().fetchCalendarEvents();

  bool _isWeekend(DateTime date) => date.weekday == DateTime.friday || date.weekday == DateTime.saturday;

  Map<String, Color> _palette(String name, {String? gender, int? studentId}) {
    final p = SiblingPalette.forStudent(name, gender: gender, studentId: studentId);
    return {
      'primary': p.primaryDark,
      'light': p.primaryLight,
      'gold': p.goldMain,
    };
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
      _selectedDay = null;
    });
  }

  List<CalendarEvent> _monthEvents(List<CalendarEvent> all) {
    final events = all.where((e) => e.overlapsMonth(_visibleMonth)).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return events;
  }

  List<CalendarEvent> _visibleEvents(List<CalendarEvent> monthEvents) {
    if (_selectedDay == null) return monthEvents;
    return monthEvents.where((e) => e.includesDay(_selectedDay!)).toList();
  }

  /// لون اليوم إذا وقع ضمن حدث (يُتجاهَل خلال عطلة نهاية الأسبوع لأنّها
  /// تُلوَّن دائمًا باللون الرمادي، تمامًا كما في التقويم الرسمي).
  Color? _eventColorForDay(List<CalendarEvent> all, DateTime date) {
    if (_isWeekend(date)) return null;
    for (final e in all) {
      if (e.includesDay(date)) return e.color;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final activeStudent = context.watch<StudentProvider>().student;
    final studentName = activeStudent?.studentName ?? '';
    final palette = _palette(studentName, gender: activeStudent?.gender, studentId: activeStudent?.studentId);
    final primary = palette['primary']!;
    final light = palette['light']!;
    final gold = palette['gold']!;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        body: Consumer<StudentProvider>(
          builder: (context, provider, _) {
            final allEvents = provider.calendarEvents;
            final isLoading = provider.isLoadingCalendarEvents;
            final error = provider.calendarEventsError;

            if (isLoading && allEvents.isEmpty) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(primary, light, gold)),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator(color: gold)),
                  ),
                ],
              );
            }

            if (error != null && allEvents.isEmpty) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(primary, light, gold)),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.gray400),
                            const SizedBox(height: 16),
                            Text('تعذر تحميل التقويم المدرسي',
                                style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800, color: primary)),
                            const SizedBox(height: 6),
                            Text(error, textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 13, color: AppColors.gray500)),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: _reload,
                              icon: Icon(Icons.refresh_rounded, color: gold, size: 18),
                              label: Text('إعادة المحاولة', style: GoogleFonts.cairo(color: gold, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            final monthEvents = _monthEvents(allEvents);
            final visibleEvents = _visibleEvents(monthEvents);

            return RefreshIndicator(
              color: gold,
              onRefresh: _reload,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(primary, light, gold)),
                  SliverToBoxAdapter(child: _buildLegend()),
                  SliverToBoxAdapter(child: _buildCalendarGrid(primary, gold, allEvents)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: Row(
                        children: [
                          Container(
                            width: 4, height: 18,
                            decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(4)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedDay == null ? 'أحداث الشهر' : 'أحداث يوم ${_selectedDay!.day} ${_months[_selectedDay!.month - 1]}',
                            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
                          ),
                          const Spacer(),
                          if (_selectedDay != null)
                            TextButton(
                              onPressed: () => setState(() => _selectedDay = null),
                              child: Text('عرض الكل', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w700, color: primary)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  visibleEvents.isEmpty
                      ? SliverToBoxAdapter(child: _buildEmptyState(primary))
                      : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final event = visibleEvents[index];
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 350 + index * 60),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) => Opacity(
                              opacity: value,
                              child: Transform.translate(offset: Offset(0, (1 - value) * 16), child: child),
                            ),
                            child: _buildEventCard(event),
                          );
                        },
                        childCount: visibleEvents.length,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(Color primary, Color light, Color gold) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [primary, light]),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
        boxShadow: [BoxShadow(color: primary.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(top: -30, left: -20, child: _decorCircle(110, gold.withOpacity(0.08))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _GlassBackButton(onTap: () => Navigator.of(context).pop()),
                    const Spacer(),
                    Text('التقويم المدرسي', style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                    const Spacer(),
                    const SizedBox(width: 42),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _MonthNavButton(icon: Icons.chevron_right_rounded, onTap: () => _changeMonth(1)),
                    Column(
                      children: [
                        Text(
                          '${_months[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                          style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ],
                    ),
                    _MonthNavButton(icon: Icons.chevron_left_rounded, onTap: () => _changeMonth(-1)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    final items = <(CalendarEventType, String)>[
      (CalendarEventType.examPeriod, 'أيام الامتحانات'),
      (CalendarEventType.midYearBreak, 'العطلة الانتصافية'),
      (CalendarEventType.studentStart, 'بدء دوام الطلاب'),
      (CalendarEventType.teacherStart, 'بدء الدوام التدريسي'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 8,
        children: items.map((item) {
          final dummy = CalendarEvent(id: 0, title: '', startDate: DateTime.now(), type: item.$1);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 11, height: 11, decoration: BoxDecoration(color: dummy.color, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 6),
              Text(item.$2, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF475569))),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(Color primary, Color gold, List<CalendarEvent> allEvents) {
    final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leadingEmpty = firstDay.weekday % 7; // 0=أحد
    final today = DateTime.now();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: primary.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Row(
            children: _weekDays.map((d) => Expanded(
              child: Center(child: Text(d, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray400))),
            )).toList(),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingEmpty + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemBuilder: (context, index) {
              if (index < leadingEmpty) return const SizedBox.shrink();
              final day = index - leadingEmpty + 1;
              final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
              final isToday = today.year == date.year && today.month == date.month && today.day == date.day;
              final isSelected = _selectedDay != null && _selectedDay!.year == date.year && _selectedDay!.month == date.month && _selectedDay!.day == date.day;
              final isWeekend = _isWeekend(date);
              final eventColor = _eventColorForDay(allEvents, date);

              Color background;
              if (isSelected) {
                background = primary;
              } else if (eventColor != null) {
                background = eventColor.withOpacity(0.22);
              } else if (isToday) {
                background = primary.withOpacity(0.1);
              } else if (isWeekend) {
                background = const Color(0xFFEEF1F5);
              } else {
                background = Colors.transparent;
              }

              Color textColor;
              if (isSelected) {
                textColor = Colors.white;
              } else if (isToday) {
                textColor = primary;
              } else if (isWeekend) {
                textColor = const Color(0xFF94A3B8);
              } else {
                textColor = const Color(0xFF334155);
              }

              return GestureDetector(
                onTap: () => setState(() => _selectedDay = isSelected ? null : date),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: background),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$day',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: (isToday || isSelected) ? FontWeight.w800 : FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        if (eventColor != null)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 4, height: 4,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? Colors.white : eventColor),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: event.color.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: event.color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(event.icon, color: event.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: event.color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                      child: Text(event.typeLabel, style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w700, color: event.color)),
                    ),
                    const Spacer(),
                    Text(_formatEventDateRange(event), style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.gray400)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(event.title, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
                if (event.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(event.subtitle!, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.gray400)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatEventDateRange(CalendarEvent event) {
    final start = event.startDate;
    final end = event.endDate;
    if (end == null || (end.year == start.year && end.month == start.month && end.day == start.day)) {
      return '${start.day} ${_months[start.month - 1]}';
    }
    if (start.month == end.month && start.year == end.year) {
      return '${start.day} - ${end.day} ${_months[start.month - 1]}';
    }
    return '${start.day} ${_months[start.month - 1]} - ${end.day} ${_months[end.month - 1]}';
  }

  Widget _buildEmptyState(Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.event_available_rounded, size: 56, color: primary.withOpacity(0.25)),
          const SizedBox(height: 12),
          Text('لا يوجد أحداث', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gray400)),
        ],
      ),
    );
  }

  Widget _decorCircle(double size, Color color) =>
      Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

class _GlassBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GlassBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MonthNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
