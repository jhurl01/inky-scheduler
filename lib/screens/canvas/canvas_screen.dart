import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/canvas_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme.dart';

class CanvasScreen extends ConsumerStatefulWidget {
  const CanvasScreen({super.key});

  @override
  ConsumerState<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends ConsumerState<CanvasScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // Scroll to the bottom after messages update
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    final me = ref.read(currentUserProvider).valueOrNull;
    if (me?.coupleId == null) return;

    setState(() => _sending = true);
    _inputCtrl.clear();

    try {
      await sendCanvasMessage(
        coupleId: me!.coupleId!,
        uid: me.uid,
        text: text,
        color: me.color,
        firestore: ref.read(firestoreProvider),
      );
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canvasAsync = ref.watch(canvasStreamProvider);
    final me = ref.watch(currentUserProvider).valueOrNull;

    // Scroll down when messages change
    canvasAsync.whenData((_) => _scrollToBottom());

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  Text(
                    'canvas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: kNearBlack,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'resets daily',
                    style: TextStyle(
                        fontSize: 11,
                        color: kMutedGray,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Messages ───────────────────────────────────────────────
            Expanded(
              child: canvasAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                    child: Text('Error: $e',
                        style: const TextStyle(color: kMutedGray))),
                data: (canvas) {
                  if (canvas == null || canvas.messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'nothing written today...',
                        style: TextStyle(
                            color: kMutedGray,
                            fontSize: 14,
                            fontStyle: FontStyle.italic),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    itemCount: canvas.messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = canvas.messages[i];
                      final isOwn = msg.uid == me?.uid;
                      return _MessageRow(
                        text: msg.text,
                        color: hexToColor(msg.color),
                        isOwn: isOwn,
                      );
                    },
                  );
                },
              ),
            ),

            // ── Input bar ──────────────────────────────────────────────
            const Divider(height: 1),
            _InputBar(
              controller: _inputCtrl,
              sending: _sending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Message row ───────────────────────────────────────────────────────────────

class _MessageRow extends StatelessWidget {
  final String text;
  final Color color;
  final bool isOwn;

  const _MessageRow({
    required this.text,
    required this.color,
    required this.isOwn,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Align(
        alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBackground,
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 10 + MediaQuery.of(context).viewInsets.bottom),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              minLines: 1,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: 'write something...',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Ink-drop send button
          GestureDetector(
            onTap: sending ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: sending ? kMutedGray : kNearBlack,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                ),
              ),
              child: sending
                  ? const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.arrow_upward, color: kBackground, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
