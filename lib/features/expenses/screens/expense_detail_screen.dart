import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/error_handler.dart';
import '../../groups/models/group.dart';
import '../../members/providers/members_provider.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/expense_comment.dart';
import '../providers/expenses_provider.dart';
import 'add_expense_screen.dart';

final expenseCommentsProvider =
    FutureProvider.family<List<ExpenseComment>, String>((ref, expenseId) async {
  final db = await DatabaseHelper().database;
  final maps = await db.query(
    'expense_comments',
    where: 'expense_id = ?',
    whereArgs: [expenseId],
    orderBy: 'created_at ASC',
  );
  return maps.map((m) => ExpenseComment.fromMap(m)).toList();
});

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final Expense expense;
  final Group group;

  const ExpenseDetailScreen({
    super.key,
    required this.expense,
    required this.group,
  });

  @override
  ConsumerState<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final comment = ExpenseComment(
      id: const Uuid().v4(),
      expenseId: widget.expense.id,
      memberName: 'You',
      content: text,
      createdAt: DateTime.now(),
    );

    final db = await DatabaseHelper().database;
    await db.insert('expense_comments', comment.toMap());
    _commentController.clear();
    ref.invalidate(expenseCommentsProvider(widget.expense.id));
  }

  @override
  Widget build(BuildContext context) {
    final expense = widget.expense;
    final cat = getCategoryData(expense.category);
    final membersAsync = ref.watch(membersProvider(widget.group.id));
    final commentsAsync = ref.watch(expenseCommentsProvider(expense.id));
    final payersAsync = ref.watch(expensePayersByGroupProvider(widget.group.id));
    final memberMap = <String, String>{};
    membersAsync.whenData((members) {
      for (final m in members) {
        memberMap[m.id] = m.name;
      }
    });

    // Build payer names
    String payerName = memberMap[expense.paidById] ?? 'Unknown';
    payersAsync.whenData((payers) {
      final expPayers =
          payers.where((p) => p.expenseId == expense.id).toList();
      if (expPayers.isNotEmpty) {
        payerName = expPayers
            .map((p) => memberMap[p.memberId] ?? 'Unknown')
            .join(', ');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.pencil),
            onPressed: () {
              Navigator.push(
                context,
                slideUpRoute(AddExpenseScreen(
                  group: widget.group,
                  expense: expense,
                )),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount & description header — iOS grouped container
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: cat.color.withAlpha(30),
                            child: Icon(cat.icon, size: 28, color: cat.color),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            formatCurrency(expense.amount, expense.currency),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            expense.description,
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          // iOS Calendar-style info rows with Dividers
                          _InfoRow(
                            icon: Icons.person,
                            label: 'Paid by',
                            value: payerName,
                          ),
                          const Divider(height: 1),
                          _InfoRow(
                            icon: Icons.calendar_today,
                            label: 'Date',
                            value: DateFormat.yMMMd().format(expense.expenseDate),
                          ),
                          const Divider(height: 1),
                          _InfoRow(
                            icon: cat.icon,
                            label: 'Category',
                            value: cat.label,
                            valueColor: cat.color,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Split details
                  Text('Split Details',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  FutureBuilder(
                    future: ref
                        .read(expenseRepositoryProvider)
                        .getSplitsByExpense(expense.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CupertinoActivityIndicator());
                      }
                      final splits = snapshot.data!;
                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: splits.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final split = entry.value;
                            final name =
                                memberMap[split.memberId] ?? 'Unknown';
                            return Column(
                              children: [
                                if (idx > 0)
                                  const Divider(height: 1, indent: 56),
                                ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 16,
                                    child: Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  title: Text(name),
                                  trailing: Text(
                                    formatCurrency(
                                        split.amount, expense.currency),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Receipt photo
                  if (expense.receiptUrl != null && expense.receiptUrl!.isNotEmpty) ...[
                    Text('Receipt',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        expense.receiptUrl!,
                        fit: BoxFit.contain,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: 200,
                            alignment: Alignment.center,
                            child: CupertinoActivityIndicator(),
                          );
                        },
                        errorBuilder: (ctx, error, _) => Container(
                          height: 100,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.broken_image_outlined, size: 32),
                              const SizedBox(height: 4),
                              Text('Could not load receipt',
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 8),
                  // Comments section
                  Row(
                    children: [
                      const Icon(CupertinoIcons.chat_bubble_2, size: 20),
                      const SizedBox(width: 8),
                      Text('Comments',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  commentsAsync.when(
                    data: (comments) {
                      if (comments.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  CupertinoIcons.chat_bubble_2,
                                  size: 40,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(80),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sei der Erste, der kommentiert',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withAlpha(100),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: comments.map((comment) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        comment.memberName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        DateFormat.MMMd()
                                            .add_jm()
                                            .format(comment.createdAt),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(comment.content),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () =>
                        const Center(child: CupertinoActivityIndicator()),
                    error: (e, _) => AppErrorHandler.errorWidget(e),
                  ),
                ],
              ),
            ),
          ),
          // Comment input bar — Cupertino styling
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).viewPadding.bottom + 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                    color: Theme.of(context).dividerColor, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoTextField(
                    controller: _commentController,
                    placeholder: 'Add a comment...',
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _addComment(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addComment,
                  icon: Icon(Icons.send,
                      color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// iOS Calendar-style info row with label on left, value on right.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(120)),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withAlpha(150),
                ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}
