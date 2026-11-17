import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_theme.dart';
import '../../services/api_service.dart';

class HolidayItem {
  final int id;
  final String name;
  final DateTime date;
  final String type;
  final String? description;
  final bool isOptional;

  HolidayItem({
    required this.id,
    required this.name,
    required this.date,
    required this.type,
    this.description,
    this.isOptional = false,
  });

  factory HolidayItem.fromJson(Map<String, dynamic> json) {
    return HolidayItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? 'Holiday',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      type: json['type'] ?? 'public',
      description: json['description'],
      isOptional: json['is_optional'] ?? false,
    );
  }

  bool get isUpcoming => date.isAfter(DateTime.now().subtract(const Duration(days: 1)));
  int get daysRemaining => date.difference(DateTime.now()).inDays;
}

class HolidaysScreen extends StatefulWidget {
  const HolidaysScreen({super.key});

  @override
  State<HolidaysScreen> createState() => _HolidaysScreenState();
}

class _HolidaysScreenState extends State<HolidaysScreen> {
  bool _isLoading = true;
  String? _error;
  List<HolidayItem> _holidays = [];
  String _selectedFilter = 'All'; // 'All', 'Upcoming', 'National'

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = context.read<ApiService>();
      final res = await api.getAuth('/holidays');

      final List<dynamic> rows;
      if (res is List) {
        rows = res;
      } else if (res is Map && res['data'] is List) {
        rows = res['data'] as List;
      } else if (res is Map && res['rows'] is List) {
        rows = res['rows'] as List;
      } else {
        rows = [];
      }

      final list = rows.map((r) => HolidayItem.fromJson(r as Map<String, dynamic>)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      if (mounted) {
        setState(() {
          _holidays = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load holidays: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<HolidayItem> get _filteredHolidays {
    if (_selectedFilter == 'Upcoming') {
      return _holidays.where((h) => h.isUpcoming).toList();
    } else if (_selectedFilter == 'National') {
      return _holidays.where((h) => h.type.toLowerCase().contains('national')).toList();
    }
    return _holidays;
  }

  HolidayItem? get _nextHoliday {
    final upcoming = _holidays.where((h) => h.isUpcoming).toList();
    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final next = _nextHoliday;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Holiday Calendar'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadHolidays,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_off, size: 48, color: AppColors.error),
                          const SizedBox(height: 12),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadHolidays,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      // Next Holiday Hero Banner
                      if (next != null) _buildNextHolidayCard(next),
                      const SizedBox(height: 16),

                      // Filter chips
                      Row(
                        children: [
                          _filterChip('All', '${_holidays.length}'),
                          const SizedBox(width: 8),
                          _filterChip('Upcoming', '${_holidays.where((h) => h.isUpcoming).length}'),
                          const SizedBox(width: 8),
                          _filterChip('National', '${_holidays.where((h) => h.type.toLowerCase().contains('national')).length}'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // List of Holidays
                      if (_filteredHolidays.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          child: const Text(
                            'No holidays found for selected filter.',
                            style: TextStyle(color: AppColors.textTertiary),
                          ),
                        )
                      else
                        ..._filteredHolidays.map((h) => _buildHolidayTile(h)),
                    ],
                  ),
      ),
    );
  }

  Widget _buildNextHolidayCard(HolidayItem holiday) {
    final days = holiday.daysRemaining;
    final daysText = days == 0
        ? 'Today!'
        : days == 1
            ? 'Tomorrow'
            : 'In $days days';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.celebration, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'NEXT HOLIDAY • $daysText',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('EEEE').format(holiday.date),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            holiday.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('dd MMMM yyyy').format(holiday.date),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (holiday.description != null && holiday.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              holiday.description!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterChip(String label, String count) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildHolidayTile(HolidayItem holiday) {
    final dayNum = DateFormat('dd').format(holiday.date);
    final monthStr = DateFormat('MMM').format(holiday.date).toUpperCase();
    final dayName = DateFormat('EEEE').format(holiday.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: holiday.isUpcoming
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          // Date badge
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: holiday.isUpcoming
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  monthStr,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: holiday.isUpcoming ? AppColors.primary : Colors.grey,
                  ),
                ),
                Text(
                  dayNum,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: holiday.isUpcoming ? AppColors.primary : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holiday.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      dayName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.purpleBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        holiday.type.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.purple,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (holiday.isUpcoming)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Upcoming',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
