import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SnitchLogin extends StatefulWidget {
  const SnitchLogin({super.key});

  @override
  State<SnitchLogin> createState() => _SnitchLoginState();
}

String get apiBaseUrl {
  if (kIsWeb) return "http://127.0.0.1:8000";
  if (defaultTargetPlatform == TargetPlatform.android) return "http://10.0.2.2:8000";
  return "http://127.0.0.1:8000";
}


class _SnitchLoginState extends State<SnitchLogin> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _openPrototypeHtml() async {
    final html = await rootBundle.loadString('lib/snitch/login.html');
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _HtmlPreviewScreen(html: html)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final url = Uri.parse('$apiBaseUrl/api/auth/login/');
      final resp = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': _emailCtrl.text.trim(),
            'password': _passwordCtrl.text,
          }));

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final token = body['token'] ?? body['access'] ?? body['data']?['token'];
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('snitch_token', token.toString());
        }
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/snitch/dashboard');
        return;
      }

      // Demo fallback: accept any non-empty credentials
      if (_emailCtrl.text.trim().isNotEmpty && _passwordCtrl.text.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('snitch_token', 'demo-token');
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/snitch/dashboard');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login failed')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In (Snitch)')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email or Username'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter email or username' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordCtrl,
                        decoration: const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter password' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              child: _loading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Sign In'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextButton(onPressed: _openPrototypeHtml, child: const Text('View HTML Prototype')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HtmlPreviewScreen extends StatelessWidget {
  final String html;
  const _HtmlPreviewScreen({required this.html});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prototype HTML Preview')),
      body: WebViewWidget(
        controller: WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadHtmlString(html),
      ),
    );
  }
}

class _WebHtmlWidget extends StatefulWidget {
  final String html;
  const _WebHtmlWidget({required this.html});

  @override
  State<_WebHtmlWidget> createState() => _WebHtmlWidgetState();
}

class _WebHtmlWidgetState extends State<_WebHtmlWidget> {
  @override
  Widget build(BuildContext context) {
    // Use a simple Scrollable HTML view using SelectableText as a fallback for platforms without WebView.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(widget.html),
    );
  }
}
