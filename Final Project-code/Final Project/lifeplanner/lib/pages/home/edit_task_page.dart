import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lifeplanner/services/task_service.dart';
import 'package:lifeplanner/utils/color_utilis.dart';
import 'package:lifeplanner/widgets/base_scaffold.dart';

class EditTaskPage extends StatefulWidget {
  final String taskId;
  final bool isRepeated;

  const EditTaskPage({
    required this.taskId,
    required this.isRepeated,
    super.key,
  });

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String? _category;
  final _predefCats = ['Work', 'Personal', 'Urgent'];
  List<String> _userCats = [];
  Color _color = Colors.blue;
  bool _loading = true;
  bool _isSaving = false; // Added save state tracker

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (mounted) setState(() => _loading = true);

    try {
      final u = FirebaseAuth.instance.currentUser;
      if (u == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Not signed in.')));
        Navigator.of(context).pop();
        return;
      }

      final userRef = FirebaseFirestore.instance.collection('Users').doc(u.uid);
      final taskRef = userRef.collection('Tasks').doc(widget.taskId);
      final results = await Future.wait([userRef.get(), taskRef.get()]);

      final userDoc = results[0] as DocumentSnapshot;
      final taskDoc = results[1] as DocumentSnapshot;

      if (!taskDoc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Task not found.')));
        Navigator.of(context).pop();
        return;
      }

      // Load user categories
      final rawUserData = userDoc.data();
      if (rawUserData is Map<String, dynamic>) {
        final rawCats = rawUserData['customCategories'];
        if (rawCats is List) {
          _userCats = rawCats.map((e) => e.toString()).toList();
        }
      }

      // Load task data
      final rawTaskData = taskDoc.data();
      if (rawTaskData is Map<String, dynamic>) {
        _titleCtrl.text = (rawTaskData['title'] ?? '').toString();
        _descCtrl.text = (rawTaskData['description'] ?? '').toString();
        _category = (rawTaskData['category'] ?? _predefCats.first).toString();

        final rawColor = rawTaskData['color'];
        if (rawColor is int) {
          _color = Color(rawColor);
          // In _loadAll():
        } else if (rawColor is String) {
          _color = ColorUtils.fromHex(rawColor);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading task: $e')));
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final u = FirebaseAuth.instance.currentUser!;
      final updates = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _category,
        'color': ColorUtils.toHex(_color),
        'modifiedAt': FieldValue.serverTimestamp(),
        'timestamp': FieldValue.serverTimestamp(), // ← refresh cache timestamp
      };

      final svc = TaskService();
      if (widget.isRepeated) {
        await svc.editSeries(
          userId: u.uid,
          taskId: widget.taskId,
          updatedFields: updates,
        );
      } else {
        await svc.editOneTime(
          userId: u.uid,
          taskId: widget.taskId,
          updatedFields: updates,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving task: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.fredoka(color: Colors.black87),
    filled: true,
    fillColor: Colors.grey.shade50,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.black87),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final allCats = {..._predefCats, ..._userCats}.toList();
    if (_category != null && !allCats.contains(_category)) {
      allCats.add(_category!);
    }

    return BaseScaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD27F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit Task',
          style: GoogleFonts.fredoka(color: Colors.black, fontSize: 22),
        ),
        elevation: 0,
      ),
      child:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Scrollbar(
                radius: const Radius.circular(12),
                thickness: 6,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _titleCtrl,
                              decoration: _inputDecoration('Title'),
                              maxLength: 50,
                              validator:
                                  (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Enter a title'
                                          : null,
                            ),
                            const SizedBox(height: 20),

                            DropdownButtonFormField<String>(
                              decoration: _inputDecoration('Category'),
                              items:
                                  allCats
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(
                                            c,
                                            style: GoogleFonts.fredoka(),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              value: _category,
                              onChanged: (v) => setState(() => _category = v),
                              validator:
                                  (v) => v == null ? 'Select a category' : null,
                            ),
                            const SizedBox(height: 20),

                            TextFormField(
                              controller: _descCtrl,
                              decoration: _inputDecoration('Details'),
                              maxLines: 3,
                              maxLength: 5000,
                              validator: (v) {
                                if (v != null && v.length > 5000) {
                                  return 'Max 5,000 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            ListTile(
                              title: const Text('Color'),
                              trailing: CircleAvatar(backgroundColor: _color),
                              onTap:
                                  () => showDialog(
                                    context: context,
                                    builder: (_) {
                                      return AlertDialog(
                                        title: const Text('Pick a color'),
                                        content: SingleChildScrollView(
                                          child: ColorPicker(
                                            color: _color,
                                            pickersEnabled: const {
                                              ColorPickerType.wheel: true,
                                            },
                                            onColorChanged:
                                                (c) =>
                                                    setState(() => _color = c),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: const Text('Done'),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                            ),

                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: _isSaving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child:
                                  _isSaving
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : Text(
                                        'Save Changes',
                                        style: GoogleFonts.fredoka(
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
    );
  }
}
