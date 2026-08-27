import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import '../models/student_model.dart';
import '../theme/app_colors.dart';

/// كانت هذه الشاشة "قريباً..." فقط رغم أن StudentProvider وApiService
/// يدعمان بالفعل جلب قائمة الطلاب كاملة (fetchAllStudents). تم تفعيلها.
class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<StudentProvider>();
      if (provider.allStudents.isEmpty && !provider.isLoading) {
        provider.fetchAllStudents();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StudentProvider>(context);
    final all = provider.allStudents;
    final filtered = _query.isEmpty
        ? all
        : all.where((s) => s.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text(
                  'قائمة الطلاب',
                  style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  style: GoogleFonts.cairo(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن طالب...',
                    hintStyle: GoogleFonts.cairo(color: AppColors.gray400, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppColors.gray400),
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.gray200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.gray200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildBody(provider, filtered)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(StudentProvider provider, List<StudentModel> filtered) {
    if (provider.isLoading && provider.allStudents.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }

    if (provider.error != null && provider.allStudents.isEmpty) {
      return _buildMessage(
        icon: Icons.cloud_off_rounded,
        title: 'تعذر تحميل القائمة',
        subtitle: provider.error!,
        onRetry: () => provider.fetchAllStudents(),
      );
    }

    if (filtered.isEmpty) {
      return _buildMessage(
        icon: Icons.people_outline,
        title: 'لا يوجد طلاب',
        subtitle: _query.isEmpty ? 'لم يتم العثور على أي طالب بعد' : 'لا نتائج مطابقة لبحثك',
        onRetry: null,
      );
    }

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: () => provider.fetchAllStudents(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _StudentTile(student: filtered[i]),
      ),
    );
  }

  Widget _buildMessage({required IconData icon, required String title, required String subtitle, VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.gray400),
            const SizedBox(height: 16),
            Text(title, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 13, color: AppColors.gray500)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onRetry, child: Text('إعادة المحاولة', style: GoogleFonts.cairo(color: AppColors.gold))),
            ],
          ],
        ),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final StudentModel student;
  const _StudentTile({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.navy, AppColors.navyLight]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name.isNotEmpty ? student.name : '-',
                    style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
                const SizedBox(height: 2),
                Text('الصف ${student.className.isNotEmpty ? student.className : '-'}',
                    style: GoogleFonts.cairo(fontSize: 12, color: AppColors.gray500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
