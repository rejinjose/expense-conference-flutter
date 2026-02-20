import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/expense_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/expense.dart' show Expense;
import '../custom_button.dart' show CustomButton;

class AddExpenseForm extends ConsumerStatefulWidget {
  const AddExpenseForm({super.key});

  @override
  ConsumerState<AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends ConsumerState<AddExpenseForm> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) setState(() => _selectedDate = pickedDate);
  }

  void _submitData() async {
    final title = _titleController.text;
    final amount = double.tryParse(_amountController.text) ?? 0;

    final user = ref.read(currentUserProvider); 
    if (user == null) return; // Handle unauthenticated state

    if (title.isEmpty || amount <= 0) return;

    final expenseService = ref.read(expenseServiceProvider);
    
    // Create the Expense object 
    final newExpense = Expense(
      title: title,
      amount: amount,
      date: _selectedDate,
      createdAt: DateTime.now(), 
      uid: user.uid,
    );

    await expenseService.addExpense(newExpense);
    if (mounted) Navigator.of(context).pop(); // Close the sheet
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Padding adjusts when keyboard appears
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Sheet only takes needed space
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("New Expense", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Date: ${DateFormat.yMd().format(_selectedDate)}",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface, // Ensures visibility
                    fontWeight: FontWeight.w500,
                  ),
                )
              ),
              TextButton(
                onPressed: _presentDatePicker,
                child: const Text("Choose Date"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: "Save Expense",
              onPressed: _submitData,
            ),
          ),
        ],
      ),
    );
  }
}
