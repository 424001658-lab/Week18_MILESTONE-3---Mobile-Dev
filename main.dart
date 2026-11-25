// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

/// Application entry point for BaonBuddy.
/// Launches the root MaterialApp widget cleanly separated from screen-level state.
void main() {
  runApp(const BaonBuddyApp());
}

/// [Week 13 - Data Modeling & Encapsulation]
/// Represents a single student expense entry in BaonBuddy.
/// Encapsulating fields in an immutable class prevents accidental mutations
/// across screens and ensures type safety when filtering categories.
class ExpenseItem {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String note;

  const ExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
  });
}

/// [Week 13 - UI Architecture & Custom Material 3 Theming]
/// Root widget configuring BaonBuddy's emerald-teal Material 3 palette,
/// high-contrast cards, and outlined form fields for readability between classes.
class BaonBuddyApp extends StatelessWidget {
  const BaonBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BaonBuddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D7C66),
          brightness: Brightness.light,
        ),
        cardTheme: const CardThemeData(
          elevation: 1,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

/// [Week 15 - Centralized State Management & Dashboard UI]
/// Holds the student's daily allowance and expense list state. Lifting state
/// here lets AddExpenseScreen and ExpenseDetailScreen return updates cleanly
/// so the remaining balance and warning banner recalculate in real time.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _dailyAllowance = 300.00;
  String _selectedCategory = 'All';

  // Pre-loaded sample entries so the dashboard demonstrates immediate utility on launch
  final List<ExpenseItem> _expenses = [
    ExpenseItem(
      id: '1',
      title: 'Jeepney Fare to NTC',
      amount: 26.00,
      category: 'Commute',
      date: DateTime.now(),
      note: 'Morning round-trip commute',
    ),
    ExpenseItem(
      id: '2',
      title: 'Silog Lunch Meal',
      amount: 85.00,
      category: 'Food',
      date: DateTime.now(),
      note: 'Canteen lunch before lab class',
    ),
  ];

  final List<String> _categories = [
    'All',
    'Food',
    'Commute',
    'School Supplies',
    'Load/Data',
    'Others',
  ];

  /// Computes total spending across all logged items regardless of active filter
  double get _totalSpent =>
      _expenses.fold(0.0, (sum, item) => sum + item.amount);

  /// Calculates remaining daily baon
  double get _remainingBalance => _dailyAllowance - _totalSpent;

  /// Triggers a proactive warning state when remaining baon drops to 20% or below
  bool get _isLowBalance =>
      _dailyAllowance > 0 && _remainingBalance <= (_dailyAllowance * 0.20);

  /// [Week 16 - Dynamic Category Filtering]
  /// Filters the visible transaction list by selected category chip without
  /// altering the underlying full expense list used for balance calculations.
  List<ExpenseItem> get _filteredExpenses {
    if (_selectedCategory == 'All') return _expenses;
    return _expenses
        .where((item) => item.category == _selectedCategory)
        .toList();
  }

  /// [Week 14 & 17 - Asynchronous Navigation & Error Handling]
  /// Pushes AddExpenseScreen and awaits a newly validated ExpenseItem payload.
  /// Wrapped in try-catch to prevent unhandled navigation exceptions.
  Future<void> _navigateToAddExpense() async {
    try {
      final ExpenseItem? newExpense = await Navigator.push<ExpenseItem>(
        context,
        MaterialPageRoute(
          builder: (context) => AddExpenseScreen(
            remainingBalance: _remainingBalance,
          ),
        ),
      );

      if (newExpense != null) {
        setState(() {
          _expenses.insert(0, newExpense);
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Logged "${newExpense.title}" (₱${newExpense.amount.toStringAsFixed(2)})',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error opening expense form. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// [Week 17 - Input Validation for Daily Allowance Updates]
  /// Validates numeric parsing and positive bounds (₱1–₱50,000) before updating
  /// state so invalid text or negative numbers cannot corrupt the budget.
  Future<void> _showUpdateAllowanceDialog() async {
    final controller =
        TextEditingController(text: _dailyAllowance.toStringAsFixed(0));
    String? dialogError;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Set Daily Baon'),
              content: TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Daily Allowance (₱)',
                  prefixText: '₱ ',
                  errorText: dialogError,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final parsed = double.tryParse(controller.text.trim());
                    if (parsed == null || parsed <= 0 || parsed > 50000) {
                      setDialogState(() {
                        dialogError = 'Enter a valid amount (₱1 – ₱50,000)';
                      });
                      return;
                    }
                    setState(() {
                      _dailyAllowance = parsed;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Removes a deleted expense and notifies the user that the balance updated
  void _deleteExpense(String id) {
    setState(() {
      _expenses.removeWhere((item) => item.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Expense removed and balance updated.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Commute':
        return Icons.directions_bus;
      case 'School Supplies':
        return Icons.menu_book;
      case 'Load/Data':
        return Icons.wifi;
      default:
        return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BaonBuddy',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit Daily Baon',
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: _showUpdateAllowanceDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Remaining Balance Summary Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Card(
              color: _isLowBalance
                  ? colorScheme.errorContainer
                  : colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Remaining Daily Baon',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _isLowBalance
                                ? colorScheme.onErrorContainer
                                : colorScheme.onPrimaryContainer,
                          ),
                        ),
                        InkWell(
                          onTap: _showUpdateAllowanceDialog,
                          child: Chip(
                            label: Text(
                              'Budget: ₱${_dailyAllowance.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₱${_remainingBalance.toStringAsFixed(2)}',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _isLowBalance
                                    ? colorScheme.onErrorContainer
                                    : colorScheme.onPrimaryContainer,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total Spent: ₱${_totalSpent.toStringAsFixed(2)} (${_expenses.length} items)',
                      style: TextStyle(
                        fontSize: 13,
                        color: _isLowBalance
                            ? colorScheme.onErrorContainer
                            : colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // [Week 17 - Proactive Low-Balance & Overspending Alert Banner]
          // Automatically surfaces when remaining baon drops to 20% or below
          if (_isLowBalance)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Card(
                color: Colors.amber.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.amber.shade900,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _remainingBalance < 0
                              ? 'Overspent Alert: You exceeded your daily baon by ₱${_remainingBalance.abs().toStringAsFixed(2)}!'
                              : 'Low Baon Alert: Less than 20% of your daily allowance remains.',
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Horizontal Category Filter Chips
          SizedBox(
            height: 50,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 4),

          // Filtered Transaction List or Empty State Message
          Expanded(
            child: _filteredExpenses.isEmpty
                ? Center(
                    child: Text(
                      'No expenses recorded under "$_selectedCategory".',
                      style: TextStyle(color: colorScheme.outline),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: _filteredExpenses.length,
                    itemBuilder: (context, index) {
                      final item = _filteredExpenses[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.secondaryContainer,
                            child: Icon(
                              _categoryIcon(item.category),
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(item.category),
                          trailing: Text(
                            '-₱${item.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.error,
                              fontSize: 15,
                            ),
                          ),
                          // [Week 14 - Forward Navigation to Detail Screen]
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExpenseDetailScreen(
                                  expense: item,
                                  onDelete: () => _deleteExpense(item.id),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddExpense,
        icon: const Icon(Icons.add),
        label: const Text('Log Expense'),
      ),
    );
  }
}

/// [Week 16 & 17 - Form Validation & Error Handling Screen]
/// Intercepts blank titles, non-numeric text, and zero/negative amounts via
/// GlobalKey<FormState> before returning a valid ExpenseItem to HomeScreen.
class AddExpenseScreen extends StatefulWidget {
  final double remainingBalance;

  const AddExpenseScreen({super.key, required this.remainingBalance});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedCategory = 'Food';
  final List<String> _categories = [
    'Food',
    'Commute',
    'School Supplies',
    'Load/Data',
    'Others',
  ];

  @override
  void dispose() {
    // Disposes text controllers to prevent memory leaks when the route pops
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Validates inputs and pops the new ExpenseItem back to HomeScreen
  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final parsedAmount = double.parse(_amountController.text.trim());
      final newExpense = ExpenseItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        amount: parsedAmount,
        category: _selectedCategory,
        date: DateTime.now(),
        note: _noteController.text.trim(),
      );

      Navigator.pop(context, newExpense);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unexpected error saving expense. Check your inputs.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log New Expense'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Available Baon: ₱${widget.remainingBalance.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Expense Title *',
                  hintText: 'e.g., Pancit Canton & Drink',
                  prefixIcon: Icon(Icons.edit_note),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter what you spent on.';
                  }
                  if (value.trim().length < 2) {
                    return 'Title must be at least 2 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (₱) *',
                  hintText: 'e.g., 65.00',
                  prefixText: '₱ ',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an amount.';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null) {
                    return 'Invalid number format (use digits only).';
                  }
                  if (amount <= 0) {
                    return 'Amount must be greater than ₱0.';
                  }
                  if (amount > 50000) {
                    return 'Amount exceeds maximum single entry limit.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add context like location or shared bill',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.check),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Save Expense', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [Week 14 & 17 - Detail Screen & Destructive Action Confirmation]
/// Displays full transaction details and requires confirmation before deletion
/// so accidental taps do not erase student records.
class ExpenseDetailScreen extends StatelessWidget {
  final ExpenseItem expense;
  final VoidCallback onDelete;

  const ExpenseDetailScreen({
    super.key,
    required this.expense,
    required this.onDelete,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: Text(
          'Remove "${expense.title}" (₱${expense.amount.toStringAsFixed(2)}) from your log?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onDelete();
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}-${expense.date.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          IconButton(
            tooltip: 'Delete Expense',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.category.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  expense.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  '₱${expense.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
                const Divider(height: 32),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18),
                    const SizedBox(width: 8),
                    Text('Date Logged: $formattedDate'),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  expense.note.isEmpty
                      ? 'No additional notes provided.'
                      : expense.note,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}