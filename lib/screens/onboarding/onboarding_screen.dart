import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/user_provider.dart';
import '../../theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  // Sign-up form
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // Pairing
  final _codeCtrl = TextEditingController();

  // Used to anchor the iOS share sheet to the share button
  final _shareButtonKey = GlobalKey();

  bool _loading = false;
  String? _error;
  bool _isSignIn = false;    // toggle between sign-up and sign-in
  bool _paired = false;      // true after account creation — show pairing UI
  String? _myCode;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  FirebaseFirestore get _db => ref.read(firestoreProvider);

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _createAccount() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirmPass = _confirmPassCtrl.text;
    if (name.isEmpty || email.isEmpty || pass.isEmpty || confirmPass.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (pass != confirmPass) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);
      final uid = cred.user!.uid;
      final code = _generateCode();

      await _db.collection('users').doc(uid).set({
        'displayName': name,
        'color': '#B8A9D9',
        'partnerId': null,
        'coupleId': null,
        'inviteCode': code,
      });

      await _db.collection('inviteCodes').doc(code).set({
        'createdBy': uid,
        'used': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _paired = true;
        _myCode = code;
        _loading = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _signIn() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pass);
      // Router redirect handles navigation once auth state updates
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _enterPartnerCode() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Enter a 6-character code.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final myUid = FirebaseAuth.instance.currentUser!.uid;

      final codeDoc = await _db.collection('inviteCodes').doc(code).get();
      if (!codeDoc.exists) {
        setState(() {
          _error = 'Code not found.';
          _loading = false;
        });
        return;
      }

      final codeData = codeDoc.data()!;
      if (codeData['used'] == true) {
        setState(() {
          _error = 'This code has already been used.';
          _loading = false;
        });
        return;
      }

      final partnerUid = codeData['createdBy'] as String;
      if (partnerUid == myUid) {
        setState(() {
          _error = 'You cannot pair with yourself.';
          _loading = false;
        });
        return;
      }

      // coupleId = alphabetically sorted uid concatenation
      final sortedUids = [myUid, partnerUid]..sort();
      final coupleId = '${sortedUids[0]}_${sortedUids[1]}';

      final batch = _db.batch();
      batch.update(_db.collection('users').doc(myUid), {
        'partnerId': partnerUid,
        'coupleId': coupleId,
      });
      batch.update(_db.collection('users').doc(partnerUid), {
        'partnerId': myUid,
        'coupleId': coupleId,
      });
      batch.update(_db.collection('inviteCodes').doc(code), {'used': true});
      await batch.commit();

      if (mounted) context.go('/today');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: _paired
              ? _buildPairingView()
              : _isSignIn
                  ? _buildSignInView()
                  : _buildSignUpView(),
        ),
      ),
    );
  }

  Widget _buildSignUpView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 52),
        const Text(
          'inky',
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w300,
            letterSpacing: 5,
            color: kNearBlack,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'a shared space for two',
          style: TextStyle(color: kMutedGray, fontSize: 15),
        ),
        const SizedBox(height: 48),
        TextField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'your name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passCtrl,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'password'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmPassCtrl,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'confirm password'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
        ],
        const SizedBox(height: 28),
        _PrimaryButton(
          label: 'Create Account',
          loading: _loading,
          onTap: _createAccount,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => setState(() {
              _isSignIn = true;
              _error = null;
            }),
            child: const Text(
              'Already have an account? Sign in →',
              style: TextStyle(color: kMutedGray, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSignInView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 52),
        const Text(
          'inky',
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w300,
            letterSpacing: 5,
            color: kNearBlack,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'welcome back',
          style: TextStyle(color: kMutedGray, fontSize: 15),
        ),
        const SizedBox(height: 48),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passCtrl,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'password'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
        ],
        const SizedBox(height: 28),
        _PrimaryButton(
          label: 'Sign In',
          loading: _loading,
          onTap: _signIn,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => setState(() {
              _isSignIn = false;
              _error = null;
            }),
            child: const Text(
              'New here? Create an account →',
              style: TextStyle(color: kMutedGray, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPairingView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 52),
        const Text(
          'pair up',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w300,
            color: kNearBlack,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "share your code or enter your partner's",
          style: TextStyle(color: kMutedGray, fontSize: 15),
        ),
        const SizedBox(height: 40),

        // ── My code card ────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: kCardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            children: [
              const Text(
                'your invite code',
                style: TextStyle(color: kMutedGray, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Text(
                _myCode ?? '',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 7,
                  color: kNearBlack,
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                key: _shareButtonKey,
                onPressed: () {
                  // iOS requires sharePositionOrigin to anchor the share sheet
                  final box = _shareButtonKey.currentContext
                      ?.findRenderObject() as RenderBox?;
                  final origin = box != null
                      ? box.localToGlobal(Offset.zero) & box.size
                      : Rect.fromLTWH(0, 400, 200, 50);
                  Share.share(
                    'Join me on Inky! Use code: $_myCode',
                    sharePositionOrigin: origin,
                  );
                },
                icon: const Icon(Icons.ios_share, size: 16),
                label: const Text('Share My Code'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kNearBlack,
                  side: const BorderSide(color: kBorder),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),
        const Row(children: [
          Expanded(child: Divider(color: kBorder)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('or', style: TextStyle(color: kMutedGray, fontSize: 13)),
          ),
          Expanded(child: Divider(color: kBorder)),
        ]),
        const SizedBox(height: 28),

        // ── Enter partner code ───────────────────────────────────────────
        TextField(
          controller: _codeCtrl,
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          decoration: const InputDecoration(hintText: "partner's code"),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
        ],
        const SizedBox(height: 16),
        _PrimaryButton(
          label: 'Connect',
          loading: _loading,
          onTap: _enterPartnerCode,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => context.go('/today'),
            child: const Text(
              'skip for now →',
              style: TextStyle(color: kMutedGray, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: kNearBlack,
          disabledBackgroundColor: kMutedGray,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Text(
                label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
              ),
      ),
    );
  }
}
