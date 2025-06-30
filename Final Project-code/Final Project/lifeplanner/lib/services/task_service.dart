import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:lifeplanner/services/notification_service.dart';
import 'package:lifeplanner/utils/color_utilis.dart';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';

enum TaskType { oneTime, repeated }

/// Call this at startup to pull down all pending tasks & occurrences

class TaskService {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final NotificationService _notifier;
  final Logger _logger = Logger();

  TaskService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    NotificationService? notifier,
  }) : firestore = firestore ?? FirebaseFirestore.instance,
       auth = auth ?? FirebaseAuth.instance,
       _notifier = notifier ?? NotificationService.instance;

  Future<void> uploadTask({
    required String title,
    required String description,
    required String category,
    required TaskType type,
    required DateTime start,
    required DateTime? reminder,
    required TimeOfDay endTime,
    DateTime? repeatEnd,
    List<int>? weekdays,
    required Color color,
  }) async {
    final user = auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'NO_USER',
        message: 'User not signed in',
      );
    }

    // Auto-fill reminder to start time if null
    final realRem = reminder ?? start;

    // Validate reminder
    if (realRem.isAfter(start)) {
      throw ArgumentError('Reminder must be ≤ start time');
    }
    if (realRem.isBefore(DateTime.now())) {
      throw ArgumentError('Reminder cannot be in past');
    }

    // Calculate offset for repeated tasks
    final offset = realRem.difference(start);

    // Build Firestore data (including cache timestamp)
    final data = <String, dynamic>{
      'title': title,
      'description': description,
      'category': category,
      'type': type == TaskType.oneTime ? 'one-time' : 'repeated',
      'startDate': Timestamp.fromDate(
        DateTime(start.year, start.month, start.day),
      ),
      'startTime': {'hour': start.hour, 'minute': start.minute},
      'endTime': {'hour': endTime.hour, 'minute': endTime.minute},
      'reminderDate': Timestamp.fromDate(
        DateTime(realRem.year, realRem.month, realRem.day),
      ),
      'reminderTime': {'hour': realRem.hour, 'minute': realRem.minute},
      'color': ColorUtils.toHex(color),
      'isComplete': false,
      'createdVia': 'user',
      'createdAt': FieldValue.serverTimestamp(),
      'timestamp': FieldValue.serverTimestamp(), // <-- cache timestamp
      if (type == TaskType.repeated && repeatEnd != null)
        'endDate': Timestamp.fromDate(
          DateTime(repeatEnd.year, repeatEnd.month, repeatEnd.day),
        ),
      if (type == TaskType.repeated && weekdays != null) 'weekdays': weekdays,
    };

    // Add parent task
    final parentRef = await firestore
        .collection('Users')
        .doc(user.uid)
        .collection('Tasks')
        .add(data);
    // --- NEW: schedule notification for one-time ---
    if (type == TaskType.oneTime) {
      // compute exact reminder DateTime
      final remDate = (data['reminderDate'] as Timestamp).toDate();
      final remTime = data['reminderTime'] as Map<String, dynamic>;
      final scheduled = DateTime(
        remDate.year,
        remDate.month,
        remDate.day,
        remTime['hour'] as int,
        remTime['minute'] as int,
      );

      // use parentRef.id.hashCode as the notification ID
      await _notifier.scheduleNotification(
        id: parentRef.id.hashCode,
        title: 'Reminder: $title',
        body: description,
        scheduledDate: scheduled,
      );
    }

    // Generate occurrences for repeated tasks
    if (type == TaskType.repeated && repeatEnd != null && weekdays != null) {
      final batch = firestore.batch();
      DateTime cursor = DateTime(start.year, start.month, start.day);
      final end = DateTime(repeatEnd.year, repeatEnd.month, repeatEnd.day);

      while (!cursor.isAfter(end)) {
        if (weekdays.contains(cursor.weekday)) {
          final occStart = DateTime(
            cursor.year,
            cursor.month,
            cursor.day,
            start.hour,
            start.minute,
          );

          // Calculate occurrence reminder
          final occReminder = occStart.add(offset);
          final docId = DateFormat('yyyy-MM-dd').format(cursor);
          final docRef = parentRef.collection('Occurrences').doc(docId);

          batch.set(docRef, {
            'startDate': Timestamp.fromDate(occStart),
            'reminderDate': Timestamp.fromDate(occReminder),
            'reminderTime': {
              'hour': occReminder.hour,
              'minute': occReminder.minute,
            },
            'completed': false,
            'timestamp':
                FieldValue.serverTimestamp(), // <-- cache timestamp on occurrence
          });
          // --- NEW: schedule each occurrence notification ---
          final occNotifId = ('${parentRef.id}|$docId').hashCode;
          await _notifier.scheduleNotification(
            id: occNotifId,
            title: 'Reminder: $title',
            body: description,
            scheduledDate: occReminder,
          );
        }
        cursor = cursor.add(const Duration(days: 1));
      }

      try {
        await batch.commit();
      } catch (e, st) {
        _logger.e(
          'Failed to commit occurrences batch',
          error: e,
          stackTrace: st,
        );
        rethrow;
      }
    }

    _logger.i('Task uploaded: ${parentRef.id}');
  }

  /// Delete one-time task
  Future<void> deleteOneTime(String userId, String taskId) async {
    await firestore
        .collection('Users')
        .doc(userId)
        .collection('Tasks')
        .doc(taskId)
        .delete();
    // cancel its notification:
    await _notifier.cancel(taskId.hashCode);
  }

  /// Delete a single occurrence
  Future<void> deleteOccurrence(
    String userId,
    String taskId,
    String occurrenceId,
  ) async {
    await firestore
        .collection('Users')
        .doc(userId)
        .collection('Tasks')
        .doc(taskId)
        .collection('Occurrences')
        .doc(occurrenceId)
        .delete();
    // cancel that notif:
    await _notifier.cancel(('$taskId|$occurrenceId').hashCode);
  }

  /// Delete entire series (parent + all occurrences)
  Future<void> deleteSeries(String userId, String taskId) async {
    // first cancel all occurrence notifs:
    final occSnap =
        await firestore
            .collection('Users')
            .doc(userId)
            .collection('Tasks')
            .doc(taskId)
            .collection('Occurrences')
            .get();
    for (var occ in occSnap.docs) {
      await _notifier.cancel(('$taskId|${occ.id}').hashCode);
    }
    // then cancel the parent:
    await _notifier.cancel(taskId.hashCode);
    // finally delete docs
    await firestore
        .collection('Users')
        .doc(userId)
        .collection('Tasks')
        .doc(taskId)
        .delete();
  }

  /// Edit one-time task
  Future<void> editOneTime({
    required String userId,
    required String taskId,
    required Map<String, dynamic> updatedFields,
  }) async {
    final filteredUpdates = {
      'title': updatedFields['title'],
      'description': updatedFields['description'],
      'category': updatedFields['category'],
      'color': updatedFields['color'],
      'modifiedAt': FieldValue.serverTimestamp(),
      'timestamp': FieldValue.serverTimestamp(), // <-- refresh cache timestamp
    };

    await firestore
        .collection('Users')
        .doc(userId)
        .collection('Tasks')
        .doc(taskId)
        .update(filteredUpdates);
  }

  /// Edit series
  Future<void> editSeries({
    required String userId,
    required String taskId,
    required Map<String, dynamic> updatedFields,
  }) async {
    final filteredUpdates = {
      'title': updatedFields['title'],
      'description': updatedFields['description'],
      'category': updatedFields['category'],
      'color': updatedFields['color'],
      'modifiedAt': FieldValue.serverTimestamp(),
      'timestamp': FieldValue.serverTimestamp(), // <-- refresh cache timestamp
    };

    await firestore
        .collection('Users')
        .doc(userId)
        .collection('Tasks')
        .doc(taskId)
        .update(filteredUpdates);
  }

  Future<void> rescheduleAllTasks() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();

    // 1) Fetch every parent task (no date filter)
    final taskSnap =
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(uid)
            .collection('Tasks')
            .get(); // ← removed the .where('reminderDate' ≥ now)

    for (var doc in taskSnap.docs) {
      final data = doc.data();
      final type = data['type'] as String;

      if (type == 'one-time') {
        // Only schedule if *this* task’s own reminderDate is still in the future
        final remTs = data['reminderDate'] as Timestamp;
        final remDate = remTs.toDate();
        if (remDate.isAfter(now) || remDate.isAtSameMomentAs(now)) {
          final remTime = data['reminderTime'] as Map<String, dynamic>;
          final scheduled = DateTime(
            remDate.year,
            remDate.month,
            remDate.day,
            remTime['hour'] as int,
            remTime['minute'] as int,
          );
          await NotificationService.instance.scheduleNotification(
            id: doc.id.hashCode,
            title: 'Reminder: ${data['title']}',
            body: data['description'] as String,
            scheduledDate: scheduled,
          );
        }
      } else {
        // Repeated: pull *all* occurrences, then schedule only future ones
        final occSnap =
            await doc.reference
                .collection('Occurrences')
                .get(); // you could keep a .where here if you like

        for (var occ in occSnap.docs) {
          final odTs = occ.data()['reminderDate'] as Timestamp;
          final od = odTs.toDate();
          if (od.isAfter(now) || od.isAtSameMomentAs(now)) {
            final ot = occ.data()['reminderTime'] as Map<String, dynamic>;
            final scheduled = DateTime(
              od.year,
              od.month,
              od.day,
              ot['hour'] as int,
              ot['minute'] as int,
            );
            final notifId = ('${doc.id}|${occ.id}').hashCode;
            await NotificationService.instance.scheduleNotification(
              id: notifId,
              title: 'Reminder: ${data['title']}',
              body: data['description'] as String,
              scheduledDate: scheduled,
            );
          }
        }
      }
    }
  }

  /// Call this to listen for live adds/updates/removals and schedule/cancel accordingly
  void startTaskChangeListener() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('Tasks')
        .snapshots()
        .listen((snap) {
          for (var change in snap.docChanges) {
            final doc = change.doc;
            final data = doc.data()!;
            final date = (data['reminderDate'] as Timestamp).toDate();
            final time = data['reminderTime'] as Map<String, dynamic>;
            final scheduled = DateTime(
              date.year,
              date.month,
              date.day,
              time['hour'] as int,
              time['minute'] as int,
            );

            final isFuture = scheduled.isAfter(DateTime.now());
            final notifId =
                data['type'] == 'one-time'
                    ? doc.id.hashCode
                    : ('${doc.id}|${DateFormat('yyyy-MM-dd').format(date)}')
                        .hashCode;

            switch (change.type) {
              case DocumentChangeType.added:
              case DocumentChangeType.modified:
                if (isFuture) {
                  NotificationService.instance.scheduleNotification(
                    id: notifId,
                    title: 'Reminder: ${data['title']}',
                    body: data['description'] as String,
                    scheduledDate: scheduled,
                  );
                }
                break;
              case DocumentChangeType.removed:
                NotificationService.instance.cancel(notifId);
                break;
            }
          }
        });
  }
}
