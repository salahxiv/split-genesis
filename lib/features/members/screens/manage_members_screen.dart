import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../expenses/repositories/expense_repository.dart';
import '../providers/members_provider.dart';

class ManageMembersScreen extends ConsumerStatefulWidget {
  final String groupId;

  const ManageMembersScreen({super.key, required this.groupId});

  @override
  ConsumerState<ManageMembersScreen> createState() =>
      _ManageMembersScreenState();
}

class _ManageMembersScreenState extends ConsumerState<ManageMembersScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    await ref.read(membersProvider(widget.groupId).notifier).addMember(name);
    _nameController.clear();
  }

  Future<void> _removeMember(String memberId, String memberName) async {
    final repo = ExpenseRepository();
    final hasExpenses = await repo.memberHasExpenses(memberId);

    if (!mounted) return;

    if (hasExpenses) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Cannot remove $memberName — they have linked expenses'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove "$memberName" from this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(membersProvider(widget.groupId).notifier)
          .deleteMember(memberId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'New Member',
                      hintText: 'e.g., Alice',
                      prefixIcon: Icon(Icons.person_add),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _addMember(),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.small(
                  heroTag: 'addMemberManage',
                  onPressed: _addMember,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: membersAsync.when(
              data: (members) {
                if (members.isEmpty) {
                  return const Center(child: Text('No members yet'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return Dismissible(
                      key: Key(member.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child:
                            const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        final repo = ExpenseRepository();
                        final hasExpenses =
                            await repo.memberHasExpenses(member.id);
                        if (hasExpenses && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Cannot remove ${member.name} — linked expenses'),
                            ),
                          );
                          return false;
                        }
                        return true;
                      },
                      onDismissed: (_) {
                        ref
                            .read(membersProvider(widget.groupId).notifier)
                            .deleteMember(member.id);
                      },
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            child: Text(
                              (member.name.isNotEmpty
                                      ? member.name[0]
                                      : '?')
                                  .toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Text(member.name),
                          trailing: IconButton(
                            icon: Icon(Icons.remove_circle_outline,
                                color: Colors.red.withAlpha(180)),
                            onPressed: () =>
                                _removeMember(member.id, member.name),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
