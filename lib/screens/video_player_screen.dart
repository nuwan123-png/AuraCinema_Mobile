import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
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
  WebViewController? _webController;
  VideoPlayerController? _nativeController;

  late final String _targetUrl;
  bool _isLoading = true;
  bool _isLandscape = false;
  bool _useNativePlayer = false;
  bool _showControls = true;
  bool _isMuted = false;
  double _playbackSpeed = 1.0;

  Timer? _extractTimer;
  Timer? _hideControlsTimer;
  int _extractAttempts = 0;
  bool _isTryingNativeInit = false;

  static const Color _accentOrange = Color(0xFFFF9F1C);
  static const Color _bgDark = Color(0xFF0B0B0F);

  static const _streamtapeDomains = [
    'streamtape',
    'stape',
    'strcloud',
    'tapecontent',
    'strtape',
  ];

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
    'highperformanceformat.com',
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

  bool _isStreamtape(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return _streamtapeDomains.any((d) => host.contains(d));
  }

  bool _isDirectVideoFile(String url) {
    final lower = url.toLowerCase().split('?').first;
    return lower.endsWith('.mp4') ||
        lower.endsWith('.m3u8') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mov');
  }

  String _normalizeStreamtapeEmbedUrl(String url) {
    return url.replaceFirst(
      RegExp(r'(streamtape\.[a-z]+|stape\.[a-z]+|strcloud\.[a-z]+)/v/'),
      r'$1/e/',
    );
  }

  @override
  void initState() {
    super.initState();
    _targetUrl = _resolvedUrl(widget.videoUrl);

    if (_isDirectVideoFile(_targetUrl)) {
      _initNativePlayer(_targetUrl);
    } else if (_isStreamtape(_targetUrl)) {
      _initStreamtape(_normalizeStreamtapeEmbedUrl(_targetUrl));
    } else {
      _initWebView(_targetUrl);
    }
  }

  Future<void> _initNativePlayer(
    String streamUrl, {
    Map<String, String>? headers,
  }) async {
    if (_isTryingNativeInit) return;
    _isTryingNativeInit = true;

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(streamUrl),
        httpHeaders: headers ?? const {},
      );

      await controller.initialize().timeout(const Duration(seconds: 7));
      if (!mounted) {
        await controller.dispose();
        return;
      }

      _extractTimer?.cancel();
      _webController?.loadRequest(Uri.parse('about:blank'));

      setState(() {
        _nativeController = controller;
        _useNativePlayer = true;
        _isLoading = false;
        _showControls = true;
      });

      await controller.play();
      _startHideControlsTimer();
    } catch (_) {
      // Native stream fail වුණොත් WebView player එකෙන්ම play වෙන්න ඉඩ දෙන්න
      _isTryingNativeInit = false;
      if (!mounted) return;
      if (_webController == null) {
        _initWebView(_targetUrl);
      } else {
        setState(() {
          _useNativePlayer = false;
          _isLoading = false;
        });
      }
    }
  }

  void _initStreamtape(String embedUrl) {
    _initWebView(embedUrl);

    _extractTimer = Timer.periodic(const Duration(milliseconds: 600), (_) async {
      if (!mounted || _useNativePlayer) {
        _extractTimer?.cancel();
        return;
      }

      _extractAttempts++;
      if (_extractAttempts > 12) {
        _extractTimer?.cancel();
        return;
      }

      await _tryExtractStreamtapeMp4();
    });
  }

  Future<void> _tryExtractStreamtapeMp4() async {
    final controller = _webController;
    if (controller == null || _isTryingNativeInit) return;

    try {
      final rawResult = await controller.runJavaScriptReturningResult('''
        (function() {
          try {
            var videoEl = document.querySelector('video');
            var sourceEl = document.querySelector('video source');
            var candidates = [
              videoEl ? videoEl.currentSrc : '',
              videoEl ? videoEl.src : '',
              sourceEl ? sourceEl.src : '',
              document.getElementById('robotlink') ? document.getElementById('robotlink').textContent : '',
              document.getElementById('norobotlink') ? document.getElementById('norobotlink').textContent : '',
              document.getElementById('ideoolink') ? document.getElementById('ideoolink').textContent : ''
            ];
            for (var i = 0; i < candidates.length; i++) {
              var val = (candidates[i] || '').trim();
              if (val && (val.includes('get_video?') || val.includes('tapecontent') || val.includes('.mp4'))) {
                return JSON.stringify({
                  url: val,
                  ua: navigator.userAgent
                });
              }
            }
          } catch (e) {}
          return '';
        })();
      ''');

      dynamic decoded = rawResult;
      if (decoded is String && decoded.isNotEmpty) {
        decoded = jsonDecode(decoded);
        if (decoded is String && decoded.isNotEmpty) {
          decoded = jsonDecode(decoded);
        }
      }

      if (decoded is Map && decoded['url'] != null) {
        String extractedUrl = decoded['url'].toString().trim();
        final userAgent = decoded['ua']?.toString() ?? '';

        if (extractedUrl.isEmpty || extractedUrl.startsWith('blob:')) return;
        if (extractedUrl.startsWith('//')) {
          extractedUrl = 'https:$extractedUrl';
        } else if (extractedUrl.startsWith('/')) {
          extractedUrl = 'https://streamtape.com$extractedUrl';
        }
        if (extractedUrl.contains('get_video?') &&
            !extractedUrl.contains('stream=1')) {
          extractedUrl = '$extractedUrl&stream=1';
        }

        await _initNativePlayer(
          extractedUrl,
          headers: {
            'Referer': 'https://streamtape.com/',
            if (userAgent.isNotEmpty) 'User-Agent': userAgent,
          },
        );
      }
    } catch (_) {
      // Ignore while DOM is loading
    }
  }

  void _initWebView(String urlToLoad) {
    final isStape = _isStreamtape(urlToLoad);

    final controller = WebViewController()
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

            // Streamtape page එකකදී external ad redirects 100% නවත්වන්න
            if (isStape &&
                (url.startsWith('http://') || url.startsWith('https://'))) {
              final isAllowedStape =
                  _streamtapeDomains.any((d) => host.contains(d));
              if (!isAllowedStape) {
                return NavigationDecision.prevent;
              }
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
          onPageStarted: (_) {
            _injectSafeAntiAdScript();
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            _injectSafeAntiAdScript();
            if (isStape) {
              _tryExtractStreamtapeMp4();
            }
          },
        ),
      );

    if (_isYouTube(urlToLoad)) {
      controller.loadRequest(
        Uri.parse(urlToLoad),
        headers: const {'Referer': 'https://auracinema.duckdns.org/'},
      );
    } else {
      controller.loadRequest(Uri.parse(urlToLoad));
    }

    _webController = controller;
  }

  // Player DOM එකට හානි නොකර Popups සහ External Ad Overlays විතරක් අයින් කරන Script එක
  void _injectSafeAntiAdScript() {
    _webController?.runJavaScript('''
      (function() {
        try {
          window.open = function() { return null; };
          window.alert = function() {};
          window.confirm = function() { return true; };
          window.prompt = function() { return null; };

          function cleanSafe() {
            // 1. External ad links (<a> tags) පමණක් disable කිරීම
            document.querySelectorAll('a[target="_blank"], a[href^="http"]').forEach(function(a) {
              var href = (a.href || '').toLowerCase();
              if (href &&
                  !href.includes('streamtape') &&
                  !href.includes('stape') &&
                  !href.includes('strcloud') &&
                  !href.includes('tapecontent') &&
                  !href.includes('youtube') &&
                  !href.includes('auracinema')) {
                a.removeAttribute('href');
                a.setAttribute('target', '_self');
                a.style.pointerEvents = 'none';
              }
            });

            // 2. Third-party ad iframes පමණක් ඉවත් කිරීම
            document.querySelectorAll('iframe').forEach(function(f) {
              var s = (f.src || '').toLowerCase();
              if (s &&
                  !s.includes('streamtape') &&
                  !s.includes('stape') &&
                  !s.includes('youtube')) {
                f.remove();
              }
            });
          }

          cleanSafe();
          if (!window.__auraSafeCleaner) {
            window.__auraSafeCleaner = true;
            setInterval(cleanSafe, 1000);
          }
        } catch (e) {}
      })();
    ''');
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted &&
          _nativeController != null &&
          _nativeController!.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _startHideControlsTimer();
    }
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

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Future<void> _seekRelative(int seconds) async {
    final c = _nativeController;
    if (c == null) return;
    final current = c.value.position;
    final max = c.value.duration;
    var target = current + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (target > max) target = max;
    await c.seekTo(target);
    _startHideControlsTimer();
  }

  Future<void> _cycleSpeed() async {
    final c = _nativeController;
    if (c == null) return;
    const speeds = [1.0, 1.25, 1.5, 2.0];
    final nextIdx = (speeds.indexOf(_playbackSpeed) + 1) % speeds.length;
    final nextSpeed = speeds[nextIdx];
    await c.setPlaybackSpeed(nextSpeed);
    setState(() => _playbackSpeed = nextSpeed);
    _startHideControlsTimer();
  }

  Widget _buildNativePlayerBody() {
    final controller = _nativeController!;

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final duration = value.duration;
        final position = value.position;
        final totalMs = duration.inMilliseconds;
        final currentMs =
            position.inMilliseconds.clamp(0, totalMs > 0 ? totalMs : 1);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio:
                      value.aspectRatio > 0 ? value.aspectRatio : 16 / 9,
                  child: VideoPlayer(controller),
                ),
              ),
              if (value.isBuffering)
                const Center(
                  child: CircularProgressIndicator(color: _accentOrange),
                ),
              if (_showControls)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.75),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.85),
                      ],
                      stops: const [0.0, 0.25, 0.7, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              if (_isLandscape)
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              if (_isLandscape)
                                Expanded(
                                  child: Text(
                                    widget.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              else
                                const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF10B981).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFF10B981),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Text(
                                  'AD-FREE',
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              iconSize: 36,
                              color: Colors.white,
                              icon: const Icon(Icons.replay_10_rounded),
                              onPressed: () => _seekRelative(-10),
                            ),
                            const SizedBox(width: 28),
                            Container(
                              decoration: const BoxDecoration(
                                color: _accentOrange,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                iconSize: 42,
                                color: Colors.black,
                                icon: Icon(
                                  value.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                                onPressed: () async {
                                  if (value.isPlaying) {
                                    await controller.pause();
                                    _hideControlsTimer?.cancel();
                                  } else {
                                    await controller.play();
                                    _startHideControlsTimer();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 28),
                            IconButton(
                              iconSize: 36,
                              color: Colors.white,
                              icon: const Icon(Icons.forward_10_rounded),
                              onPressed: () => _seekRelative(10),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: _accentOrange,
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: _accentOrange,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 12,
                                  ),
                                  trackHeight: 3,
                                ),
                                child: Slider(
                                  value: currentMs.toDouble(),
                                  min: 0,
                                  max: (totalMs > 0 ? totalMs : 1).toDouble(),
                                  onChanged: (val) {
                                    controller.seekTo(
                                      Duration(milliseconds: val.toInt()),
                                    );
                                    _startHideControlsTimer();
                                  },
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${_formatDuration(position)} / ${_formatDuration(duration)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: _cycleSpeed,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white12,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${_playbackSpeed}x',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 34,
                                      minHeight: 34,
                                    ),
                                    icon: Icon(
                                      _isMuted
                                          ? Icons.volume_off_rounded
                                          : Icons.volume_up_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      final next = !_isMuted;
                                      await controller.setVolume(next ? 0 : 1);
                                      setState(() => _isMuted = next);
                                      _startHideControlsTimer();
                                    },
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 34,
                                      minHeight: 34,
                                    ),
                                    icon: Icon(
                                      _isLandscape
                                          ? Icons.fullscreen_exit_rounded
                                          : Icons.fullscreen_rounded,
                                      color: _accentOrange,
                                      size: 24,
                                    ),
                                    onPressed: _toggleOrientation,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _extractTimer?.cancel();
    _hideControlsTimer?.cancel();
    _nativeController?.dispose();
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
              backgroundColor: _bgDark,
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
                    color: _accentOrange,
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
          if (_useNativePlayer && _nativeController != null)
            _buildNativePlayerBody()
          else if (_webController != null)
            WebViewWidget(controller: _webController!),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: _accentOrange),
            ),
          if (_isLandscape && !_useNativePlayer)
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
                      color: _accentOrange,
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