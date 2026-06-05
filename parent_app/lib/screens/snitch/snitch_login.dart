import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/snitch_theme.dart';
import '../../widgets/snitch_card.dart';
import '_oauth_webview.dart';

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
  bool _passwordVisible = false;
  bool _rememberFor30Days = true;

  Future<void> _openLink(Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      messenger.showSnackBar(SnackBar(content: Text('Could not open ${uri.toString()}')));
    }
  }

  Future<void> _forgotPassword() => _openLink(Uri.parse('$apiBaseUrl/reset-password/'));

  Future<void> _openPrivacyPolicy() => _openLink(Uri.parse('$apiBaseUrl/privacy-policy/'));

  Future<void> _openTerms() => _openLink(Uri.parse('$apiBaseUrl/terms-of-service/'));

  Future<void> _openSupport() async {
    if (!mounted) return;
    Navigator.of(context).pushNamed('/snitch/support');
  }

  Future<void> _contactSchoolAdmin() async {
    if (!mounted) return;
    Navigator.of(context).pushNamed('/snitch/support');
  }

  Future<void> _startGoogleSignIn() async {
    // URL to start Google OAuth on backend. Replace with your backend OAuth start URL.
    final oauthStart = Uri.parse('$apiBaseUrl/api/auth/google/start/');
    if (oauthStart.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OAuth not configured')));
      return;
    }

    final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => OAuthWebview(startUrl: oauthStart.toString())));
    if (result is Map<String, dynamic>) {
      final prefs = await SharedPreferences.getInstance();
      if (result['token'] != null) await prefs.setString('snitch_token', result['token']);
      if (result['parent_id'] != null) await prefs.setInt('snitch_parent_id', int.parse(result['parent_id'].toString()));
      await prefs.setBool('snitch_logged_in', true);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/snitch/dashboard');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final url = Uri.parse('$apiBaseUrl/api/login/');
      final resp = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': _emailCtrl.text.trim(),
            'password': _passwordCtrl.text,
          }));

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        // backend returns user_id and parent_id
        final userId = body['user_id'];
        final parentId = body['parent_id'];
        final prefs = await SharedPreferences.getInstance();
        if (userId != null) await prefs.setInt('snitch_user_id', userId as int);
        if (parentId != null) await prefs.setInt('snitch_parent_id', parentId as int);
        // Also set a logged-in flag for quick checks
        await prefs.setBool('snitch_logged_in', true);
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/snitch/dashboard');
        return;
      }

      // Demo fallback: accept any non-empty credentials and store demo parent id
      if (_emailCtrl.text.trim().isNotEmpty && _passwordCtrl.text.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('snitch_token', 'demo-token');
        await prefs.setBool('snitch_logged_in', true);
        await prefs.setInt('snitch_parent_id', 1);
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
      backgroundColor: const Color(0xFFF8F9FF),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: _GlowCircle(color: const Color(0xFFEAF1FF), size: 240),
          ),
          Positioned(
            bottom: -110,
            left: -90,
            child: _GlowCircle(color: const Color(0xFFF5EEDB), size: 220),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SnitchCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(color: Colors.transparent),
                                    child: Image.asset('assets/branding/app_logo.png', fit: BoxFit.contain),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('EduParent', style: GoogleFonts.manrope(color: SnitchTheme.primary, fontSize: 20, fontWeight: FontWeight.w800)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text('Sign In', style: GoogleFonts.manrope(color: const Color(0xFF1B1F27), fontSize: 24, fontWeight: FontWeight.w800, height: 1.0)),
                              const SizedBox(height: 6),
                              Text('Welcome back, please enter your details.', style: GoogleFonts.inter(color: const Color(0xFF6F7785), fontSize: 15, height: 1.25)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('Email or Username', style: GoogleFonts.inter(color: const Color(0xFF5B6270), fontSize: 12, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. parent@school.edu',
                                    hintStyle: GoogleFonts.inter(color: const Color(0xFF9AA3B2), fontSize: 13),
                                    prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20, color: Color(0xFF7E8796)),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCFD6E2))),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCFD6E2))),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: SnitchTheme.primary, width: 1.0)),
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter email or username' : null,
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Password', style: GoogleFonts.inter(color: const Color(0xFF5B6270), fontSize: 12, fontWeight: FontWeight.w700)),
                                    TextButton(
                                      onPressed: _forgotPassword,
                                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                      child: Text('Forgot Password?', style: GoogleFonts.inter(color: SnitchTheme.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordCtrl,
                                  decoration: InputDecoration(
                                    hintText: '••••••••',
                                    hintStyle: GoogleFonts.inter(color: const Color(0xFF9AA3B2), fontSize: 13),
                                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF7E8796)),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                                      icon: Icon(_passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: const Color(0xFF7E8796)),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCFD6E2))),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCFD6E2))),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: SnitchTheme.primary, width: 1.0)),
                                  ),
                                  obscureText: !_passwordVisible,
                                  validator: (v) => (v == null || v.isEmpty) ? 'Enter password' : null,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Transform.scale(
                                      scale: 0.95,
                                      child: Checkbox(
                                        value: _rememberFor30Days,
                                        onChanged: (v) => setState(() => _rememberFor30Days = v ?? false),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                        side: const BorderSide(color: Color(0xFFB7C0CF)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                        activeColor: SnitchTheme.primary,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(() => _rememberFor30Days = !_rememberFor30Days),
                                      child: Text('Remember for 30 days', style: GoogleFonts.inter(color: const Color(0xFF616A77), fontSize: 11, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      elevation: 3,
                                      shadowColor: const Color(0x33000000),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      backgroundColor: SnitchTheme.primary,
                                      foregroundColor: Colors.white,
                                      textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                                    ),
                                    onPressed: _loading ? null : _submit,
                                    child: _loading
                                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text('Sign In'),
                                              const SizedBox(width: 10),
                                              Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white.withValues(alpha: 0.95)),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: const [
                                    Expanded(child: Divider(color: Color(0xFFCFD6E2), height: 1)),
                                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('OR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF9AA3B2)))),
                                    Expanded(child: Divider(color: Color(0xFFCFD6E2), height: 1)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      side: const BorderSide(color: Color(0xFFCFD6E2)),
                                      backgroundColor: const Color(0xFFFFFFFF),
                                    ),
                                    onPressed: _startGoogleSignIn,
                                    icon: const _GoogleIconWrapper(),
                                    label: Text('Sign In with Google', style: GoogleFonts.inter(color: const Color(0xFF1F1F1F), fontWeight: FontWeight.w700, fontSize: 14)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text("Don't have an account? ", style: GoogleFonts.inter(color: const Color(0xFF5F6775), fontSize: 12, height: 1.35)),
                                      TextButton(
                                        onPressed: _contactSchoolAdmin,
                                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap, foregroundColor: SnitchTheme.primary),
                                        child: Text('Contact School\nAdmin', textAlign: TextAlign.center, style: GoogleFonts.inter(color: SnitchTheme.primary, fontSize: 12, fontWeight: FontWeight.w700, height: 1.05)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(onPressed: _openPrivacyPolicy, style: TextButton.styleFrom(foregroundColor: const Color(0xFF8C96A5), padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap), child: Text('Privacy Policy', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500))),
                            const SizedBox(width: 16),
                            TextButton(onPressed: _openTerms, style: TextButton.styleFrom(foregroundColor: const Color(0xFF8C96A5), padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap), child: Text('Terms of Service', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500))),
                            const SizedBox(width: 16),
                            TextButton(onPressed: _openSupport, style: TextButton.styleFrom(foregroundColor: const Color(0xFF8C96A5), padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap), child: Text('Support', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleGIcon extends StatelessWidget {
  const _GoogleGIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _GoogleGPainter(),
      ),
    );
  }
}

class _GoogleIconWrapper extends StatefulWidget {
  const _GoogleIconWrapper();

  @override
  State<_GoogleIconWrapper> createState() => _GoogleIconWrapperState();
}

class _GoogleIconWrapperState extends State<_GoogleIconWrapper> {
  bool _hasSvg = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _checkAsset();
  }

  Future<void> _checkAsset() async {
    try {
      // Check for SVG first
      await rootBundle.loadString('assets/branding/google_g.svg');
      if (mounted) setState(() => _hasSvg = true);
    } catch (_) {
      if (mounted) setState(() => _hasSvg = false);
    } finally {
      if (mounted) setState(() => _checked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) return const SizedBox(width: 20, height: 20);
    if (_hasSvg) return SvgPicture.asset('assets/branding/google_g.svg', width: 20, height: 20);
    // fallback to existing painter
    return const _GoogleGIcon();
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw a filled multi-segment 'G' approximation using thick arcs.
    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.36
      ..strokeCap = StrokeCap.butt;
    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.36
      ..strokeCap = StrokeCap.butt;
    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.36
      ..strokeCap = StrokeCap.butt;
    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.36
      ..strokeCap = StrokeCap.butt;

    final r = Rect.fromLTWH(size.width * 0.06, size.height * 0.06, size.width * 0.88, size.height * 0.88);
    // Blue segment (top-right)
    canvas.drawArc(r, -1.05, 1.10, false, paintBlue);
    // Green segment (bottom-right)
    canvas.drawArc(r, 0.05, 0.80, false, paintGreen);
    // Yellow segment (bottom-left)
    canvas.drawArc(r, 0.95, 0.55, false, paintYellow);
    // Red segment (top-left)
    canvas.drawArc(r, 1.65, 0.95, false, paintRed);

    // Draw the inner horizontal stroke to form the G notch
    final notchPaint = Paint()..color = const Color(0xFF1F1F1F)..style = PaintingStyle.fill;
    final notchWidth = size.width * 0.38;
    final notchHeight = size.height * 0.12;
    final notchRect = Rect.fromCenter(center: Offset(size.width * 0.62, size.height * 0.5), width: notchWidth, height: notchHeight);
    canvas.drawRRect(RRect.fromRectAndRadius(notchRect, Radius.circular(notchHeight / 2)), notchPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }
}
