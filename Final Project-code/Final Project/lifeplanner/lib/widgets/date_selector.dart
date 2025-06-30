import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSelector extends StatefulWidget {
  /// The date that should be highlighted
  final DateTime selectedDate;

  /// Called whenever the user taps a new date
  final ValueChanged<DateTime> onDateChanged;

  const DateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  State<DateSelector> createState() => _DateSelectorState();
}

class _DateSelectorState extends State<DateSelector> {
  int weekOffset = 0;

  /// Generate the 7 dates of the week, offset by [weekOffset]
  List<DateTime> generateWeekDates(int weekOffset) {
    final today = DateTime.now();
    // Start of current week (Monday)
    DateTime startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    // Shift by whole weeks
    startOfWeek = startOfWeek.add(Duration(days: weekOffset * 7));
    return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final weekDates = generateWeekDates(weekOffset);
    final monthName = DateFormat('MMMM').format(weekDates.first);

    return Column(
      children: [
        // ← Month + week‑nav arrows →
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => setState(() => weekOffset--),
              ),
              Text(
                monthName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () => setState(() => weekOffset++),
              ),
            ],
          ),
        ),

        // ← The horizontal list of days →
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: weekDates.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final date = weekDates[index];
              final isSelected =
                  date.year == widget.selectedDate.year &&
                  date.month == widget.selectedDate.month &&
                  date.day == widget.selectedDate.day;

              return GestureDetector(
                onTap: () => widget.onDateChanged(date),
                child: Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? Colors.deepOrangeAccent
                            : Colors.transparent,
                    border: Border.all(
                      color:
                          isSelected
                              ? Colors.deepOrangeAccent
                              : Colors.grey.shade300,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('d').format(date),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('E').format(date),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
