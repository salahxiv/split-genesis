import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../expenses/repositories/expense_repository.dart';
import '../providers/members_provider.dart';
import '../../../core/utils/error_handler.dart';

class ManageMembersScreen extends ConsumerStatefulWidget {
  final String groupId;

  const ManageMembersScreen({super.key, required this.groupId});

  @override
  ConsumerState<ManageMembersScreen> createState() =>
      _ManageMembersScreenState();
}

class _ManageMembersScreenState extends ConsumerState<ManageMembersScreen> {
  final _nameController = TextEditingController();
  final _focusNode = FocusNode();
  bool _adding = false;

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _adding = true);
    try {
      await ref.read(membersProvider(widget.groupId).notifier).addMember(name);
      _nameController.clear();
      _focusNode.requestFocus();
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _confirmRemoveMember(String memberId, String memberName) async {
    final repo = ExpenseRepository();
    final hasExpenses = await repo.memberHasExpenses(memberId);

    if (!mounted) return;

    if (hasExpenses) {
      _showCannotRemoveToast(memberName);
      return;
    }

    bool? confirmed;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Remove Member'),
        message: Text('Remove "$memberName" from this group?'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              confirmed = true;
              Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            confirmed = false;
            Navigator.pop(ctx);
          },
          child: const Text('Cancel'),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(membersProvider(widget.groupId).notifier)
          .deleteMember(memberId);
    }
  }

  void _showCannotRemoveToast(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cannot remove $name — they have linked expenses'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Color _avatarColor(String name) {
    const colors = [
      Color(0xFF5856D6),
      Color(0xFFFF9500),
      Color(0xFFFF2D55),
      Color(0xFF34C759),
      Color(0xFF007AFF),
      Color(0xFFAF52DE),
      Color(0xFFFF6B35),
      Color(0xFF30B0C7),
    ];
    return name.isNotEmpty
        ? colors[name.codeUnitAt(0) % colors.length]
        : colors[0];
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersProvider(widget.groupId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
        title: const Text('Members'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // ── Section: Add Member ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(
              'ADD MEMBER',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: colorScheme.onSurface.withAlpha(120),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 30 : 8),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.person_add,
                      size: 17,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CupertinoTextField.borderless(
                      controller: _nameController,
                      focusNode: _focusNode,
                      placeholder: 'New member name…',
                      textCapitalization: TextCapitalization.words,
                      onSubmitted: (_) => _addMember(),
                      style: TextStyle(color: colorScheme.onSurface),
                      placeholderStyle: TextStyle(
                        color: colorScheme.onSurface.withAlpha(80),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _adding
                      ? const CupertinoActivityIndicator(radius: 10)
                      : CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 34,
                          onPressed: _addMember,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 18),
                          ),
                        ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── Section: Current Members ─────────────────────────
          membersAsync.when(
            data: (members) {
              if (members.isEmpty) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                      child: Row(
                        children: [
                          Text(
                            'MEMBERS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                              color:
                                  colorScheme.onSurface.withAlpha(120),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 40, horizontal: 24),
                      child: Column(
                        children: [
                          Icon(
                            CupertinoIcons.person_2,
                            size: 48,
                            color: colorScheme.onSurface.withAlpha(60),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No members yet',
                            style: TextStyle(
                              color: colorScheme.onSurface.withAlpha(100),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'MEMBERS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            color: colorScheme.onSurface.withAlpha(120),
                          ),
                        ),
                        Text(
                          '${members.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withAlpha(100),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color:
                          isDark ? const Color(0xFF2C2C2E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withAlpha(isDark ? 30 : 8),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: List.generate(members.length, (i) {
                        final member = members[i];
                        final isLast = i == members.length - 1;
                        final color = _avatarColor(member.name);

                        return Column(
                          children: [
                            Dismissible(
                              key: Key(member.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemRed,
                                  borderRadius: BorderRadius.vertical(
                                    top: i == 0
                                        ? const Radius.circular(12)
                                        : Radius.zero,
                                    bottom: isLast
                                        ? const Radius.circular(12)
                                        : Radius.zero,
                                  ),
                                ),
                                child: const Icon(CupertinoIcons.delete,
                                    color: Colors.white, size: 20),
                              ),
                              confirmDismiss: (_) async {
                                final repo = ExpenseRepository();
                                final hasExpenses = await repo
                                    .memberHasExpenses(member.id);
                                if (hasExpenses && context.mounted) {
                                  _showCannotRemoveToast(member.name);
                                  return false;
                                }
                                return true;
                              },
                              onDismissed: (_) {
                                ref
                                    .read(membersProvider(widget.groupId)
                                        .notifier)
                                    .deleteMember(member.id);
                              },
                              child: CupertinoListTile(
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    (member.name.isNotEmpty
                                            ? member.name[0]
                                            : '?')
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  member.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                                trailing: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  minSize: 30,
                                  onPressed: () => _confirmRemoveMember(
                                      member.id, member.name),
                                  child: Icon(
                                    CupertinoIcons.minus_circle_fill,
                                    color: CupertinoColors.systemRed
                                        .resolveFrom(context),
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                            if (!isLast)
                              Divider(
                                height: 1,
                                thickness: 0.5,
                                indent: 56,
                                color: isDark
                                    ? Colors.white.withAlpha(12)
                                    : Colors.black.withAlpha(12),
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'Swipe left to remove a member.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withAlpha(80),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () =>
                const Center(child: CupertinoActivityIndicator()),
            error: (e, _) => AppErrorHandler.errorWidget(e),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
