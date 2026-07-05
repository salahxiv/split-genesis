import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ios_section.dart';
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
    final controller = TextEditingController(text: _name);
    final newName = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Name ändern'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            placeholder: 'Gruppenname',
            textCapitalization: TextCapitalization.words,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Speichern'),
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
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Symbol wählen',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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
          const SnackBar(
            content: Text('Symbol-Speichern: in Kürze verfügbar'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _editCurrency() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Währungsänderung: in Kürze verfügbar'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmLeave() async {
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Gruppe verlassen?'),
        content: const Text(
          'Du wirst aus der Mitgliederliste entfernt. Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verlassen'),
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
          const SnackBar(content: Text('Du bist kein Mitglied dieser Gruppe.')),
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
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Gruppe löschen?'),
        content: const Text(
          'Alle Ausgaben, Mitglieder und Aktivitäten dieser Gruppe werden gelöscht. Das kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
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
    final typeData = getGroupTypeData(_type);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gruppen-Einstellungen',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 32),
        children: [
          IosSection(
            children: [
              IosSectionRow(
                title: 'Name',
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
                title: 'Symbol',
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
                title: 'Währung',
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
                title: 'Mitglieder verwalten',
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
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  child: Text(
                    'Gruppe verlassen',
                    style: TextStyle(
                      color: AppTheme.negativeColor,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _confirmDelete,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  child: Text(
                    'Gruppe löschen',
                    style: TextStyle(
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
