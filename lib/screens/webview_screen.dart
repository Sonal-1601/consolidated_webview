import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
    _initializeWebView();
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

      _controller = WebViewController()
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
            onPageFinished: (String url) {
              setState(() {
                _isLoading = false;
                _currentUrl = url;
              });
            },
            onWebResourceError: (WebResourceError error) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Failed to load page: ${error.description}\nError code: ${error.errorCode}\nError type: ${error.errorType}';
              });
            },
            onHttpError: (HttpResponseError error) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'HTTP Error: ${error.response?.statusCode}';
              });
            },
          ),
        )
        ..loadRequest(Uri.parse(kWebUrl));

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

    return WebViewWidget(controller: _controller);
  }
}
