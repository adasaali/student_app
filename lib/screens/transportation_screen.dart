import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/placeholder_screen.dart';

/// النقل — تُفتح من الشاشة الرئيسية.
/// TODO: اربط مع StudentProvider / ApiService لما يتوفر endpoint النقل.
class TransportationScreen extends StatelessWidget {
  const TransportationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionScaffold(
      title: 'النقل',
      body: PlaceholderContent(
        title: 'حافلة المدرسة',
        icon: Icons.directions_bus_filled_rounded,
        accentColor: AppColors.gold,
        subtitle: 'رح تظهر هون تفاصيل خط الحافلة، اسم السائق، ووقت الوصول المتوقع',
      ),
    );
  }
}
