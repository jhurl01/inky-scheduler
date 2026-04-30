import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart' hide colorToHex;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme.dart';

class YouScreen extends ConsumerStatefulWidget {
  const YouScreen({super.key});

  @override
  ConsumerState<YouScreen> createState() => _YouScreenState();
}

class _YouScreenState extends ConsumerState<YouScreen> {
  final _nameCtrl = TextEditingController();
  final _pairCodeCtrl = TextEditingController();
  bool _editingName = false;
  bool _savingName = false;
  bool _pairing = false;
  String? _pairError;
  final _shareButtonKey = GlobalKey();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pairCodeCtrl.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _shareCode(String code) {
    final box =
        _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : Rect.fromLTWH(0, 400, 200, 50);
    Share.share('Join me on Inky! Use code: $code',
        sharePositionOrigin: origin);
  }

  Future<void> _pairWithCode() async {
    final code = _pairCodeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _pairError = 'Enter a 6-character code.');
      return;
    }
    setState(() { _pairing = true; _pairError = null; });
    try {
      final me = ref.read(currentUserProvider).valueOrNull!;
      final db = ref.read(firestoreProvider);
      final codeDoc = await db.collection('inviteCodes').doc(code).get();
      if (!codeDoc.exists) {
        setState(() { _pairError = 'Code not found.'; _pairing = false; });
        return;
      }
      final data = codeDoc.data()!;
      if (data['used'] == true) {
        setState(() { _pairError = 'Code already used.'; _pairing = false; });
        return;
      }
      final partnerUid = data['createdBy'] as String;
      if (partnerUid == me.uid) {
        setState(() { _pairError = 'You cannot pair with yourself.'; _pairing = false; });
        return;
      }
      final sorted = [me.uid, partnerUid]..sort();
      final coupleId = '${sorted[0]}_${sorted[1]}';
      final batch = db.batch();
      batch.update(db.collection('users').doc(me.uid),
          {'partnerId': partnerUid, 'coupleId': coupleId});
      batch.update(db.collection('users').doc(partnerUid),
          {'partnerId': me.uid, 'coupleId': coupleId});
      batch.update(db.collection('inviteCodes').doc(code), {'used': true});
      await batch.commit();
      _pairCodeCtrl.clear();
      setState(() => _pairing = false);
    } catch (e) {
      setState(() { _pairError = e.toString(); _pairing = false; });
    }
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _savingName = true);
    await ref.read(firestoreProvider).collection('users').doc(
        ref.read(currentUserProvider).valueOrNull!.uid).update({
      'displayName': name,
    });
    setState(() {
      _editingName = false;
      _savingName = false;
    });
  }

  Future<void> _pickColor(String currentHex) async {
    Color picked = hexToColor(currentHex);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardSurface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('your color',
            style: TextStyle(fontSize: 17, color: kNearBlack)),
        content: ColorPicker(
          pickerColor: picked,
          onColorChanged: (c) => picked = c,
          enableAlpha: false,
          labelTypes: const [],
          pickerAreaHeightPercent: 0.5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('cancel',
                style: TextStyle(color: kMutedGray)),
          ),
          TextButton(
            onPressed: () async {
              final hex = colorToHex(picked);
              await ref.read(firestoreProvider).collection('users').doc(
                  ref.read(currentUserProvider).valueOrNull!.uid).update({
                'color': hex,
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('save',
                style: TextStyle(color: kNearBlack)),
          ),
        ],
      ),
    );
  }

  Future<void> _unpair() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardSurface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('unpair?',
            style: TextStyle(fontSize: 17, color: kNearBlack)),
        content: const Text(
          'This will disconnect you from your partner. You can re-pair later with a new code.',
          style: TextStyle(color: kMutedGray, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('cancel',
                style: TextStyle(color: kMutedGray)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('unpair',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final me = ref.read(currentUserProvider).valueOrNull;
    if (me == null) return;
    final db = ref.read(firestoreProvider);
    final batch = db.batch();

    batch.update(db.collection('users').doc(me.uid), {
      'partnerId': null,
      'coupleId': null,
    });
    if (me.partnerId != null) {
      batch.update(db.collection('users').doc(me.partnerId), {
        'partnerId': null,
        'coupleId': null,
      });
    }
    // Mark original invite code as reusable
    if (me.inviteCode.isNotEmpty) {
      batch.update(db.collection('inviteCodes').doc(me.inviteCode), {
        'used': false,
      });
    }
    await batch.commit();
    // Router will redirect to /onboarding once coupleId is cleared
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) context.go('/onboarding');
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider).valueOrNull;
    final partner = ref.watch(partnerProvider).valueOrNull;

    if (me == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            const Text(
              'you',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: kNearBlack),
            ),
            const SizedBox(height: 24),

            // ── Display name ──────────────────────────────────────────
            _SectionLabel('display name'),
            _SettingsCard(
              child: _editingName
                  ? Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameCtrl,
                            autofocus: true,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration.collapsed(
                                hintText: 'your name'),
                            style: const TextStyle(
                                fontSize: 15, color: kNearBlack),
                          ),
                        ),
                        if (_savingName)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: kMutedGray),
                          )
                        else
                          GestureDetector(
                            onTap: _saveName,
                            child: const Text('save',
                                style: TextStyle(
                                    color: kNearBlack,
                                    fontWeight: FontWeight.w500)),
                          ),
                      ],
                    )
                  : GestureDetector(
                      onTap: () {
                        _nameCtrl.text = me.displayName;
                        setState(() => _editingName = true);
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              me.displayName.isEmpty
                                  ? 'tap to set name'
                                  : me.displayName,
                              style: TextStyle(
                                fontSize: 15,
                                color: me.displayName.isEmpty
                                    ? kMutedGray
                                    : kNearBlack,
                              ),
                            ),
                          ),
                          const Icon(Icons.edit_outlined,
                              size: 16, color: kMutedGray),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            // ── Accent color ──────────────────────────────────────────
            _SectionLabel('your color'),
            _SettingsCard(
              child: GestureDetector(
                onTap: () => _pickColor(me.color),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: hexToColor(me.color),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(6),
                          bottomLeft: Radius.circular(6),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      me.color.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 15, color: kNearBlack),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        size: 18, color: kMutedGray),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Changing your color applies to new events only.',
                style: TextStyle(fontSize: 11, color: kMutedGray),
              ),
            ),
            const SizedBox(height: 24),

            // ── Partner (paired) ──────────────────────────────────────
            if (partner != null) ...[
              _SectionLabel('partner'),
              _SettingsCard(
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: hexToColor(partner.color),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(6),
                          bottomLeft: Radius.circular(6),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      partner.displayName.isEmpty
                          ? 'partner'
                          : partner.displayName,
                      style: const TextStyle(
                          fontSize: 15, color: kNearBlack),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Pair with partner (unpaired) ──────────────────────────
            if (me.coupleId == null) ...[
              _SectionLabel('pair with a partner'),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('your invite code',
                        style: TextStyle(fontSize: 11, color: kMutedGray)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          me.inviteCode,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 5,
                            color: kNearBlack,
                          ),
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          key: _shareButtonKey,
                          onPressed: () => _shareCode(me.inviteCode),
                          icon: const Icon(Icons.ios_share, size: 14),
                          label: const Text('share'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kNearBlack,
                            side: const BorderSide(color: kBorder),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _pairCodeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                      decoration: const InputDecoration(
                          hintText: "enter partner's code",
                          counterText: ''),
                    ),
                    if (_pairError != null) ...[
                      const SizedBox(height: 6),
                      Text(_pairError!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 12)),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _pairing ? null : _pairWithCode,
                        style: FilledButton.styleFrom(
                          backgroundColor: kNearBlack,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _pairing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('connect',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Account actions ───────────────────────────────────────
            _SectionLabel('account'),
            _SettingsCard(
              child: Column(
                children: [
                  if (me.coupleId != null) ...[
                    _ActionRow(
                      label: 'unpair',
                      color: Colors.redAccent.shade100,
                      onTap: _unpair,
                    ),
                    const Divider(height: 1),
                  ],
                  _ActionRow(
                    label: 'sign out',
                    color: kMutedGray,
                    onTap: _signOut,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 12,
            color: kMutedGray,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: child,
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionRow(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(label,
            style: TextStyle(fontSize: 15, color: color)),
      ),
    );
  }
}
