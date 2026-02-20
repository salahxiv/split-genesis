import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../balances/screens/group_detail_screen.dart';
import '../providers/groups_provider.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  final String shareCode;
  final Map<String, dynamic>? prefetchedGroupData;

  const JoinGroupScreen({super.key, required this.shareCode, this.prefetchedGroupData});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  bool _loading = true;
  bool _joining = false;
  String? _error;
  Map<String, dynamic>? _groupData;

  @override
  void initState() {
    super.initState();
    _lookupGroup();
  }

  Future<void> _lookupGroup() async {
    try {
      final data = widget.prefetchedGroupData ??
          await SyncService.instance.findGroupByShareCode(widget.shareCode);
      if (data == null) {
        setState(() {
          _loading = false;
          _error = 'No group found with code "${widget.shareCode}"';
        });
        return;
      }

      // Check if already have this group locally
      final repo = ref.read(groupRepositoryProvider);
      try {
        final existingGroup = await repo.getGroup(data['id'] as String);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            slideRoute(GroupDetailScreen(group: existingGroup)),
          );
          return;
        }
      } catch (_) {
        // Group not found locally — continue to show join UI
      }

      setState(() {
        _loading = false;
        _groupData = data;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Could not connect. Check your internet connection.';
      });
    }
  }

  Future<void> _joinGroup() async {
    if (_groupData == null) return;

    final swTotal = Stopwatch()..start();
    debugPrint('[PERF] _joinGroup START');
    setState(() => _joining = true);
    try {
      final groupId = _groupData!['id'] as String;

      // Fetch group via API-first repository (caches to SQLite)
      final repo = ref.read(groupRepositoryProvider);
      final group = await repo.getGroup(groupId);
      debugPrint('[PERF] _joinGroup: getGroup done at ${swTotal.elapsedMilliseconds}ms');

      // Refresh groups list
      ref.invalidate(groupsProvider);

      if (mounted) {
        debugPrint('[PERF] _joinGroup: getGroup done at ${swTotal.elapsedMilliseconds}ms');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            slideRoute(GroupDetailScreen(group: group)),
          );
          debugPrint('[PERF] _joinGroup: navigated at ${swTotal.elapsedMilliseconds}ms');
        }
      }

      // Run addUserToGroup and listenToGroup in background (non-blocking)
      SyncService.instance.addUserToGroup(groupId);
      SyncService.instance.listenToGroup(groupId);
    } catch (e) {
      debugPrint('[PERF] _joinGroup ERROR after ${swTotal.elapsedMilliseconds}ms: $e');
      setState(() {
        _joining = false;
        _error = 'Failed to join group. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Group')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64,
                            color: AppTheme.negativeColor.withAlpha(150)),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  )
                : _groupData != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Text(
                                (_groupData!['name'] as String? ?? '?')[0]
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _groupData!['name'] as String? ?? 'Group',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Code: ${widget.shareCode}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withAlpha(120),
                                  ),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _joining ? null : _joinGroup,
                                child: _joining
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Join Group'),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
      ),
    );
  }
}
