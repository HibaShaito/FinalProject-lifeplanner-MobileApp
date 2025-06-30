import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lifeplanner/services/task_service.dart';
import 'package:lifeplanner/widgets/base_scaffold.dart';

/// A generic FormField wrapper so we can validate pickers
typedef PickerValidator<T> = String? Function(T? value);

class PickerFormField<T> extends FormField<T> {
  const PickerFormField({
    super.key,
    super.initialValue,
    super.validator,
    AutovalidateMode super.autovalidateMode = AutovalidateMode.disabled,
    required super.builder,
  });
}

class AddNewTask extends StatefulWidget {
  const AddNewTask({super.key});

  @override
  State<AddNewTask> createState() => _AddNewTaskState();
}

class _AddNewTaskState extends State<AddNewTask> {
  final _formKey = GlobalKey<FormState>();
  final _taskService = TaskService();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  TaskType _taskType = TaskType.oneTime;
  String? _category;
  final _predefCats = ['Work', 'Personal', 'Urgent'];
  List<String> _userCats = [];

  DateTime _startDate = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  DateTime? _repeatEnd;
  List<int> _weekdays = [];

  DateTime? _reminderDate;
  TimeOfDay? _reminderTime;

  Color _color = Colors.blue;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadCustomCats();
  }

  Future<void> _loadCustomCats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();
    if (doc.exists) {
      final cats = doc.data()?['customCategories'] as List<dynamic>?;
      if (cats != null) {
        setState(() => _userCats = List<String>.from(cats));
      }
    }
  }

  DateTime? get _startDT =>
      _startTime == null
          ? null
          : DateTime(
            _startDate.year,
            _startDate.month,
            _startDate.day,
            _startTime!.hour,
            _startTime!.minute,
          );

  DateTime? get _reminderDT =>
      (_reminderDate == null || _reminderTime == null)
          ? null
          : DateTime(
            _reminderDate!.year,
            _reminderDate!.month,
            _reminderDate!.day,
            _reminderTime!.hour,
            _reminderTime!.minute,
          );

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final deviceWidth = MediaQuery.of(context).size.width;

    final cats = [..._predefCats, ..._userCats];
    return BaseScaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD27F),
        title: Text('Add Task', style: GoogleFonts.fredoka(fontSize: 22)),
        leading: BackButton(color: Colors.black),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                maxLength: 50,
                validator:
                    (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Enter a title'
                            : null,
              ),

              const SizedBox(height: 16),
              // Description
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Details'),
                maxLines: 3,
                maxLength: 5000, // ← now allows up to 5,000 chars
                validator: (v) {
                  if (v != null && v.length > 5000) {
                    return 'Max 5,000 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),
              // One-time vs Repeated
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('One-time', style: GoogleFonts.fredoka()),
                  Switch(
                    value: _taskType == TaskType.repeated,
                    onChanged:
                        (v) => setState(
                          () =>
                              _taskType =
                                  v ? TaskType.repeated : TaskType.oneTime,
                        ),
                  ),
                  Text('Repeated', style: GoogleFonts.fredoka()),
                ],
              ),

              const SizedBox(height: 16),
              // Category
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Category'),
                items:
                    cats
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                value: _category,
                onChanged: (v) => setState(() => _category = v),
                validator: (v) => v == null ? 'Select a category' : null,
              ),
              const SizedBox(height: 20),
              Center(
                child: Image.asset(
                  'assets/img/task_illustration.png',
                  height: deviceHeight * 0.25,
                  width: deviceWidth * 0.8,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),

              const SizedBox(height: 16),
              // ─── Start Date Picker ───────────────────────────────────────────────────────
              PickerFormField<DateTime>(
                initialValue: _startDate,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (_) {
                  final today = DateTime.now();
                  final todayDateOnly = DateTime(
                    today.year,
                    today.month,
                    today.day,
                  );
                  if (_startDate.isBefore(todayDateOnly)) {
                    return 'Start date can’t be before today';
                  }
                  return null;
                },
                builder: (field) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: const Text('Start Date'),
                        subtitle: Text(DateFormat.yMMMd().format(_startDate)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (d != null) {
                            setState(() => _startDate = d);
                            field.didChange(d);
                          }
                        },
                      ),
                      if (field.hasError)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            field.errorText!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              // ─── Start Time Picker ───────────────────────────────────────────────────────
              PickerFormField<TimeOfDay>(
                initialValue: _startTime,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (t) {
                  if (t == null) return 'Select a start time';
                  // only if on the same day do we compare to now
                  final selectedDT = DateTime(
                    _startDate.year,
                    _startDate.month,
                    _startDate.day,
                    t.hour,
                    t.minute,
                  );
                  if (selectedDT.isBefore(DateTime.now())) {
                    return 'Start must be in the future';
                  }
                  return null;
                },
                builder: (field) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: const Text('Start Time'),
                        subtitle: Text(
                          _startTime?.format(context) ?? 'Not set',
                        ),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: _startTime ?? TimeOfDay.now(),
                          );
                          if (t != null) {
                            setState(() => _startTime = t);
                            field.didChange(t);
                          }
                        },
                      ),
                      if (field.hasError)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            field.errorText!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              // ─── End Time Picker ─────────────────────────────────────────────────────────
              PickerFormField<TimeOfDay>(
                initialValue: _endTime,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (t) {
                  if (t == null) return 'Select an end time';
                  if (_startTime != null) {
                    final startDT = _startDT!;
                    final endDT = DateTime(
                      _startDate.year,
                      _startDate.month,
                      _startDate.day,
                      t.hour,
                      t.minute,
                    );
                    if (!endDT.isAfter(startDT)) {
                      return 'End must be after start';
                    }
                  }
                  return null;
                },
                builder: (field) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: const Text('End Time'),
                        subtitle: Text(_endTime?.format(context) ?? 'Not set'),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime:
                                _endTime ?? _startTime ?? TimeOfDay.now(),
                          );
                          if (t != null) {
                            setState(() => _endTime = t);
                            field.didChange(t);
                          }
                        },
                      ),
                      if (field.hasError)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            field.errorText!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              if (_taskType == TaskType.repeated) ...[
                const SizedBox(height: 16),
                // ─── Repeat End Time Picker ─────────────────────────────────────────────────────────
                PickerFormField<DateTime>(
                  initialValue: _repeatEnd,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (_) {
                    if (_repeatEnd == null) return 'Select repeat end';
                    if (_repeatEnd!.isBefore(_startDate)) {
                      return 'Must be after start';
                    }
                    return null;
                  },
                  builder: (field) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: const Text('Repeat Until'),
                          subtitle: Text(
                            _repeatEnd == null
                                ? 'Not set'
                                : DateFormat.yMMMd().format(_repeatEnd!),
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _repeatEnd ?? _startDate,
                              firstDate: _startDate,
                              lastDate: _startDate.add(
                                const Duration(days: 365),
                              ),
                            );
                            if (d != null) {
                              setState(() => _repeatEnd = d);
                              field.didChange(d);
                            }
                          },
                        ),
                        if (field.hasError)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              field.errorText!,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 8),
                // ─── Weekdays Picker ─────────────────────────────────────────────────────────
                PickerFormField<List<int>>(
                  initialValue: _weekdays,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator:
                      (list) =>
                          (list == null || list.isEmpty)
                              ? 'Pick at least one weekday'
                              : null,
                  builder: (field) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          children:
                              {
                                1: 'Mon',
                                2: 'Tue',
                                3: 'Wed',
                                4: 'Thu',
                                5: 'Fri',
                                6: 'Sat',
                                7: 'Sun',
                              }.entries.map((e) {
                                final sel = _weekdays.contains(e.key);
                                return FilterChip(
                                  label: Text(
                                    e.value,
                                    style: GoogleFonts.fredoka(
                                      color: sel ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  selected: sel,
                                  selectedColor: Theme.of(context).primaryColor,
                                  onSelected: (_) {
                                    final newList = List<int>.from(_weekdays);
                                    sel
                                        ? newList.remove(e.key)
                                        : newList.add(e.key);
                                    setState(() => _weekdays = newList);
                                    field.didChange(newList);
                                  },
                                );
                              }).toList(),
                        ),
                        if (field.hasError)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Text(
                              field.errorText!,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],

              const SizedBox(height: 16),
              // ─── Reminder Date Picker ─────────────────────────────────────────────────────────
              PickerFormField<DateTime>(
                initialValue: _reminderDate,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (_) {
                  if ((_reminderDate == null) != (_reminderTime == null)) {
                    return 'Set both date & time or leave blank';
                  }
                  return null;
                },
                builder: (field) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: const Text('Reminder Date'),
                        subtitle: Text(
                          _reminderDate == null
                              ? 'Not set'
                              : DateFormat.yMMMd().format(_reminderDate!),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final now = DateTime.now();
                          final last =
                              _taskType == TaskType.repeated
                                  ? (_repeatEnd ?? now)
                                  : _startDate;
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _reminderDate ?? now,
                            firstDate: now.subtract(const Duration(days: 365)),
                            lastDate: last,
                          );
                          if (d != null) {
                            setState(() => _reminderDate = d);
                            field.didChange(d);
                          }
                        },
                      ),
                      if (field.hasError)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            field.errorText!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              // ─── Reminder Time Picker ─────────────────────────────────────────────────────────
              PickerFormField<TimeOfDay>(
                initialValue: _reminderTime,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (t) {
                  // 1) You must have chosen start time first
                  if (_startDT == null) {
                    return 'Please pick a start date & time first';
                  }
                  // 2) Your existing “both or neither” check
                  if ((_reminderDate == null) != (t == null)) {
                    return 'Set both date & time or leave blank';
                  }
                  if (t != null) {
                    final remDT = _reminderDT!;
                    final now = DateTime.now();

                    // 3) Now _startDT! and remDT are guaranteed non-null
                    if (remDT.isAfter(_startDT!)) {
                      return 'Reminder must be before start';
                    }
                    if (remDT.isBefore(now)) {
                      return 'Reminder cannot be in past';
                    }
                  }
                  return null;
                },
                builder: (field) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: const Text('Reminder Time'),
                        subtitle: Text(
                          _reminderTime?.format(context) ?? 'Not set',
                        ),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: _reminderTime ?? TimeOfDay.now(),
                          );
                          if (t != null) {
                            setState(() => _reminderTime = t);
                            field.didChange(t);
                          }
                        },
                      ),
                      if (field.hasError)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            field.errorText!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),
              //Color
              // Update color picker dialog
              ListTile(
                title: const Text('Color'),
                trailing: CircleAvatar(backgroundColor: _color),
                onTap:
                    () => showDialog(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            title: const Text('Pick a color'),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                color: _color,
                                pickersEnabled: const {
                                  ColorPickerType.wheel: true,
                                },
                                onColorChanged:
                                    (c) => setState(() => _color = c),
                                width: 40,
                                height: 40,
                                spacing: 0,
                                runSpacing: 0,
                                wheelDiameter: 200,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Done'),
                              ),
                            ],
                          ),
                    ),
              ),
              const SizedBox(height: 24),
              // Submit
              ElevatedButton(
                onPressed:
                    _submitting
                        ? null
                        : () {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => _submitting = true);

                          // NOTE: no async/await here
                          _taskService
                              .uploadTask(
                                title: titleController.text.trim(),
                                description: descriptionController.text.trim(),
                                category: _category!,
                                type: _taskType,
                                start: _startDT!,
                                reminder: _reminderDT,
                                endTime: _endTime!,
                                repeatEnd:
                                    _taskType == TaskType.repeated
                                        ? _repeatEnd
                                        : null,
                                weekdays:
                                    _taskType == TaskType.repeated
                                        ? _weekdays
                                        : null,
                                color: _color,
                              )
                              .then((_) {
                                // only use context here, inside the then callback
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Task added!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                Navigator.pop(context, true);
                              })
                              .catchError((e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                setState(() => _submitting = false);
                              });
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _taskType == TaskType.oneTime ? 'Add Task' : 'Add Repeated',
                  style: GoogleFonts.fredoka(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
