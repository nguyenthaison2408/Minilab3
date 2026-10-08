import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'analytics/analytics_screen.dart';
import 'home/home_screen.dart';
import 'scanner/camera_scanner_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CameraScannerScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primaryLight,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.cardSurface,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(
                  _currentIndex == 0 ? Icons.account_balance_wallet : Icons.account_balance_wallet_outlined,
                  color: _currentIndex == 0 ? AppColors.accent : AppColors.textSecondary,
                  size: 26,
                ),
                tooltip: 'Sổ chi tiêu',
                onPressed: () => setState(() => _currentIndex = 0),
              ),
              const SizedBox(width: 48), // Space for notched floating button
              IconButton(
                icon: Icon(
                  _currentIndex == 1 ? Icons.pie_chart : Icons.pie_chart_outline,
                  color: _currentIndex == 1 ? AppColors.accent : AppColors.textSecondary,
                  size: 26,
                ),
                tooltip: 'Thống kê',
                onPressed: () => setState(() => _currentIndex = 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

