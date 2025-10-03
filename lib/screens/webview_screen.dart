import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../services/network_service.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  // Hardcoded URL
  static const String kWebUrl = 'https://platinum.arzen.io/web-interface/';
  
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _currentUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _configureAndroidWebView();
    _initializeWebView();
  }

  void _configureAndroidWebView() {
    // Configure Android WebView with proper settings for video playback
    if (Platform.isAndroid) {
      AndroidWebViewController.enableDebugging(true);
    }
  }

  Future<void> _initializeWebView() async {
    try {
      // Check network connectivity first
      final hasInternet = await NetworkService.hasInternetConnection();
      if (!hasInternet) {
        setState(() {
          _isLoading = false;
        });
        NetworkService.showNetworkErrorDialog(context);
        return;
      }

      // Create WebViewController with platform-specific parameters
      late final PlatformWebViewControllerCreationParams params;
      if (Platform.isAndroid) {
        params = AndroidWebViewControllerCreationParams();
      } else {
        params = const PlatformWebViewControllerCreationParams();
      }

      _controller = WebViewController.fromPlatformCreationParams(params)
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..enableZoom(false)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            },
            onPageFinished: (String url) async {
              setState(() {
                _isLoading = false;
                _currentUrl = url;
              });
              
              // Inject JavaScript to optimize video playback on Android TV
              if (Platform.isAndroid) {
                await _controller.runJavaScript('''
                  // Enable hardware acceleration for video elements
                  document.addEventListener('DOMContentLoaded', function() {
                    var videos = document.getElementsByTagName('video');
                    for (var i = 0; i < videos.length; i++) {
                      videos[i].setAttribute('playsinline', 'true');
                      videos[i].setAttribute('webkit-playsinline', 'true');
                      // Optimize video performance
                      videos[i].style.transform = 'translateZ(0)';
                      videos[i].style.backfaceVisibility = 'hidden';
                    }
                  });
                  
                  // Also handle dynamically added videos
                  var observer = new MutationObserver(function(mutations) {
                    mutations.forEach(function(mutation) {
                      mutation.addedNodes.forEach(function(node) {
                        if (node.tagName === 'VIDEO') {
                          node.setAttribute('playsinline', 'true');
                          node.setAttribute('webkit-playsinline', 'true');
                          node.style.transform = 'translateZ(0)';
                          node.style.backfaceVisibility = 'hidden';
                        }
                      });
                    });
                  });
                  observer.observe(document.body, { childList: true, subtree: true });
                ''');
              }
            },
            onWebResourceError: (WebResourceError error) {
              // Only show error if it's the main frame (not sub-resources like images, videos, etc.)
              if (error.errorType == WebResourceErrorType.hostLookup ||
                  error.errorType == WebResourceErrorType.timeout ||
                  error.errorType == WebResourceErrorType.connect) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = 'Failed to load page: ${error.description}\nError code: ${error.errorCode}\nError type: ${error.errorType}';
                });
              } else {
                // Ignore sub-resource errors (common with video elements)
                print('Non-critical resource error: ${error.description}');
              }
            },
            onHttpError: (HttpResponseError error) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'HTTP Error: ${error.response?.statusCode}';
              });
            },
          ),
        );

      // Configure Android-specific settings for video playback
      if (_controller.platform is AndroidWebViewController) {
        AndroidWebViewController androidController = _controller.platform as AndroidWebViewController;
        
        // Disable media playback gesture requirement (allows autoplay)
        await androidController.setMediaPlaybackRequiresUserGesture(false);
        
        // Set additional Android WebView settings
        await androidController.setGeolocationPermissionsPromptCallbacks(
          onShowPrompt: (request) async {
            return GeolocationPermissionsResponse(
              allow: false,
              retain: false,
            );
          },
        );
        
        // Give the controller a moment to fully initialize
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Load the URL after all settings are configured
      await _controller.loadRequest(Uri.parse(kWebUrl));

      setState(() {
        _currentUrl = kWebUrl;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing web view: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshPage() async {
    // Check network connectivity before refreshing
    final hasInternet = await NetworkService.hasInternetConnection();
    if (!hasInternet) {
      NetworkService.showNetworkErrorDialog(context);
      return;
    }
    
    if (_currentUrl != null) {
      await _controller.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Web View Screen'),
      //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.refresh),
      //       onPressed: _refreshPage,
      //       tooltip: 'Refresh',
      //     ),
      //     // IconButton(
      //     //   icon: const Icon(Icons.edit),
      //     //   onPressed: _changeUrl,
      //     //   tooltip: 'Change URL',
      //     // ),
      //   ],
      // ),
      body: SafeArea(
        child: Column(
          children: [
            // Navigation buttons
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            //   decoration: BoxDecoration(
            //     color: Theme.of(context).colorScheme.surface,
            //     border: Border(
            //       bottom: BorderSide(
            //         color: Theme.of(context).dividerColor,
            //         width: 1,
            //       ),
            //     ),
            //   ),
            //   child: Row(
            //     children: [
            //       IconButton(
            //         icon: const Icon(Icons.arrow_back),
            //         onPressed: _goBack,
            //         tooltip: 'Go Back',
            //       ),
            //       IconButton(
            //         icon: const Icon(Icons.arrow_forward),
            //         onPressed: _goForward,
            //         tooltip: 'Go Forward',
            //       ),
            //       Expanded(
            //         child: Padding(
            //           padding: const EdgeInsets.symmetric(horizontal: 8),
            //           child: Text(
            //             _currentUrl ?? 'Loading...',
            //             style: const TextStyle(fontSize: 12),
            //             overflow: TextOverflow.ellipsis,
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            // Web view content
            Expanded(
              child: _buildWebViewContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebViewContent() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshPage,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      );
    }

    // Use platform-specific widget for Android with Virtual Display mode for better video performance
    if (Platform.isAndroid) {
      return WebViewWidget.fromPlatformCreationParams(
        params: AndroidWebViewWidgetCreationParams(
          controller: _controller.platform as AndroidWebViewController,
          // Use Virtual Display (texture layer) for smooth video playback on Android TV
          // Hybrid composition can cause lag with video content
          displayWithHybridComposition: false,
        ),
      );
    }

    return WebViewWidget(controller: _controller);
  }
}
