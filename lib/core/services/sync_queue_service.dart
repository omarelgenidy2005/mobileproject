import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../errors/app_exception.dart';
import 'connectivity_service.dart';
import 'hive_service.dart';

/// Queues Firestore writes while offline and flushes when connectivity returns.
class SyncQueueService {
  SyncQueueService({
    required ConnectivityService connectivity,
    FirebaseFirestore? firestore,
  })  : _connectivity = connectivity,
        _firestore = firestore;

  final ConnectivityService _connectivity;
  final FirebaseFirestore? _firestore;

  Future<void> enqueue({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    final key = '${DateTime.now().millisecondsSinceEpoch}_$documentId';
    await HiveService.syncQueueBox.put(key, {
      'collection': collection,
      'documentId': documentId,
      'data': data,
      'merge': merge,
    });

    if (_connectivity.isOnline) {
      await flush();
    }
  }

  Future<void> flush() async {
    if (!_connectivity.isOnline || _firestore == null) return;

    final box = HiveService.syncQueueBox;
    final keys = box.keys.toList();

    for (final key in keys) {
      final item = box.get(key);
      if (item == null) continue;
      try {
        await _firestore
            .collection(item['collection'] as String)
            .doc(item['documentId'] as String)
            .set(item['data'] as Map<String, dynamic>, SetOptions(merge: item['merge'] as bool? ?? true));
        await box.delete(key);
      } catch (e, st) {
        debugPrint('SyncQueueService.flush failed for $key: $e');
        debugPrintStack(stackTrace: st);
        throw const DatabaseException('Sync failed. Will retry when online.');
      }
    }
  }
}
