import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/preferences_service.dart';
import '../services/network_service.dart';
import 'url_input_screen.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
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
      
      final storedUrl = await PreferencesService.getUrl();
      
      if (storedUrl == null) {
        setState(() {
          _errorMessage = 'No URL stored. Please enter a URL first.';
          _isLoading = false;
        });
        return;
      }

      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
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
                _errorMessage = 'Failed to load page: ${error.description}';
              });
            },
          ),
        )
        ..loadRequest(Uri.parse(storedUrl));

      setState(() {
        _currentUrl = storedUrl;
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

  Future<void> _goBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    }
  }

  Future<void> _goForward() async {
    if (await _controller.canGoForward()) {
      await _controller.goForward();
    }
  }

  Future<void> _changeUrl() async {
    // Clear the stored URL so user can enter a new one
    await PreferencesService.clearUrl();
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const UrlInputScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Web View Screen'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPage,
            tooltip: 'Refresh',
          ),
          // IconButton(
          //   icon: const Icon(Icons.edit),
          //   onPressed: _changeUrl,
          //   tooltip: 'Change URL',
          // ),
        ],
      ),
      body: Column(
        children: [
          // Navigation buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _goBack,
                  tooltip: 'Go Back',
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _goForward,
                  tooltip: 'Go Forward',
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      _currentUrl ?? 'Loading...',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Web view content
          Expanded(
            child: _buildWebViewContent(),
          ),
        ],
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
              onPressed: _changeUrl,
              child: const Text('Enter New URL'),
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
