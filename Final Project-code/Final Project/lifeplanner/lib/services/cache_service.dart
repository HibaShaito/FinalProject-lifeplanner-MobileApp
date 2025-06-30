import 'package:cloud_firestore/cloud_firestore.dart';

class CacheService {
  /// Deletes any locally cached documents in [collectionPath] older than [maxAge].
  static Future<void> pruneOldCache({
    required String collectionPath,
    required Duration maxAge,
  }) async {
    final cutoff = Timestamp.fromDate(DateTime.now().subtract(maxAge));

    // Query only the local cache
    final snapshot = await FirebaseFirestore.instance
        .collection(collectionPath)
        .where('cachedAt', isLessThan: cutoff)
        .get(const GetOptions(source: Source.cache));

    for (final doc in snapshot.docs) {
      // This will only delete the local copy (since source is cache)
      await doc.reference.delete();
    }
  }
}
