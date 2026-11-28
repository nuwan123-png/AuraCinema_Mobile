import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/aura_theme.dart';
import 'aura_blue_logo.dart';
import 'glass_widgets.dart';

class AppUpdateNoticeBanner extends StatefulWidget {
  const AppUpdateNoticeBanner({super.key});

  @override
  State<AppUpdateNoticeBanner> createState() => _AppUpdateNoticeBannerState();
}

class _AppUpdateNoticeBannerState extends State<AppUpdateNoticeBanner> {
  static bool _hasShownPopupThisSession = false;

  bool _isUpdating = false;
  String _title = 'AuraCinema නව Update එකක්!';
  String _message =
      'මේ වෙලාවේ App එකට අලුත් update එකක් නිකුත් වෙමින් පවතී. App එක open කරගෙන තත්පර 10ක් පමණ තියලා, සම්පූර්ණයෙන්ම close කරලා ආපහු open කළාම අලුත් update එක ලැබේවි.';

  @override
  void initState() {
    super.initState();
    _checkUpdateStatus();
  }

  Future<void> _checkUpdateStatus() async {
    try {
      final res = await http
          .get(
            Uri.parse('https://auracinema.duckdns.org/api/v1/app-update-status'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['is_updating'] == true) {
          if (!mounted) return;
          setState(() {
            _isUpdating = true;
            if (decoded['title'] != null &&
                decoded['title'].toString().trim().isNotEmpty) {
              _title = decoded['title'].toString();
            }
            if (decoded['message'] != null &&
                decoded['message'].toString().trim().isNotEmpty) {
              _message = decoded['message'].toString();
            }
          });

          if (!_hasShownPopupThisSession) {
            _hasShownPopupThisSession = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _showUpdateGuideDialog();
            });
          }
        }
      }
    } catch (_) {
      // Offline නම් silently skip වේ
    }
  }

  void _showUpdateGuideDialog() {
    final glass = Theme.of(context).extension<AuraGlassColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.78 : 0.45),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 410),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: glass.modalSurface.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.45),
                    width: 1.3,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const AuraBlueLogo(size: 26),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _title,
                            style: TextStyle(
                              color: glass.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: glass.textSecondary,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              const Color(0xFF38BDF8).withValues(alpha: 0.28),
                        ),
                      ),
                      child: Text(
                        _message,
                        style: TextStyle(
                          color: glass.textPrimary,
                          fontSize: 13,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _stepRow(
                      glass: glass,
                      step: '1',
                      text:
                          'App එක open කරගෙන තත්පර 10ක් පමණ සාමාන්‍ය පරිදි තියන්න (Update එක download වීමට).',
                    ),
                    const SizedBox(height: 8),
                    _stepRow(
                      glass: glass,
                      step: '2',
                      text:
                          'ඉන්පසු App එක සම්පූර්ණයෙන්ම Close (Recent Apps වලින් ඉවත්) කර නැවත Open කරන්න.',
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text(
                        'හරි, තේරුණා',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _stepRow({
    required AuraGlassColors glass,
    required String step,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: glass.glassFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: glass.glassBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: const Color(0xFF2563EB),
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: glass.textPrimary.withValues(alpha: 0.92),
                fontSize: 12.2,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUpdating) return const SizedBox.shrink();

    final glass = Theme.of(context).extension<AuraGlassColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
      child: GlassPanel(
        borderRadius: 16,
        blur: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        onTap: _showUpdateGuideDialog,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.system_update_rounded,
                color: Color(0xFF38BDF8),
                size: 19,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: TextStyle(
                      color: glass.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'තත්පර 10ක් තියලා App එක close කර නැවත open කරන්න. (විස්තර සඳහා tap කරන්න)',
                    style: TextStyle(
                      color: glass.textSecondary,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF38BDF8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}