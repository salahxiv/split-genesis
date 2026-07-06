import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ios_section.dart';
import '../../../l10n/app_localizations.dart';
import '../../members/providers/members_provider.dart';
import '../../members/screens/manage_members_screen.dart';
import '../models/group.dart';
import '../models/group_type.dart';
import '../providers/groups_provider.dart';

class GroupSettingsScreen extends ConsumerStatefulWidget {
  final Group group;
  const GroupSettingsScreen({super.key, required this.group});

  @override
  ConsumerState<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends ConsumerState<GroupSettingsScreen> {
  late String _name = widget.group.name;
  late String _type = widget.group.type;
  late final String _currency = widget.group.currency;

  Future<void> _editName() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: _name);
    final newName = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.groupSettingsRenameTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            placeholder: l10n.groupSettingsNameHint,
            textCapitalization: TextCapitalization.words,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.groupSettingsSave),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty && newName != _name) {
      await ref
          .read(groupsProvider.notifier)
          .renameGroup(widget.group.id, newName);
      setState(() => _name = newName);
    }
  }

  Future<void> _editSymbol() async {
    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  l10n.groupSettingsChooseSymbol,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
              ...groupTypes.map(
                (gt) => ListTile(
                  leading: Icon(gt.icon, color: gt.color),
                  title: Text(gt.label),
                  trailing: gt.key == _type
                      ? const Icon(CupertinoIcons.check_mark,
                          color: AppTheme.primaryColor)
                      : null,
                  onTap: () => Navigator.pop(ctx, gt.key),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && selected != _type) {
      // Backend update for type is out of scope (provider has no updateType yet);
      // Reflect choice locally only.
      setState(() => _type = selected);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.groupSettingsSymbolComingSoon),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _editCurrency() async {
    final l10n = AppLocalizations.of(context);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.groupSettingsCurrencyComingSoon),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmLeave() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.groupSettingsLeaveTitle),
        content: Text(l10n.groupSettingsLeaveMessage),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.groupSettingsLeave),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final userId = AuthService.instance.userId;
    if (userId == null) return;
    final members = await ref.read(membersProvider(widget.group.id).future);
    final me = members.where((m) => m.userId == userId).firstOrNull;
    if (me == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.groupSettingsNotMember)),
        );
      }
      return;
    }
    await ref.read(membersProvider(widget.group.id).notifier).deleteMember(me.id);
    if (!mounted) return;
    Navigator.of(context)
      ..pop()
      ..pop();
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.groupSettingsDeleteTitle),
        content: Text(l10n.groupSettingsDeleteMessage),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(groupsProvider.notifier).deleteGroup(widget.group.id);
    if (!mounted) return;
    Navigator.of(context)
      ..pop()
      ..pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final typeData = getGroupTypeData(_type);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.groupSettingsTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 32),
        children: [
          IosSection(
            children: [
              IosSectionRow(
                title: l10n.groupSettingsName,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _name,
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(170),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      CupertinoIcons.chevron_forward,
                      size: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(80),
                    ),
                  ],
                ),
                onTap: _editName,
              ),
              IosSectionRow(
                title: l10n.groupSettingsSymbol,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(typeData.icon, color: typeData.color, size: 20),
                    const SizedBox(width: 6),
                    Icon(
                      CupertinoIcons.chevron_forward,
                      size: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(80),
                    ),
                  ],
                ),
                onTap: _editSymbol,
              ),
              IosSectionRow(
                title: l10n.groupSettingsCurrency,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currency,
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(170),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      CupertinoIcons.chevron_forward,
                      size: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(80),
                    ),
                  ],
                ),
                onTap: _editCurrency,
              ),
            ],
          ),
          const SizedBox(height: 28),
          IosSection(
            children: [
              IosSectionRow(
                leading: const Icon(
                  CupertinoIcons.person_2,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                title: l10n.groupSettingsManageMembers,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ManageMembersScreen(groupId: widget.group.id),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          IosSection(
            children: [
              GestureDetector(
                onTap: _confirmLeave,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 13),
                  child: Text(
                    l10n.groupSettingsLeaveGroup,
                    style: const TextStyle(
                      color: AppTheme.negativeColor,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _confirmDelete,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 13),
                  child: Text(
                    l10n.groupSettingsDeleteGroup,
                    style: const TextStyle(
                      color: AppTheme.negativeColor,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
