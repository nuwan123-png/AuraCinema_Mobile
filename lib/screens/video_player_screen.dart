import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String title;
  final String videoUrl;

  const VideoPlayerScreen({
    super.key,
    required this.title,
    required this.videoUrl,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final WebViewController _controller;
  late final String _targetUrl;
  bool _isLoading = true;
  bool _isLandscape = false;

  static const _blockedHosts = [
    'doubleclick.net',
    'googlesyndication.com',
    'googleadservices.com',
    'adservice.google.',
    'popads.net',
    'popcash.net',
    'propellerads.com',
    'hilltopads.net',
    'exoclick.com',
    'exosrv.com',
    'juicyads.com',
    'trafficjunky.',
    'clickadu.com',
    'adsterra.com',
    'tsyndicate.com',
    'moatads.com',
    'revcontent.com',
    'mgid.com',
    'outbrain.com',
    'taboola.com',
    'yllix.com',
    'admaven.com',
  ];

  String _resolvedUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return 'https://auracinema.duckdns.org$trimmed';
    }
    return 'https://pub-63df71478cdb4786a59eae41e51254b1.r2.dev/$trimmed';
  }

  bool _isYouTube(String url) {
    final lower = url.toLowerCase();
    return lower.contains('youtube.com') || lower.contains('youtu.be');
  }

  Future<void> _setLandscape(bool enable) async {
    if (enable) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Future<void> _toggleOrientation() async {
    final next = !_isLandscape;
    setState(() => _isLandscape = next);
    await _setLandscape(next);
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(_targetUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _injectAntiAdScript() {
    _controller.runJavaScript('''
      (function() {
        try {
          window.open = function() { return null; };
          window.alert = function() {};
          window.confirm = function() { return true; };
          window.prompt = function() { return null; };
          document.querySelectorAll('a[target="_blank"]').forEach(function(a) {
            a.setAttribute('target', '_self');
          });
          document.querySelectorAll('video').forEach(function(v) {
            v.removeAttribute('poster');
          });
        } catch (e) {}
      })();
    ''');
  }

  @override
  void initState() {
    super.initState();
    _targetUrl = _resolvedUrl(widget.videoUrl);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url.toLowerCase();
            final host = Uri.tryParse(url)?.host ?? '';

            if (_blockedHosts.any((b) => host.contains(b) || url.contains(b))) {
              return NavigationDecision.prevent;
            }

            if (url.startsWith('http://') ||
                url.startsWith('https://') ||
                url.startsWith('data:') ||
                url.startsWith('about:') ||
                url.startsWith('blob:')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            _injectAntiAdScript();
          },
        ),
      );

    if (_isYouTube(_targetUrl)) {
      _controller.loadRequest(
        Uri.parse(_targetUrl),
        headers: const {
          'Referer': 'https://auracinema.duckdns.org/',
        },
      );
    } else {
      _controller.loadRequest(Uri.parse(_targetUrl));
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isLandscape
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF0B0B0F),
              foregroundColor: Colors.white,
              title: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.open_in_browser_rounded,
                    color: Colors.white70,
                    size: 22,
                  ),
                  tooltip: 'Open External',
                  onPressed: _openExternally,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.fullscreen_rounded,
                    color: Color(0xFFFF9F1C),
                    size: 26,
                  ),
                  tooltip: 'Horizontal Fullscreen',
                  onPressed: _toggleOrientation,
                ),
              ],
            ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF9F1C)),
            ),
          if (_isLandscape)
            Positioned(
              top: 14,
              right: 14,
              child: SafeArea(
                child: Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                  child: IconButton(
                    icon: const Icon(
                      Icons.fullscreen_exit_rounded,
                      color: Color(0xFFFF9F1C),
                      size: 26,
                    ),
                    tooltip: 'Exit Fullscreen',
                    onPressed: _toggleOrientation,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}