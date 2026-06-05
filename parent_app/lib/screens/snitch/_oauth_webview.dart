import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OAuthWebview extends StatefulWidget {
  final String startUrl;
  const OAuthWebview({super.key, required this.startUrl});

  @override
  State<OAuthWebview> createState() => _OAuthWebviewState();
}

class _OAuthWebviewState extends State<OAuthWebview> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null &&
                (uri.queryParameters.containsKey('snitch_token') ||
                    uri.queryParameters.containsKey('token') ||
                    uri.queryParameters.containsKey('parent_id'))) {
              final result = <String, dynamic>{};
              if (uri.queryParameters.containsKey('token')) result['token'] = uri.queryParameters['token'];
              if (uri.queryParameters.containsKey('snitch_token')) result['token'] = uri.queryParameters['snitch_token'];
              if (uri.queryParameters.containsKey('parent_id')) result['parent_id'] = uri.queryParameters['parent_id'];
              Navigator.of(context).pop(result);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.startUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in with Google')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
        ],
      ),
    );
  }
}
