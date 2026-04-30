import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/event_model.dart';
import '../../providers/user_provider.dart';
import '../../theme.dart';
import '../../widgets/ink_dot.dart';

class AddEventSheet extends ConsumerStatefulWidget {
  final DateTime initialDate;
  final EventModel? editingEvent; // non-null when editing an existing event

  const AddEventSheet({
    super.key,
    required this.initialDate,
    this.editingEvent,
  });

  @override
  ConsumerState<AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends ConsumerState<AddEventSheet> {
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _isPaired = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.editingEvent;
    if (e != null) {
      _titleCtrl.text = e.title;
      _locationCtrl.text = e.location ?? '';
      _noteCtrl.text = e.note ?? '';
      _date = DateTime(e.startTime.year, e.startTime.month, e.startTime.day);
      _startTime = TimeOfDay.fromDateTime(e.startTime);
      _endTime = TimeOfDay.fromDateTime(e.endTime);
    } else {
      _date = DateTime(widget.initialDate.year, widget.initialDate.month,
          widget.initialDate.day);
      final now = TimeOfDay.now();
      _startTime = TimeOfDay(hour: now.hour, minute: 0);
      _endTime = TimeOfDay(
          hour: (now.hour + 1).clamp(0, 23), minute: 0);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  DateTime _combine(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: kNearBlack),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: kNearBlack),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
        // Auto-advance end time if it would be before start
        final start = _combine(_date, picked);
        final end = _combine(_date, _endTime);
        if (!end.isAfter(start)) {
          _endTime = TimeOfDay(
              hour: (picked.hour + 1).clamp(0, 23), minute: picked.minute);
        }
      } else {
        _endTime = picked;
      }
    });
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Title is required.');
      return;
    }
    final start = _combine(_date, _startTime);
    final end = _combine(_date, _endTime);
    if (!end.isAfter(start)) {
      setState(() => _error = 'End time must be after start time.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final me = ref.read(currentUserProvider).valueOrNull;
      if (me == null) throw Exception('Not signed in.');
      final partner = ref.read(partnerProvider).valueOrNull;

      // Fall back to solo coupleId (own uid) when not yet paired
      final coupleId = me.coupleId ?? me.uid;

      final db = ref.read(firestoreProvider);
      final data = EventModel(
        id: widget.editingEvent?.id ?? '',
        ownerId: me.uid,
        coupleId: coupleId,
        title: title,
        startTime: start,
        endTime: end,
        location:
            _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        color: me.color,
        isPaired: _isPaired && partner != null,
        partnerColor: (_isPaired && partner != null) ? partner.color : null,
      ).toMap();

      if (widget.editingEvent != null) {
        await db.collection('events').doc(widget.editingEvent!.id).update(data);
      } else {
        await db.collection('events').add(data);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final partner = ref.watch(partnerProvider).valueOrNull;
    final me = ref.watch(currentUserProvider).valueOrNull;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: kCardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.editingEvent != null ? 'edit event' : 'new event',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: kNearBlack),
          ),
          const SizedBox(height: 20),

          // Title
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'title'),
          ),
          const SizedBox(height: 12),

          // Date + times row
          Row(
            children: [
              Expanded(
                child: _FieldTile(
                  label: 'date',
                  value: DateFormat('MMM d').format(_date),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FieldTile(
                  label: 'start',
                  value: _startTime.format(context),
                  onTap: () => _pickTime(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FieldTile(
                  label: 'end',
                  value: _endTime.format(context),
                  onTap: () => _pickTime(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Location (optional)
          TextField(
            controller: _locationCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'location (optional)'),
          ),
          const SizedBox(height: 12),

          // Note (optional)
          TextField(
            controller: _noteCtrl,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'note (optional)'),
          ),
          const SizedBox(height: 12),

          // Paired event toggle (only shown when partner exists)
          if (partner != null) ...[
            GestureDetector(
              onTap: () => setState(() => _isPaired = !_isPaired),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _isPaired ? kNearBlack.withOpacity(0.05) : kCardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isPaired ? kNearBlack.withOpacity(0.2) : kBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Row(
                      children: [
                        InkDot(color: hexToColor(me?.color ?? '#B8A9D9')),
                        const SizedBox(width: 4),
                        InkDot(color: hexToColor(partner.color)),
                      ],
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'paired event',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: kNearBlack,
                        ),
                      ),
                    ),
                    Switch(
                      value: _isPaired,
                      onChanged: (v) => setState(() => _isPaired = v),
                      activeColor: kNearBlack,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style:
                    const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ],
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: kNearBlack,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'save',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _FieldTile(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: kCardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 10, color: kMutedGray)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kNearBlack)),
          ],
        ),
      ),
    );
  }
}
