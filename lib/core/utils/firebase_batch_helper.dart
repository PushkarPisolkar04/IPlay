import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class for Firebase batch operations
/// Optimizes Firebase writes by batching multiple operations together
class FirebaseBatchHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Execute multiple writes in a single batch
  /// Maximum 500 operations per batch (Firebase limit)
  Future<void> executeBatch(List<BatchOperation> operations) async {
    if (operations.isEmpty) return;
    
    // Split into chunks of 500 (Firebase batch limit)
    final chunks = <List<BatchOperation>>[];
    for (var i = 0; i < operations.length; i += 500) {
      chunks.add(
        operations.sublist(
          i,
          i + 500 > operations.length ? operations.length : i + 500,
        ),
      );
    }
    
    // Execute each chunk
    for (final chunk in chunks) {
      final batch = _firestore.batch();
      
      for (final operation in chunk) {
        switch (operation.type) {
          case BatchOperationType.set:
            batch.set(
              operation.reference,
              operation.data!,
              operation.setOptions,
            );
            break;
          case BatchOperationType.update:
            batch.update(operation.reference, operation.data!);
            break;
          case BatchOperationType.delete:
            batch.delete(operation.reference);
            break;
        }
      }
      
      await batch.commit();
    }
  }
  
  /// Batch update multiple documents
  Future<void> batchUpdate(
    String collection,
    Map<String, Map<String, dynamic>> updates,
  ) async {
    final operations = updates.entries.map((entry) {
      return BatchOperation.update(
        _firestore.collection(collection).doc(entry.key),
        entry.value,
      );
    }).toList();
    
    await executeBatch(operations);
  }
  
  /// Batch delete multiple documents
  Future<void> batchDelete(String collection, List<String> documentIds) async {
    final operations = documentIds.map((id) {
      return BatchOperation.delete(
        _firestore.collection(collection).doc(id),
      );
    }).toList();
    
    await executeBatch(operations);
  }
  
  /// Increment a field value atomically
  Future<void> incrementField(
    String collection,
    String documentId,
    String field,
    num incrementBy,
  ) async {
    await _firestore.collection(collection).doc(documentId).update({
      field: FieldValue.increment(incrementBy),
    });
  }
  
  /// Increment multiple fields atomically
  Future<void> incrementFields(
    String collection,
    String documentId,
    Map<String, num> increments,
  ) async {
    final updates = increments.map(
      (key, value) => MapEntry(key, FieldValue.increment(value)),
    );
    
    await _firestore.collection(collection).doc(documentId).update(updates);
  }
}

/// Batch operation types
enum BatchOperationType { set, update, delete }

/// Represents a single batch operation
class BatchOperation {
  final BatchOperationType type;
  final DocumentReference reference;
  final Map<String, dynamic>? data;
  final SetOptions? setOptions;
  
  BatchOperation._({
    required this.type,
    required this.reference,
    this.data,
    this.setOptions,
  });
  
  factory BatchOperation.set(
    DocumentReference reference,
    Map<String, dynamic> data, {
    SetOptions? options,
  }) {
    return BatchOperation._(
      type: BatchOperationType.set,
      reference: reference,
      data: data,
      setOptions: options,
    );
  }
  
  factory BatchOperation.update(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) {
    return BatchOperation._(
      type: BatchOperationType.update,
      reference: reference,
      data: data,
    );
  }
  
  factory BatchOperation.delete(DocumentReference reference) {
    return BatchOperation._(
      type: BatchOperationType.delete,
      reference: reference,
    );
  }
}
