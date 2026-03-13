import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// ─── Design Tokens — Light Theme ─────────────────────────────────────────────
const _bg = Color(0xFFF0F3F8);
const _surface = Color(0xFFFFFFFF);
const _surfaceEl = Color(0xFFF4F6FB);
const _border = Color(0xFFE2E8F0);

const _accent = Color(0xFF4F46E5);
const _accentSoft = Color(0xFFEEF2FF);
const _accentLt = Color(0xFF818CF8);

const _red = Color(0xFFDC2626);
const _redSoft = Color(0xFFFEE2E2);
const _green = Color(0xFF059669);

const _textPri = Color(0xFF0F172A);
const _textSec = Color(0xFF475569);
const _textMuted = Color(0xFF94A3B8);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  bool _showPassword = false;
  String? _error;

  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!userDoc.exists) {
        setState(() {
          _error = 'Account not set up. Please contact admin.';
          _loading = false;
        });
        await FirebaseAuth.instance.signOut();
      }
      // Success — AuthGate handles navigation
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        switch (e.code) {
          case 'user-not-found':
            _error = 'No account found with this email.';
            break;
          case 'wrong-password':
            _error = 'Incorrect password.';
            break;
          case 'invalid-email':
            _error = 'Invalid email address.';
            break;
          case 'user-disabled':
            _error = 'This account has been disabled.';
            break;
          case 'too-many-requests':
            _error = 'Too many attempts. Please try again later.';
            break;
          default:
            _error = 'Login failed: ${e.message}';
        }
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  void quickLogin(String email, String password) {
    _emailCtrl.text = email;
    _passwordCtrl.text = password;
    _login();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                const SizedBox(height: 52),
                _buildLogo(),
                const SizedBox(height: 28),
                _buildHeading(),
                const SizedBox(height: 36),
                _buildForm(),
                const SizedBox(height: 28),
                // _buildDivider(),
                // const SizedBox(height: 20),
                // _buildQuickLogins(),
                // const SizedBox(height: 40),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ── Logo ──────────────────────────────────────────────────────────────────
  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
              color: _accent.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8)),
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Image.network(
          'https://firebasestorage.googleapis.com/v0/b/pro-connect-da8ac.firebasestorage.app/o/400px.jpg?alt=media&token=05adfb1a-fbc5-4aca-955e-f3ff218e67c9',
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : const Center(
                  child: CircularProgressIndicator(
                      color: _accent, strokeWidth: 2)),
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.business_rounded, size: 42, color: _accent),
        ),
      ),
    );
  }

  // ── Heading ───────────────────────────────────────────────────────────────
  Widget _buildHeading() {
    return Column(children: [
      const Text('Pro Connect',
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: _textPri,
              letterSpacing: -0.8)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: _accentSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _accent.withOpacity(0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 6,
              height: 6,
              decoration:
                  const BoxDecoration(color: _accent, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          const Text('Sign in to continue',
              style: TextStyle(
                  color: _accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3)),
        ]),
      ),
    ]);
  }

  // ── Form ──────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Error banner
          if (_error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _redSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _red.withOpacity(0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded, color: _red, size: 18),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(_error!,
                        style: const TextStyle(
                            color: _red,
                            fontSize: 13,
                            fontWeight: FontWeight.w500))),
              ]),
            ),
            const SizedBox(height: 18),
          ],

          // Email
          _fieldLabel('EMAIL'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !_loading,
            style: const TextStyle(fontSize: 14, color: _textPri),
            decoration: _inputDec('Enter your email', Icons.email_outlined),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter your email';
              if (!v.contains('@')) return 'Please enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password
          _fieldLabel('PASSWORD'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: !_showPassword,
            textInputAction: TextInputAction.done,
            enabled: !_loading,
            onFieldSubmitted: (_) => _login(),
            style: const TextStyle(fontSize: 14, color: _textPri),
            decoration:
                _inputDec('Enter your password', Icons.lock_outlined).copyWith(
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _showPassword = !_showPassword),
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Icon(
                    _showPassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: _textMuted,
                    size: 18,
                  ),
                ),
              ),
              suffixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter your password';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Sign In button
          GestureDetector(
            onTap: _loading ? null : _login,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 54,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _loading ? _surfaceEl : _accent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _loading
                    ? []
                    : [
                        BoxShadow(
                            color: _accent.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6)),
                      ],
              ),
              child: Center(
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: _accent, strokeWidth: 2.5))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Icon(Icons.login_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 10),
                              Text('Sign In',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2)),
                            ])),
            ),
          ),
        ]),
      ),
    );
  }

  InputDecoration _inputDec(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(icon, color: _textMuted, size: 18),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: _surfaceEl,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: _border, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: _accent, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: _red)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: _red, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      );

  Widget _fieldLabel(String t) => Text(t,
      style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _textMuted,
          letterSpacing: 1.4));

  // // ── Divider ───────────────────────────────────────────────────────────────
  // Widget _buildDivider() {
  //   return Row(children: [
  //     Expanded(child: Container(height: 1, color: _border)),
  //     Padding(
  //       padding: const EdgeInsets.symmetric(horizontal: 12),
  //       child: Text('Quick Login  ·  Testing',
  //           style: const TextStyle(
  //               fontSize: 11, color: _textMuted, fontWeight: FontWeight.w600)),
  //     ),
  //     Expanded(child: Container(height: 1, color: _border)),
  //   ]);
  // }

  // // ── Quick Login Buttons ───────────────────────────────────────────────────
  // Widget _buildQuickLogins() {
  //   final accounts = [
  //     {
  //       'label': 'Admin',
  //       'icon': Icons.admin_panel_settings_rounded,
  //       'email': 'admin@prodix.com',
  //       'pass': '123456'
  //     },
  //     {
  //       'label': 'Manager',
  //       'icon': Icons.manage_accounts_rounded,
  //       'email': 'manager@prodix.com',
  //       'pass': '123456'
  //     },
  //     {
  //       'label': 'Sales Staff',
  //       'icon': Icons.trending_up_rounded,
  //       'email': 'sales@prodix.com',
  //       'pass': '123456'
  //     },
  //     {
  //       'label': 'Design Staff',
  //       'icon': Icons.palette_rounded,
  //       'email': 'design@prodix.com',
  //       'pass': '123456'
  //     },
  //   ];

  //   return Wrap(
  //     spacing: 8,
  //     runSpacing: 8,
  //     alignment: WrapAlignment.center,
  //     children: accounts.map((a) {
  //       return GestureDetector(
  //         onTap: _loading
  //             ? null
  //             : () => _quickLogin(a['email'] as String, a['pass'] as String),
  //         child: Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
  //           decoration: BoxDecoration(
  //             color: _surface,
  //             borderRadius: BorderRadius.circular(12),
  //             border: Border.all(color: _border, width: 1.5),
  //             boxShadow: [
  //               BoxShadow(
  //                   color: Colors.black.withOpacity(0.03),
  //                   blurRadius: 8,
  //                   offset: const Offset(0, 2)),
  //             ],
  //           ),
  //           child: Row(mainAxisSize: MainAxisSize.min, children: [
  //             Container(
  //               width: 28,
  //               height: 28,
  //               decoration: BoxDecoration(
  //                   color: _accentSoft, borderRadius: BorderRadius.circular(8)),
  //               child: Icon(a['icon'] as IconData, size: 14, color: _accent),
  //             ),
  //             const SizedBox(width: 8),
  //             Text(a['label'] as String,
  //                 style: const TextStyle(
  //                     fontSize: 12,
  //                     fontWeight: FontWeight.w700,
  //                     color: _textPri)),
  //           ]),
  //         ),
  //       );
  //     }).toList(),
  //   );
  // }
}
