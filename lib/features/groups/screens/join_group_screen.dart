import 'package:flutter/cupertino.dart';
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

  const JoinGroupScreen(
      {super.key, required this.shareCode, this.prefetchedGroupData});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _joining = false;
  String? _error;
  Map<String, dynamic>? _groupData;

  bool _showQrScanner = false;
  bool _qrProcessing = false;
  final MobileScannerController _scannerController = MobileScannerController();

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _lookupGroup();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _fadeController.dispose();
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
      } catch (_) {}

      setState(() {
        _loading = false;
        _groupData = data;
      });
      _fadeController.forward();
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
    _fadeController.reset();

    try {
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
      _fadeController.forward();
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
      final repo = ref.read(groupRepositoryProvider);
      final group = await repo.getGroup(groupId);
      debugPrint(
          '[PERF] _joinGroup: getGroup done at ${swTotal.elapsedMilliseconds}ms');
      ref.invalidate(groupsProvider);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          slideRoute(GroupDetailScreen(group: group)),
        );
        debugPrint(
            '[PERF] _joinGroup: navigated at ${swTotal.elapsedMilliseconds}ms');
      }
      SyncService.instance.addUserToGroup(groupId);
      SyncService.instance.listenToGroup(groupId);
    } catch (e) {
      debugPrint(
          '[PERF] _joinGroup ERROR after ${swTotal.elapsedMilliseconds}ms: $e');
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
        setState(() {
          _qrProcessing = false;
          _showQrScanner = false;
          _error = 'Invalid QR code. Please scan a Split Genesis group QR.';
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

  // ── Avatar color from name ────────────────────────────────────
  Color _avatarColor(String name) {
    const colors = [
      Color(0xFF5856D6),
      Color(0xFFFF9500),
      Color(0xFFFF2D55),
      Color(0xFF34C759),
      Color(0xFF007AFF),
      Color(0xFFAF52DE),
    ];
    return name.isNotEmpty
        ? colors[name.codeUnitAt(0) % colors.length]
        : colors[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Group'),
        actions: [
          if (!_showQrScanner && !_loading)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: () {
                setState(() {
                  _showQrScanner = true;
                  _qrProcessing = false;
                  _error = null;
                });
                _scannerController.start();
              },
              child: const Icon(CupertinoIcons.qrcode_viewfinder, size: 26),
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
        CustomPaint(
          painter: _ScanFramePainter(
            color: Theme.of(context).colorScheme.primary,
          ),
          child: Container(),
        ),
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(160),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Point at a Splitty group QR code',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: GestureDetector(
            onTap: () {
              _scannerController.stop();
              setState(() => _showQrScanner = false);
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(120),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.xmark,
                  color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJoinContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(child: CupertinoActivityIndicator(radius: 14));
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.negativeColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(CupertinoIcons.exclamationmark_circle,
                  color: AppTheme.negativeColor, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Go Back'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _showQrScanner = true;
                    _qrProcessing = false;
                  });
                  _scannerController.start();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.qrcode_viewfinder, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Try QR Scanner', style: TextStyle(color: colorScheme.primary)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_groupData != null) {
      final groupName = _groupData!['name'] as String? ?? 'Group';
      final memberCount = (_groupData!['memberCount'] as int?) ?? 0;
      final avatarColor = _avatarColor(groupName);

      return FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Group avatar with gradient ring
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      avatarColor.withAlpha(200),
                      avatarColor,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: avatarColor.withAlpha(80),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  groupName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                groupName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Metadata row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MetaBadge(
                    icon: CupertinoIcons.tag,
                    label: widget.shareCode,
                    color: colorScheme.primary,
                    isDark: isDark,
                  ),
                  if (memberCount > 0) ...[
                    const SizedBox(width: 8),
                    _MetaBadge(
                      icon: CupertinoIcons.person_2,
                      label: '$memberCount member${memberCount == 1 ? '' : 's'}',
                      color: colorScheme.secondary,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _joining ? null : _joinGroup,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _joining
                      ? const CupertinoActivityIndicator(
                          color: Colors.white,
                          radius: 10,
                        )
                      : const Text(
                          'Join Group',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: colorScheme.onSurface.withAlpha(140)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _MetaBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 40 : 20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
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

    final dimPaint = Paint()..color = Colors.black.withAlpha(100);

    const frameSize = 240.0;
    const cornerLength = 32.0;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final left = cx - frameSize / 2;
    final top = cy - frameSize / 2;
    final right = cx + frameSize / 2;
    final bottom = cy + frameSize / 2;

    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, top), dimPaint);
    canvas.drawRect(
        Rect.fromLTRB(0, bottom, size.width, size.height), dimPaint);
    canvas.drawRect(Rect.fromLTRB(0, top, left, bottom), dimPaint);
    canvas.drawRect(Rect.fromLTRB(right, top, size.width, bottom), dimPaint);

    // Corners
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLength), paint);
    canvas.drawLine(
        Offset(right - cornerLength, top), Offset(right, top), paint);
    canvas.drawLine(Offset(right, top), Offset(right, top + cornerLength), paint);
    canvas.drawLine(
        Offset(left, bottom - cornerLength), Offset(left, bottom), paint);
    canvas.drawLine(Offset(left, bottom), Offset(left + cornerLength, bottom), paint);
    canvas.drawLine(
        Offset(right, bottom - cornerLength), Offset(right, bottom), paint);
    canvas.drawLine(
        Offset(right - cornerLength, bottom), Offset(right, bottom), paint);
  }

  @override
  bool shouldRepaint(_ScanFramePainter old) => old.color != color;
}
