import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lifeplanner/pages/home/view_task_page.dart';
import 'package:lifeplanner/services/task_service.dart';
import 'package:lifeplanner/utils/color_utilis.dart';
import 'package:lifeplanner/widgets/base_scaffold.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/date_selector.dart';
import 'add_new_category.dart';
import 'add_new_task.dart';
import 'edit_task_page.dart';

class _TaskDataSource extends CalendarDataSource {
  _TaskDataSource(List<Appointment> source) {
    appointments = source;
  }
}

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with SingleTickerProviderStateMixin {
  bool _showIcons = false;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  final CalendarController _calendarController = CalendarController();

  void _toggleIcons() {
    final shouldShowIcons = !_showIcons;
    setState(() => _showIcons = shouldShowIcons);
    shouldShowIcons ? _fabController.forward() : _fabController.reverse();
  }

  DateTime _selectedDate = DateTime.now();
  List<Appointment> _appointments = [];
  bool _loading = true;
  StreamSubscription<QuerySnapshot>? _tasksSub;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeInOut,
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _tasksSub = FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('Tasks')
          .snapshots()
          .listen(_onTasksUpdate);
    }
  }

  @override
  void dispose() {
    _fabController.dispose();
    _tasksSub?.cancel();
    super.dispose();
  }

  Future<void> _onTasksUpdate(QuerySnapshot snap) async {
    final List<Appointment> appts = [];
    for (final doc in snap.docs) {
      final data = doc.data()! as Map<String, dynamic>;
      final title = data['title'] as String? ?? '';
      // Replace hexToColor with:
      final color = ColorUtils.fromHex(data['color'] as String);

      if (data['type'] == 'one-time') {
        final dateOnly = (data['startDate'] as Timestamp).toDate();
        final sm = data['startTime'] as Map<String, dynamic>;
        final em = data['endTime'] as Map<String, dynamic>;
        final start = DateTime(
          dateOnly.year,
          dateOnly.month,
          dateOnly.day,
          sm['hour'] as int,
          sm['minute'] as int,
        );
        final end = DateTime(
          dateOnly.year,
          dateOnly.month,
          dateOnly.day,
          em['hour'] as int,
          em['minute'] as int,
        );

        appts.add(
          Appointment(
            startTime: start,
            endTime: end,
            subject: title,
            color: color,
            notes: jsonEncode({'taskId': doc.id, 'type': 'one-time'}),
          ),
        );
      } else {
        final sm = data['startTime'] as Map<String, dynamic>;
        final em = data['endTime'] as Map<String, dynamic>;
        final occSnap = await doc.reference.collection('Occurrences').get();

        for (final occ in occSnap.docs) {
          try {
            final occDate = (occ['startDate'] as Timestamp).toDate();
            final start = DateTime(
              occDate.year,
              occDate.month,
              occDate.day,
              sm['hour'] as int,
              sm['minute'] as int,
            );
            final end = DateTime(
              occDate.year,
              occDate.month,
              occDate.day,
              em['hour'] as int,
              em['minute'] as int,
            );

            appts.add(
              Appointment(
                startTime: start,
                endTime: end,
                subject: title,
                color: color,
                notes: jsonEncode({
                  'taskId': doc.id,
                  'occurrenceId': occ.id,
                  'type': 'repeated',
                }),
              ),
            );
          } catch (e) {
            debugPrint("Invalid occurrence data: $e");
            continue; // skip faulty entry
          }
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _appointments = appts;
      _loading = false;
    });
  }

  void _handleAppointmentTap(Appointment appt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.15,
            maxChildSize: 0.6,
            builder:
                (context, ctrl) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).canvasColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: ListView(
                    controller: ctrl,
                    children: [_buildAppointmentOptions(appt)],
                  ),
                ),
          ),
    );
  }

  Widget _buildAppointmentOptions(Appointment appt) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            appt.subject,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Task'),
            onTap: () {
              Navigator.pop(context);
              _navigateToEditTask(appt);
            },
          ),
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('View Task'),
            onTap: () {
              Navigator.pop(context);
              _navigateToViewTask(appt);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete Task'),
            onTap: () {
              Navigator.pop(context);
              _deleteTask(appt);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToEditTask(Appointment appt) async {
    final meta = jsonDecode(appt.notes ?? '{}');
    final taskId = meta['taskId'];
    final isRepeated = meta['type'] == 'repeated';

    // await the edit page
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditTaskPage(taskId: taskId, isRepeated: isRepeated),
      ),
    );

    // once you return, reload
    await _refreshAppointments();
  }

  Future<void> _navigateToViewTask(Appointment appt) async {
    final meta = jsonDecode(appt.notes ?? '{}');
    final taskId = meta['taskId'] as String;
    final isRepeated = meta['type'] == 'repeated';
    final occId = meta['occurrenceId'] as String?;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ViewTaskPage(
              taskId: taskId,
              isRepeated: isRepeated,
              occurrenceId: occId,
            ),
      ),
    );

    await _refreshAppointments();
  }

  Future<void> _refreshAppointments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap =
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .collection('Tasks')
            .get();
    await _onTasksUpdate(snap);
  }

  void _deleteTask(Appointment appt) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final meta = jsonDecode(appt.notes ?? '{}') as Map<String, dynamic>;
    final taskId = meta['taskId'] as String;
    final isRepeated = meta['type'] == 'repeated';
    final occId = meta['occurrenceId'] as String?;

    if (!isRepeated) {
      final ok = await _confirmDialog('Delete this task?');
      if (ok) {
        await TaskService().deleteOneTime(user.uid, taskId);
        await _refreshAppointments();
      }
      return;
    }

    final choice = await showDialog<String>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Repeated Task"),
            content: const Text('Delete this occurrence or entire series?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'cancel'),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'occurrence'),
                child: const Text('This Occurrence'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'series'),
                child: const Text('Entire Series'),
              ),
            ],
          ),
    );

    if (choice == 'occurrence' && occId != null) {
      await TaskService().deleteOccurrence(user.uid, taskId, occId);
      await _refreshAppointments();
    } else if (choice == 'series') {
      await TaskService().deleteSeries(user.uid, taskId);
      await _refreshAppointments();
    }
  }

  Future<bool> _confirmDialog(String message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Confirm"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    return confirmed == true;
  }

  bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in to see your schedule.'));
    }

    return BaseScaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD27F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Schedule',
          style: GoogleFonts.fredoka(color: Colors.black, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            children: [
              DateSelector(
                selectedDate: _selectedDate,
                onDateChanged: (d) {
                  setState(() => _selectedDate = d);
                  _calendarController.displayDate = d;
                },
              ),
              Expanded(
                child:
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : SfCalendar(
                          controller: _calendarController,
                          view: CalendarView.timelineDay,
                          dataSource: _TaskDataSource(_appointments),
                          initialDisplayDate: _selectedDate,
                          headerHeight: 0,
                          showNavigationArrow: false,
                          showDatePickerButton: false,
                          allowViewNavigation: false,
                          timeSlotViewSettings: const TimeSlotViewSettings(
                            timeInterval: Duration(minutes: 30),
                            timeIntervalWidth: 100,
                          ),
                          onTap: (CalendarTapDetails details) {
                            if (details.targetElement ==
                                    CalendarElement.appointment &&
                                details.appointments != null) {
                              final tappedAppt =
                                  details.appointments!.first as Appointment;
                              _handleAppointmentTap(tappedAppt);
                            }
                          },
                          onViewChanged: (ViewChangedDetails details) {
                            final visibleDates = details.visibleDates;
                            if (visibleDates.isNotEmpty) {
                              final newDate = visibleDates.first;
                              if (!isSameDate(newDate, _selectedDate)) {
                                setState(() => _selectedDate = newDate);
                              }
                            }
                          },
                        ),
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_showIcons) ...[
                  _miniFab(
                    icon: Icons.add_task,
                    tooltip: 'Add Task',
                    onPressed: () async {
                      // push, wait for the page to pop, then refresh
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddNewTask()),
                      );
                      await _refreshAppointments();
                    },
                  ),
                  _miniFab(
                    icon: Icons.category,
                    tooltip: 'Add Category',
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddCustomCategoryPage(),
                        ),
                      );
                      await _refreshAppointments();
                    },
                  ),
                ],
                FloatingActionButton(
                  onPressed: _toggleIcons,
                  backgroundColor: const Color(0xFFFFD27F),
                  child: AnimatedRotation(
                    turns: _showIcons ? 0.125 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniFab({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) => ScaleTransition(
    scale: _fabAnimation,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: FloatingActionButton(
        heroTag: tooltip,
        mini: true,
        backgroundColor: Colors.white,
        tooltip: tooltip,
        onPressed: onPressed,
        child: Icon(icon, color: Colors.black),
      ),
    ),
  );

  void _showHelpDialog(BuildContext c) {
    showDialog(
      context: c,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Page Guide"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("• Date selector: Tap to switch between days."),
                SizedBox(height: 8),
                Text("• Task list: Shows scheduled tasks."),
                SizedBox(height: 8),
                Text("➕ button: Tap to add task or category."),
                SizedBox(height: 8),
                Text("💡 Long press icons to view tooltip"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text("Got it!"),
              ),
            ],
          ),
    );
  }
}
