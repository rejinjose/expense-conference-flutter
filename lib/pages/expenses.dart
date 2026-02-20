import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../models/expense.dart' show Expense;
import '../components/page_header.dart' show PageHeader;
import '../components/custom_button.dart' show CustomButton, ButtonVariant;
import '../components/expenses/add_expense_form.dart' show AddExpenseForm;

class ExpensesPage extends ConsumerWidget  {
  const ExpensesPage({super.key});

  void _showAddExpenseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows keyboard to push the sheet up
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const AddExpenseForm(),
    );
  }

  void _deleteExpense(BuildContext context, WidgetRef ref, String expenseId) async {
    final expenseService = ref.read(expenseServiceProvider);
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await expenseService.deleteExpense(expenseId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense deleted successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final expenseService = ref.watch(expenseServiceProvider);
    final user = ref.read(currentUserProvider); 

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left Side: Header & Subheader
                  Expanded(
                    child: PageHeader(
                      title: "Expenses",
                      subtitle: "Track your daily spending:: ${user!.email}",
                    ),
                  ),
                  // Right Side: Add Button
                  CustomButton(
                    text: "Add Expense",
                    variant: ButtonVariant.primary,
                    onPressed: () => _showAddExpenseSheet(context),
                    leftIcon: const Icon(Icons.add, size: 18),
                  ),
                ],
              ),              
            ],
          ),
        ),
        // Example of reading data back
        Expanded(
          child: StreamBuilder<List<Expense>>(
            stream: expenseService.getExpenses(),
            builder: (context, snapshot) {
              // 1. Check for Errors (Index issues, permissions, etc.)
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              // 2. Check if still loading for the first time
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // 3. Check if the list is empty
              final docs = snapshot.data ?? [];
              if (docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "No expenses created yet.",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Please click on the button above to create your first expense.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // 4. Data is ready
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final expense = docs[i];
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: const Icon(Icons.money_off, color: Colors.white),
                      ),
                      title: Text(expense.title),
                      subtitle: Text(
                        DateFormat.yMMMd().format(expense.date),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _deleteExpense(context, ref, expense.id!);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Show amount as chip for better visual
                      onTap: () {}, // Optional: Add edit functionality later
                    ),
                  );
                },
              );

            },
          ),
        )
      ],
    );
  }
}
