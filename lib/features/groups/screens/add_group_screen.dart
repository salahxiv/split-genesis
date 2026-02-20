import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/navigation/app_routes.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/group_type.dart';
import '../providers/groups_provider.dart';
import '../../members/providers/members_provider.dart';
import '../../balances/screens/group_detail_screen.dart';

class AddGroupScreen extends ConsumerStatefulWidget {
  const AddGroupScreen({super.key});

  @override
  ConsumerState<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends ConsumerState<AddGroupScreen> {
  final _groupNameController = TextEditingController();
  final _memberNameController = TextEditingController();
  final _memberNames = <String>[];
  String _selectedType = 'other';
  String _selectedCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectedCurrency = ref.read(defaultCurrencyProvider);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _memberNameController.dispose();
    super.dispose();
  }

  void _addMember() {
    final name = _memberNameController.text.trim();
    if (name.isNotEmpty &&
        !_memberNames.any((n) => n.toLowerCase() == name.toLowerCase())) {
      setState(() {
        _memberNames.add(name);
        _memberNameController.clear();
      });
    }
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }
    if (_memberNames.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least 2 members')),
      );
      return;
    }

    try {
      final group = await ref.read(groupsProvider.notifier).addGroup(
            groupName,
            currency: _selectedCurrency,
            type: _selectedType,
          );

      final membersNotifier = ref.read(membersProvider(group.id).notifier);
      for (final name in _memberNames) {
        await membersNotifier.addMember(name);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          slideRoute(GroupDetailScreen(group: group)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating group: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'e.g., Weekend Trip',
                prefixIcon: Icon(Icons.group),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            const SizedBox(height: 20),
            // Group type picker
            Text('Type', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: groupTypes.map((type) {
                  final isSelected = _selectedType == type.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(type.icon, size: 18, color: isSelected ? type.color : null),
                      label: Text(type.label),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedType = type.key);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            // Currency picker
            DropdownButtonFormField<String>(
              value: _selectedCurrency,
              decoration: const InputDecoration(
                labelText: 'Currency',
                prefixIcon: Icon(Icons.attach_money),
              ),
              items: const [
                DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                DropdownMenuItem(value: 'EUR', child: Text('EUR (\u20AC)')),
                DropdownMenuItem(value: 'GBP', child: Text('GBP (\u00A3)')),
                DropdownMenuItem(value: 'JPY', child: Text('JPY (\u00A5)')),
                DropdownMenuItem(value: 'CAD', child: Text('CAD (\$)')),
                DropdownMenuItem(value: 'AUD', child: Text('AUD (\$)')),
                DropdownMenuItem(value: 'CHF', child: Text('CHF')),
                DropdownMenuItem(value: 'CNY', child: Text('CNY (\u00A5)')),
                DropdownMenuItem(value: 'INR', child: Text('INR (\u20B9)')),
                DropdownMenuItem(value: 'MXN', child: Text('MXN (\$)')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _selectedCurrency = v);
              },
            ),
            const SizedBox(height: 28),
            Text(
              'Members',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _memberNameController,
                    decoration: const InputDecoration(
                      labelText: 'Member Name',
                      hintText: 'e.g., Alice',
                      prefixIcon: Icon(Icons.person_add),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _addMember(),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.small(
                  heroTag: 'addMember',
                  onPressed: _addMember,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _memberNames.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(60),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Add at least 2 members',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(100),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _memberNames.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Text(
                                (_memberNames[index].isNotEmpty
                                        ? _memberNames[index][0]
                                        : '?')
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(_memberNames[index]),
                            trailing: IconButton(
                              icon: Icon(Icons.close,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(120)),
                              onPressed: () {
                                setState(() {
                                  _memberNames.removeAt(index);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _memberNames.length >= 2 ? _createGroup : null,
              child: Text(
                'Create Group (${_memberNames.length} members)',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
