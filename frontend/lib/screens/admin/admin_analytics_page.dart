/// Admin Analytics Page
/// 
/// Provides analytics and statistics dashboard.
library;

import 'package:flutter/material.dart';
import '../../core/constants/app_color.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  String _selectedPeriod = 'Last 30 Days';
  final List<String> _periods = ['Last 7 Days', 'Last 30 Days', 'Last 90 Days', 'Last Year'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColorsDark.backgroundPrimary
          : AppColorsLight.backgroundPrimary,
      body: Column(
        children: [
          _buildHeader(isDark),
          Expanded(
            child: _buildContent(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundSecondary
            : AppColorsLight.backgroundTertiary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Analytics Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColorsDark.textWhite
                  : AppColorsLight.textBlack,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColorsDark.backgroundTertiary
                  : AppColorsLight.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: _selectedPeriod,
              items: _periods.map((period) {
                return DropdownMenuItem(
                  value: period,
                  child: Text(period),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value!;
                });
              },
              underline: Container(),
              style: TextStyle(
                color: isDark
                    ? AppColorsDark.textWhite
                    : AppColorsLight.textBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKeyMetrics(isDark),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildChartCard('User Growth', isDark),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildTopUsers(isDark),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: _buildTopBuilds(isDark),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildActivityChart(isDark),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetrics(bool isDark) {
    final metrics = [
      {'label': 'Total Users', 'value': '1,234', 'change': '+12%', 'icon': Icons.people, 'color': AppColorsDark.buttonBlue},
      {'label': 'Active Users', 'value': '856', 'change': '+8%', 'icon': Icons.person, 'color': AppColorsDark.buttonGreen},
      {'label': 'New Builds', 'value': '234', 'change': '+15%', 'icon': Icons.computer, 'color': AppColorsDark.buttonPurple},
      {'label': 'Forum Posts', 'value': '567', 'change': '+23%', 'icon': Icons.forum, 'color': AppColorsDark.warning},
    ];

    return Row(
      children: metrics.map((metric) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColorsDark.backgroundSecondary
                  : AppColorsLight.backgroundTertiary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (metric['color'] as Color).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        metric['icon'] as IconData,
                        color: metric['color'] as Color,
                        size: 20,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColorsDark.buttonGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        metric['change'] as String,
                        style: const TextStyle(
                          color: AppColorsDark.buttonGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  metric['value'] as String,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColorsDark.textWhite
                        : AppColorsLight.textBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metric['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColorsDark.textWhite.withOpacity(0.7)
                        : AppColorsLight.textBlack.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChartCard(String title, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundSecondary
            : AppColorsLight.backgroundTertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColorsDark.textWhite
                  : AppColorsLight.textBlack,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColorsDark.buttonBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 48,
                    color: AppColorsDark.buttonBlue.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chart Visualization',
                    style: TextStyle(
                      color: isDark
                          ? AppColorsDark.textWhite.withOpacity(0.5)
                          : AppColorsLight.textBlack.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopUsers(bool isDark) {
    final topUsers = List.generate(5, (index) => {
      'name': 'User ${index + 1}',
      'builds': (index + 1) * 5,
    });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundSecondary
            : AppColorsLight.backgroundTertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Users',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColorsDark.textWhite
                  : AppColorsLight.textBlack,
            ),
          ),
          const SizedBox(height: 16),
          ...topUsers.map((user) {
            final userName = user['name'] as String;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColorsDark.buttonBlue,
                    child: Text(
                      userName.isNotEmpty ? userName[userName.length - 1] : 'U',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      userName,
                      style: TextStyle(
                        color: isDark
                            ? AppColorsDark.textWhite
                            : AppColorsLight.textBlack,
                      ),
                    ),
                  ),
                  Text(
                    '${user['builds'] as int} builds',
                    style: TextStyle(
                      color: isDark
                          ? AppColorsDark.textWhite.withOpacity(0.7)
                          : AppColorsLight.textBlack.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTopBuilds(bool isDark) {
    final topBuilds = List.generate(5, (index) => {
      'name': 'Build ${index + 1}',
      'views': (index + 1) * 100,
    });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundSecondary
            : AppColorsLight.backgroundTertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Builds',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColorsDark.textWhite
                  : AppColorsLight.textBlack,
            ),
          ),
          const SizedBox(height: 16),
          ...topBuilds.map((build) {
            final buildName = build['name'] as String;
            final buildViews = build['views'] as int;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColorsDark.buttonPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.computer, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      buildName,
                      style: TextStyle(
                        color: isDark
                            ? AppColorsDark.textWhite
                            : AppColorsLight.textBlack,
                      ),
                    ),
                  ),
                  Text(
                    '$buildViews views',
                    style: TextStyle(
                      color: isDark
                          ? AppColorsDark.textWhite.withOpacity(0.7)
                          : AppColorsLight.textBlack.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityChart(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundSecondary
            : AppColorsLight.backgroundTertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColorsDark.textWhite
                  : AppColorsLight.textBlack,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColorsDark.buttonGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timeline,
                    size: 48,
                    color: AppColorsDark.buttonGreen.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Activity Chart',
                    style: TextStyle(
                      color: isDark
                          ? AppColorsDark.textWhite.withOpacity(0.5)
                          : AppColorsLight.textBlack.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

