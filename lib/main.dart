import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF0B0B0F),
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const AuraCinemaApp());
}

class AuraCinemaApp extends StatelessWidget {
  const AuraCinemaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AuraCinema',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0B0F),
      ),
      home: const AuraCinemaWebView(),
    );
  }
}

class AuraCinemaWebView extends StatefulWidget {
  const AuraCinemaWebView({super.key});

  @override
  State<AuraCinemaWebView> createState() => _AuraCinemaWebViewState();
}

class _AuraCinemaWebViewState extends State<AuraCinemaWebView> {
  late final WebViewController _controller;
  double _loadingProgress = 0;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B0B0F))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress / 100;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _loadingProgress = 1.0;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url.toLowerCase();

            // AuraCinema website ekata saha video streaming servers walata witharak ida denna
            if (url.contains('auracinema.duckdns.org') ||
                url.contains('streamtape.com') ||
                url.contains('tapecontent.net') ||
                url.contains('r2.dev') ||
                url.contains('youtube.com') ||
                url.contains('youtu.be')) {
              return NavigationDecision.navigate;
            }

            // Player eka slow karana external popup ad redirects block kirima
            return NavigationDecision.prevent;
          },
        ),
      );

    _initLoad();
  }

  Future<void> _initLoad() async {
    await _controller.clearCache();
    await _controller.loadRequest(Uri.parse('https://auracinema.duckdns.org'));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0B0F),
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_loadingProgress < 1.0)
                LinearProgressIndicator(
                  value: _loadingProgress,
                  minHeight: 3,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFF97316),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}