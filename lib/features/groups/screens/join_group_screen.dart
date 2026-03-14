import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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

  // QR Scanner state
  bool _showQrScanner = false;
  bool _qrProcessing = false;
  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _lookupGroup();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
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

  Future<void> _lookupGroupById(String groupId) async {
    setState(() {
      _loading = true;
      _error = null;
      _groupData = null;
    });

    try {
      // Check if already have this group locally
      final repo = ref.read(groupRepositoryProvider);
      try {
        final existingGroup = await repo.getGroup(groupId);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            slideRoute(GroupDetailScreen(group: existingGroup)),
          );
          return;
        }
      } catch (_) {}

      // Try to fetch from remote by ID
      final data = await SyncService.instance.findGroupById(groupId);
      if (data == null) {
        setState(() {
          _loading = false;
          _error = 'No group found with this QR code.';
        });
        return;
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

  void _onQrDetected(BarcodeCapture capture) {
    if (_qrProcessing) return;
    final rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _qrProcessing = true);
    _scannerController.stop();

    // Parse the QR value
    try {
      final uri = Uri.parse(rawValue);
      String? groupId;

      if (uri.scheme == 'splitgenesis' &&
          uri.host == 'join' &&
          uri.queryParameters.containsKey('groupId')) {
        groupId = uri.queryParameters['groupId'];
      }

      if (groupId != null && groupId.isNotEmpty) {
        setState(() => _showQrScanner = false);
        _lookupGroupById(groupId);
      } else {
        // Not a valid QR
        setState(() {
          _qrProcessing = false;
          _showQrScanner = false;
          _error = 'Invalid QR code. Please scan a Split Genesis group QR code.';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _qrProcessing = false;
        _showQrScanner = false;
        _error = 'Invalid QR code format.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Group'),
        actions: [
          if (!_showQrScanner && !_loading)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: 'Scan QR Code',
              onPressed: () {
                setState(() {
                  _showQrScanner = true;
                  _qrProcessing = false;
                  _error = null;
                });
                _scannerController.start();
              },
            ),
        ],
      ),
      body: _showQrScanner ? _buildQrScanner() : _buildJoinContent(),
    );
  }

  Widget _buildQrScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _onQrDetected,
        ),
        // Overlay with scan frame
        CustomPaint(
          painter: _ScanFramePainter(
            color: Theme.of(context).colorScheme.primary,
          ),
          child: Container(),
        ),
        // Info text at the bottom
        Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(160),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Point at a group QR code to join',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ),
        ),
        // Cancel button
        Positioned(
          top: 16,
          right: 16,
          child: IconButton.filled(
            icon: const Icon(Icons.close),
            onPressed: () {
              _scannerController.stop();
              setState(() => _showQrScanner = false);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildJoinContent() {
    return Padding(
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
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Try QR Scanner'),
                        onPressed: () {
                          setState(() {
                            _error = null;
                            _showQrScanner = true;
                            _qrProcessing = false;
                          });
                          _scannerController.start();
                        },
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
    );
  }
}

/// Custom painter for QR scan frame overlay
class _ScanFramePainter extends CustomPainter {
  final Color color;
  _ScanFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final dimPaint = Paint()
      ..color = Colors.black.withAlpha(100);

    const frameSize = 240.0;
    const cornerLength = 32.0;
    const cornerRadius = 6.0;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final left = cx - frameSize / 2;
    final top = cy - frameSize / 2;
    final right = cx + frameSize / 2;
    final bottom = cy + frameSize / 2;

    // Dim the outside
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, top), dimPaint);
    canvas.drawRect(Rect.fromLTRB(0, bottom, size.width, size.height), dimPaint);
    canvas.drawRect(Rect.fromLTRB(0, top, left, bottom), dimPaint);
    canvas.drawRect(Rect.fromLTRB(right, top, size.width, bottom), dimPaint);

    // Draw corners
    // Top-left
    canvas.drawLine(Offset(left + cornerRadius, top), Offset(left + cornerLength, top), paint);
    canvas.drawLine(Offset(left, top + cornerRadius), Offset(left, top + cornerLength), paint);
    // Top-right
    canvas.drawLine(Offset(right - cornerLength, top), Offset(right - cornerRadius, top), paint);
    canvas.drawLine(Offset(right, top + cornerRadius), Offset(right, top + cornerLength), paint);
    // Bottom-left
    canvas.drawLine(Offset(left + cornerRadius, bottom), Offset(left + cornerLength, bottom), paint);
    canvas.drawLine(Offset(left, bottom - cornerLength), Offset(left, bottom - cornerRadius), paint);
    // Bottom-right
    canvas.drawLine(Offset(right - cornerLength, bottom), Offset(right - cornerRadius, bottom), paint);
    canvas.drawLine(Offset(right, bottom - cornerLength), Offset(right, bottom - cornerRadius), paint);
  }

  @override
  bool shouldRepaint(_ScanFramePainter old) => old.color != color;
}
