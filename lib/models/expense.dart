// models/expense.dart
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp, FieldValue;

class Expense {
  final String? id;
  final String title;
  final double amount;
  final DateTime date;      // The date the user picked in the UI
  final DateTime createdAt; // Metadata: when the entry was created
  final String uid;
  final String status;

  Expense({
    this.id, 
    required this.title, 
    required this.amount, 
    required this.date, 
    required this.createdAt, 
    required this.uid,
    this.status = 'active',
  });

  // Convert to Map for saving
  Map<String, dynamic> toMap() => {
    'title': title,
    'amount': amount,
    'date': Timestamp.fromDate(date), // Convert DateTime to Firestore Timestamp
    'createdAt': FieldValue.serverTimestamp(), // Let the server set the time
    'uid': uid,
    'status': status,
  };

  factory Expense.fromMap(Map<String, dynamic> data, String id) {
    return Expense(
      id: id,
      title: data['title'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      uid: data['uid'] ?? '',
      status: data['status'] ?? 'active',
      // Parsing the user-selected date
      date: (data['date'] as Timestamp).toDate(),
      // Parsing the system creation time (with a fallback)
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
