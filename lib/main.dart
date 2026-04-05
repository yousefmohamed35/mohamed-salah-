import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مستر محمد صلاح',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _webViewController;
  double _loadingProgress = 0.0;
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasLoadedSuccessfully = false;
  final String _initialUrl = 'https://mohamedsalah.anmka.com/';

  @override
  void initState() {
    super.initState();
    _initializeWebViewController();
    _initializeScreenProtector();
  }

  void _initializeWebViewController() {
    late final PlatformWebViewControllerCreationParams params;
    if (defaultTargetPlatform == TargetPlatform.android) {
      params = AndroidWebViewControllerCreationParams();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _webViewController = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(true);

    // Platform-specific settings
    if (_webViewController.platform is AndroidWebViewController) {
      (_webViewController.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _webViewController.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (url) {
          debugPrint('🚀 Page started loading: $url');
          debugPrint('📋 Request headers: X-App-Source: anmka');
          if (mounted) {
            setState(() {
              _loadingProgress = 0.0;
              _isLoading = true;
              _errorMessage = null;
            });
          }
        },
        onPageFinished: (url) {
          debugPrint('✅ Page finished loading: $url');
          // Enable media autoplay for all videos and iframes
          _webViewController.runJavaScript('''
              (function() {
                try {
                  // Enable autoplay for all video elements
                  var videos = document.querySelectorAll('video');
                  videos.forEach(function(video) {
                    video.setAttribute('playsinline', '');
                    video.setAttribute('webkit-playsinline', '');
                    video.setAttribute('x5-playsinline', '');
                    video.setAttribute('x5-video-player-type', 'h5');
                    video.setAttribute('x5-video-player-fullscreen', 'true');
                    video.setAttribute('x5-video-orientation', 'portraint');
                    video.muted = false;
                    video.controls = true;
                    // Try to play the video
                    video.play().catch(function(e) {
                      console.log('Video autoplay prevented:', e);
                    });
                  });
                  
                  // Enable autoplay for all iframes (YouTube, Vimeo, etc.)
                  var iframes = document.querySelectorAll('iframe');
                  iframes.forEach(function(iframe) {
                    var currentAllow = iframe.getAttribute('allow') || '';
                    var newAllow = 'autoplay; encrypted-media; picture-in-picture; fullscreen; accelerometer; gyroscope';
                    if (!currentAllow.includes('autoplay')) {
                      iframe.setAttribute('allow', newAllow);
                    }
                    // For YouTube iframes, ensure proper attributes
                    if (iframe.src && (iframe.src.includes('youtube.com') || iframe.src.includes('youtu.be'))) {
                      iframe.setAttribute('allowfullscreen', '');
                      iframe.setAttribute('frameborder', '0');
                    }
                  });
                  
                  // Enable autoplay for dynamically added videos
                  var observer = new MutationObserver(function(mutations) {
                    mutations.forEach(function(mutation) {
                      mutation.addedNodes.forEach(function(node) {
                        if (node.nodeType === 1) {
                          if (node.tagName === 'VIDEO') {
                            node.setAttribute('playsinline', '');
                            node.setAttribute('webkit-playsinline', '');
                            node.muted = false;
                            node.play().catch(function(e) {
                              console.log('Dynamic video autoplay prevented:', e);
                            });
                          } else if (node.tagName === 'IFRAME') {
                            var currentAllow = node.getAttribute('allow') || '';
                            if (!currentAllow.includes('autoplay')) {
                              node.setAttribute('allow', 'autoplay; encrypted-media; picture-in-picture; fullscreen');
                            }
                          }
                          // Check for videos/iframes inside added nodes
                          var videos = node.querySelectorAll && node.querySelectorAll('video');
                          if (videos) {
                            videos.forEach(function(video) {
                              video.setAttribute('playsinline', '');
                              video.setAttribute('webkit-playsinline', '');
                              video.muted = false;
                            });
                          }
                          var iframes = node.querySelectorAll && node.querySelectorAll('iframe');
                          if (iframes) {
                            iframes.forEach(function(iframe) {
                              var currentAllow = iframe.getAttribute('allow') || '';
                              if (!currentAllow.includes('autoplay')) {
                                iframe.setAttribute('allow', 'autoplay; encrypted-media; picture-in-picture; fullscreen');
                              }
                            });
                          }
                        }
                      });
                    });
                  });
                  
                  observer.observe(document.body, {
                    childList: true,
                    subtree: true
                  });
                  
                  console.log('Media autoplay enabled for', videos.length, 'videos and', iframes.length, 'iframes');
                } catch (e) {
                  console.error('Error enabling media autoplay:', e);
                }
              })();
            ''');
          if (mounted) {
            setState(() {
              _loadingProgress = 1.0;
              _isLoading = false;
              _hasLoadedSuccessfully = true;
              _errorMessage = null;
            });
          }
        },
        onWebResourceError: (error) {
          debugPrint('❌ WebView Error: ${error.description}');
          if (!_hasLoadedSuccessfully) {
            if (mounted) {
              setState(() {
                _errorMessage = 'خطأ في تحميل الصفحة: ${error.description}';
                _isLoading = false;
              });
            }
          }
        },
        onNavigationRequest: (request) async {
          final url = request.url;
          debugPrint('🧭 Navigation request: $url');

          // Handle Android Intent URLs specially
          if (url.startsWith('intent://')) {
            try {
              // Parse the intent URL to extract the actual scheme and package
              // Format: intent://...#Intent;scheme=SCHEME;package=PACKAGE;end
              final intentMatch = RegExp(
                r'intent://(.+)#Intent;scheme=([^;]+);package=([^;]+);end',
              ).firstMatch(url);

              if (intentMatch != null) {
                final scheme = intentMatch.group(2);
                final packageName = intentMatch.group(3);
                final path = intentMatch.group(1);

                // Try the app-specific scheme first (e.g., fb-messenger://)
                final appUrl = '$scheme://$path';
                debugPrint('🔄 Trying app URL: $appUrl');

                try {
                  final uri = Uri.parse(appUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                    debugPrint('✅ Opened with app scheme: $appUrl');
                    return NavigationDecision.prevent;
                  }
                } catch (e) {
                  debugPrint('⚠️ App scheme failed, trying package: $e');
                }

                // If app scheme fails, try opening the package directly
                final marketUrl = 'market://details?id=$packageName';
                try {
                  final uri = Uri.parse(marketUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                    debugPrint('✅ Opened Play Store for: $packageName');
                  }
                } catch (e) {
                  debugPrint('❌ Could not open app or Play Store: $e');
                }
              }
            } catch (e) {
              debugPrint('❌ Error parsing intent URL: $e');
            }
            return NavigationDecision.prevent;
          }

          // Try to deep‑link WhatsApp for known web URLs
          if (url.contains('wa.me') ||
              url.contains('api.whatsapp.com') ||
              url.contains('chat.whatsapp.com')) {
            Uri? targetUri;
            try {
              final uri = Uri.parse(url);
              // api.whatsapp.com/send/?phone=...&text=...
              if (uri.host.contains('api.whatsapp.com') &&
                  uri.path.startsWith('/send')) {
                final phone = uri.queryParameters['phone'];
                final text = uri.queryParameters['text'];
                if (phone != null && phone.isNotEmpty) {
                  targetUri = Uri(
                    scheme: 'whatsapp',
                    host: 'send',
                    queryParameters: {
                      'phone': phone,
                      if (text != null && text.isNotEmpty) 'text': text,
                    },
                  );
                }
              }
              // wa.me/<phone>
              else if (uri.host == 'wa.me' && uri.pathSegments.isNotEmpty) {
                final phone = uri.pathSegments.first;
                targetUri = Uri(
                  scheme: 'whatsapp',
                  host: 'send',
                  queryParameters: {'phone': phone},
                );
              }
              // chat.whatsapp.com/<invite-code> – let WhatsApp or browser handle it
              else if (uri.host.contains('chat.whatsapp.com')) {
                targetUri = uri;
              }

              if (targetUri != null && await canLaunchUrl(targetUri)) {
                await launchUrl(
                  targetUri,
                  mode: LaunchMode.externalApplication,
                );
                debugPrint('✅ Deep‑linked to WhatsApp: $targetUri');
                return NavigationDecision.prevent;
              }
            } catch (e) {
              debugPrint('❌ Error deep‑linking WhatsApp URL: $e');
            }
            // Fallback: let WebView load it normally
            return NavigationDecision.navigate;
          }

          // Allow YouTube URLs to load in WebView (for embedded videos)
          if (url.contains('youtube.com') || url.contains('youtu.be')) {
            debugPrint('📺 YouTube URL detected, allowing in WebView: $url');
            return NavigationDecision.navigate;
          }

          // Check if it's an external URL scheme (WhatsApp, tel, mailto, etc.)
          if (url.startsWith('whatsapp://') ||
              url.startsWith('tel:') ||
              url.startsWith('mailto:') ||
              url.startsWith('sms:') ||
              url.startsWith('fb://') ||
              url.startsWith('fb-messenger://') ||
              url.startsWith('instagram://') ||
              url.startsWith('twitter://') ||
              url.startsWith('tg://')) {
            // Try to launch the external app
            try {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                debugPrint('✅ Opened external app: $url');
              } else {
                debugPrint('❌ Cannot launch: $url');
              }
            } catch (e) {
              debugPrint('❌ Error launching URL: $e');
            }
            return NavigationDecision.prevent;
          }

          return NavigationDecision.navigate;
        },
      ),
    );

    _webViewController.loadRequest(
      Uri.parse(_initialUrl),
      headers: {
        'X-App-Source': 'anmka', // <-- الهيدر اللي بيتأكد منه السيرفر
      },
    );

    // Print header when app opens
    debugPrint('🔧 WebView initialized');
    debugPrint('📋 Headers being sent: X-App-Source: anmka');
    debugPrint('🌐 Loading URL: $_initialUrl');
  }

  /// Initialize screen protection on Android/iOS
  Future<void> _initializeScreenProtector() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        debugPrint('🛡️ Enabling Android screen protection...');
        await ScreenProtector.protectDataLeakageOn();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        debugPrint('🛡️ Enabling iOS screenshot prevention...');
        await ScreenProtector.preventScreenshotOn();
      }
    } catch (e) {
      debugPrint('❌ ScreenProtector init error: $e');
    }
  }

  void _refreshWebView() {
    debugPrint('🔄 Refreshing WebView...');
    if (mounted) {
      setState(() {
        _loadingProgress = 0.0;
        _isLoading = true;
        _errorMessage = null;
        _hasLoadedSuccessfully = false;
      });
    }
    _webViewController.reload();
  }

  @override
  void dispose() {
    // Disable screen protection when leaving
    if (defaultTargetPlatform == TargetPlatform.android) {
      ScreenProtector.protectDataLeakageOff();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      ScreenProtector.preventScreenshotOff();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If the WebView can go back in its history, navigate back instead of closing the app
        if (await _webViewController.canGoBack()) {
          _webViewController.goBack();
          return false; // Do not pop the route
        }
        // No more history in WebView -> allow app to close / go back normally
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              _refreshWebView();
            },
            child: Stack(
              children: [
                WebViewWidget(controller: _webViewController),
                if (_isLoading && _loadingProgress < 1.0)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: _loadingProgress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue[700]!,
                      ),
                      minHeight: 3,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
