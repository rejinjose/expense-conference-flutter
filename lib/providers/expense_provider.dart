// providers/expense_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../models/expense.dart' show Expense;

final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

final expenseServiceProvider = Provider((ref) {
  final firestore = ref.watch(firestoreProvider);
  final user = ref.watch(authStateProvider).value;
  return ExpenseService(firestore, user?.uid);
});

class ExpenseService {
  final FirebaseFirestore _db;
  final String? _userId;

  ExpenseService(this._db, this._userId);

  // Helper to get a converted collection reference
  CollectionReference<Expense> get _expensesRef => 
    _db.collection('expenses').withConverter<Expense>(
      fromFirestore: (snapshot, _) => Expense.fromMap(snapshot.data()!, snapshot.id),
      toFirestore: (expense, _) => expense.toMap(),
    );

  Future<void> addExpense(Expense expense) async {
    if (_userId == null) throw Exception("User not logged in");
    // Now you can pass the object directly!
    await _expensesRef.add(expense); 
  }

  Stream<List<Expense>> getExpenses() {
    return _expensesRef
        .where('uid', isEqualTo: _userId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Soft Delete: matches React softDeleteExpense
  Future<void> deleteExpense(String expenseId) async {
    await _db.collection('expenses').doc(expenseId).update({'status': 'deleted'});
  }
}




