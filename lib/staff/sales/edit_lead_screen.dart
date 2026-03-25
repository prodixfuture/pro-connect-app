import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Design Tokens — Light Theme ─────────────────────────────────────────────
const _bg = Color(0xFFF0F3F8);
const _surface = Color(0xFFFFFFFF);
const _surfaceEl = Color(0xFFF4F6FB);
const _border = Color(0xFFE2E8F0);
const _accent = Color(0xFF4F46E5);
const _accentSoft = Color(0xFFEEF2FF);
const _green = Color(0xFF059669);
const _greenSoft = Color(0xFFD1FAE5);
const _amber = Color(0xFFD97706);
const _amberSoft = Color(0xFFFEF3C7);
const _red = Color(0xFFDC2626);
const _redSoft = Color(0xFFFEE2E2);
const _blue = Color(0xFF2563EB);
const _blueSoft = Color(0xFFDBEAFE);
const _purple = Color(0xFF7C3AED);
const _purpleSoft = Color(0xFFEDE9FE);
const _cyan = Color(0xFF0891B2);
const _textPri = Color(0xFF0F172A);
const _textSec = Color(0xFF475569);
const _textMuted = Color(0xFF94A3B8);

class EditLeadScreen extends StatefulWidget {
  const EditLeadScreen({super.key});
  @override
  State<EditLeadScreen> createState() => _EditLeadScreenState();
}

class _EditLeadScreenState extends State<EditLeadScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _dealCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _priority = 'medium';
  String _status = 'new';
  String _source = 'website';
  DateTime? _followUp;
  bool _saving = false;
  bool _loading = true;
  String? _leadId;

  late AnimationController _anim;
  late Animation<double> _fade;

  final _sources = [
    {'v': 'website', 'l': 'Website', 'i': Icons.language_rounded},
    {'v': 'referral', 'l': 'Referral', 'i': Icons.people_rounded},
    {'v': 'cold_call', 'l': 'Cold Call', 'i': Icons.phone_in_talk_rounded},
    {'v': 'social_media', 'l': 'Social', 'i': Icons.trending_up_rounded},
    {'v': 'event', 'l': 'Event', 'i': Icons.event_available_rounded},
    {'v': 'other', 'l': 'Other', 'i': Icons.more_horiz_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) _loadData();
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _phoneCtrl,
      _emailCtrl,
      _companyCtrl,
      _dealCtrl,
      _notesCtrl
    ]) c.dispose();
    _anim.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _leadId = ModalRoute.of(context)?.settings.arguments as String?;
    if (_leadId == null) {
      Navigator.pop(context);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('leads')
          .doc(_leadId)
          .get();
      if (!doc.exists) {
        Navigator.pop(context);
        return;
      }
      final d = doc.data()!;
      if (mounted) {
        setState(() {
          _nameCtrl.text = d['name'] ?? '';
          _phoneCtrl.text = d['phone'] ?? '';
          _emailCtrl.text = d['email'] ?? '';
          _companyCtrl.text = d['company'] ?? '';
          _dealCtrl.text = d['dealValue']?.toString() ?? '';
          _notesCtrl.text = d['notes'] ?? '';
          _priority = d['priority'] ?? 'medium';
          _status = d['status'] ?? 'new';
          _source = d['source'] ?? 'website';
          if (d['nextFollowUp'] != null)
            _followUp = (d['nextFollowUp'] as Timestamp).toDate();
          _loading = false;
        });
        _anim.forward();
      }
    } catch (e) {
      if (mounted) {
        _snack('Error loading: $e', true);
        Navigator.pop(context);
      }
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _followUp ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (c, ch) => Theme(
          data: ThemeData.light()
              .copyWith(colorScheme: const ColorScheme.light(primary: _accent)),
          child: ch!),
    );
    if (d != null && mounted) {
      final t = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
          builder: (c, ch) => Theme(
              data: ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(primary: _accent)),
              child: ch!));
      if (t != null)
        setState(() =>
            _followUp = DateTime(d.year, d.month, d.day, t.hour, t.minute));
    }
  }

  Future<void> _update() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('leads').doc(_leadId).update({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'company': _companyCtrl.text.trim(),
        'dealValue': _dealCtrl.text.isNotEmpty
            ? double.tryParse(_dealCtrl.text) ?? 0
            : 0,
        'notes': _notesCtrl.text.trim(),
        'priority': _priority,
        'status': _status,
        'source': _source,
        'nextFollowUp': _followUp,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _snack('Lead updated!', false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _snack('Failed: $e', true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (_) => Dialog(
              backgroundColor: _surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22)),
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                            color: _redSoft, shape: BoxShape.circle),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: _red, size: 26)),
                    const SizedBox(height: 16),
                    const Text('Delete Lead?',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _textPri)),
                    const SizedBox(height: 8),
                    const Text('This action is permanent and cannot be undone.',
                        style: TextStyle(color: _textSec, fontSize: 13),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    Row(children: [
                      Expanded(
                          child: SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: _textSec,
                                      side: BorderSide(color: _border),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12))),
                                  child: const Text('Cancel',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600))))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: _red,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12))),
                                  child: const Text('Delete',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700))))),
                    ]),
                  ])),
            ));
    if (ok != true) return;
    try {
      await FirebaseFirestore.instance
          .collection('leads')
          .doc(_leadId)
          .delete();
      if (mounted) {
        _snack('Lead deleted', false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _snack('Failed: $e', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
            child: CircularProgressIndicator(color: _accent, strokeWidth: 2)),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(slivers: [
        _sliverBar(),
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fade,
            child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('Contact Details'),
                        const SizedBox(height: 16),
                        _field('Full Name *', _nameCtrl, Icons.person_rounded,
                            validator: (v) => v!.isEmpty ? 'Required' : null),
                        const SizedBox(height: 12),
                        _field(
                            'Phone Number *', _phoneCtrl, Icons.phone_rounded,
                            keyboard: TextInputType.phone,
                            validator: (v) => v!.isEmpty ? 'Required' : null),
                        const SizedBox(height: 12),
                        _field('Email', _emailCtrl, Icons.email_rounded,
                            keyboard: TextInputType.emailAddress),
                        const SizedBox(height: 12),
                        _field('Company / Organisation', _companyCtrl,
                            Icons.business_rounded),
                        const SizedBox(height: 26),

                        _sectionHeader('Lead Details'),
                        const SizedBox(height: 16),
                        _fieldLabel('PRIORITY'),
                        const SizedBox(height: 10),
                        _prioritySelector(),
                        const SizedBox(height: 16),
                        _fieldLabel('STATUS'),
                        const SizedBox(height: 10),
                        _statusSelector(),
                        const SizedBox(height: 16),
                        _fieldLabel('SOURCE'),
                        const SizedBox(height: 10),
                        _sourceChips(),
                        const SizedBox(height: 16),
                        _field('Deal Value (₹)', _dealCtrl,
                            Icons.currency_rupee_rounded,
                            keyboard: TextInputType.number),
                        const SizedBox(height: 26),

                        _sectionHeader('Follow-up'),
                        const SizedBox(height: 14),
                        _followUpPicker(),
                        const SizedBox(height: 26),

                        _sectionHeader('Notes'),
                        const SizedBox(height: 14),
                        _field('Additional context or notes...', _notesCtrl,
                            Icons.notes_rounded,
                            maxLines: 4),
                        const SizedBox(height: 30),

                        // Buttons
                        Row(children: [
                          Expanded(
                              child: SizedBox(
                                  height: 56,
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _textSec,
                                      side: const BorderSide(
                                          color: _border, width: 1.5),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                    ),
                                    child: const Text('Cancel',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14)),
                                  ))),
                          const SizedBox(width: 12),
                          Expanded(
                              flex: 2,
                              child: GestureDetector(
                                onTap: _saving ? null : _update,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: _saving ? _surfaceEl : _accent,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: _saving
                                        ? []
                                        : [
                                            BoxShadow(
                                                color: _accent.withOpacity(0.3),
                                                blurRadius: 16,
                                                offset: const Offset(0, 6))
                                          ],
                                  ),
                                  child: Center(
                                      child: _saving
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                  color: _accent,
                                                  strokeWidth: 2.5))
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                  Icon(Icons.save_rounded,
                                                      color: Colors.white,
                                                      size: 18),
                                                  SizedBox(width: 10),
                                                  Text('Update Lead',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w700)),
                                                ])),
                                ),
                              )),
                        ]),
                        const SizedBox(height: 50),
                      ]),
                )),
          ),
        ),
      ]),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────
  Widget _sliverBar() => SliverAppBar(
        expandedHeight: 145,
        pinned: true,
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        forceElevated: true,
        shadowColor: Colors.black.withOpacity(0.06),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: _surfaceEl,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border)),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _textPri, size: 16)),
        ),
        actions: [
          GestureDetector(
            onTap: _delete,
            child: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: _redSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _red.withOpacity(0.25))),
                child: const Icon(Icons.delete_outline_rounded,
                    color: _red, size: 18)),
          ),
        ],
        flexibleSpace: FlexibleSpaceBar(
          background: Container(
            color: _surface,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: _purpleSoft,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _purple.withOpacity(0.2))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                              color: _purple, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('EDIT LEAD',
                          style: TextStyle(
                              color: _purple,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.6)),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _nameCtrl.text.isEmpty ? 'Edit Lead' : _nameCtrl.text,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: _textPri,
                        letterSpacing: -0.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ]),
          ),
        ),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _border)),
      );

  // ── Form helpers ──────────────────────────────────────────────────────────
  Widget _sectionHeader(String title) => Row(children: [
        Text(title,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: _textPri)),
        const SizedBox(width: 12),
        Expanded(
            child: Container(
                height: 1,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [_border, _border.withOpacity(0)])))),
      ]);

  Widget _fieldLabel(String t) => Text(t,
      style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _textMuted,
          letterSpacing: 1.4));

  Widget _field(String hint, TextEditingController ctrl, IconData icon,
      {int maxLines = 1,
      TextInputType? keyboard,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: validator,
      keyboardType: keyboard,
      style: const TextStyle(color: _textPri, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
        prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(icon, color: _textMuted, size: 18)),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _border, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _accent, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _red)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _red, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  Widget _prioritySelector() {
    const opts = ['low', 'medium', 'high'];
    const lbls = ['Low', 'Medium', 'High'];
    const icons = [
      Icons.south_rounded,
      Icons.remove_rounded,
      Icons.north_rounded
    ];
    final colors = [_green, _amber, _red];
    final softs = [_greenSoft, _amberSoft, _redSoft];
    return Row(
        children: List.generate(3, (i) {
      final sel = _priority == opts[i];
      return Expanded(
          child: GestureDetector(
        onTap: () => setState(() => _priority = opts[i]),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: sel ? softs[i] : _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: sel ? colors[i] : _border, width: 1.5),
          ),
          child: Column(children: [
            Icon(icons[i], size: 18, color: sel ? colors[i] : _textMuted),
            const SizedBox(height: 5),
            Text(lbls[i],
                style: TextStyle(
                    color: sel ? colors[i] : _textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      ));
    }));
  }

  Widget _statusSelector() {
    const opts = ['new', 'contacted', 'in_progress', 'converted', 'lost'];
    const lbls = ['New', 'Contacted', 'In Progress', 'Converted', 'Lost'];
    const icons = [
      Icons.fiber_new_rounded,
      Icons.call_made_rounded,
      Icons.autorenew_rounded,
      Icons.check_circle_rounded,
      Icons.cancel_rounded
    ];
    final colors = [_blue, _purple, _amber, _green, _red];
    final softs = [_blueSoft, _purpleSoft, _amberSoft, _greenSoft, _redSoft];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
          children: List.generate(opts.length, (i) {
        final sel = _status == opts[i];
        return GestureDetector(
          onTap: () => setState(() => _status = opts[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: EdgeInsets.only(right: i < opts.length - 1 ? 8 : 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: sel ? softs[i] : _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: sel ? colors[i] : _border, width: 1.5),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icons[i], size: 13, color: sel ? colors[i] : _textMuted),
              const SizedBox(width: 6),
              Text(lbls[i],
                  style: TextStyle(
                      color: sel ? colors[i] : _textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        );
      })),
    );
  }

  Widget _sourceChips() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _sources.map((s) {
          final sel = _source == s['v'];
          return GestureDetector(
            onTap: () => setState(() => _source = s['v'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: sel ? _accentSoft : _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sel ? _accent : _border, width: 1.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(s['i'] as IconData,
                    size: 13, color: sel ? _accent : _textMuted),
                const SizedBox(width: 6),
                Text(s['l'] as String,
                    style: TextStyle(
                        color: sel ? _accent : _textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          );
        }).toList(),
      );

  Widget _followUpPicker() => GestureDetector(
        onTap: _pickDate,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border, width: 1.5)),
          child: Row(children: [
            Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: _accentSoft, borderRadius: BorderRadius.circular(9)),
                child:
                    const Icon(Icons.event_rounded, color: _accent, size: 16)),
            const SizedBox(width: 12),
            Expanded(
                child: Text(
              _followUp == null
                  ? 'Select date & time'
                  : '${_followUp!.day.toString().padLeft(2, '0')}/${_followUp!.month.toString().padLeft(2, '0')}/${_followUp!.year}  ${_followUp!.hour}:${_followUp!.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                  color: _followUp == null ? _textMuted : _textPri,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            )),
            if (_followUp != null)
              GestureDetector(
                  onTap: () => setState(() => _followUp = null),
                  child: const Icon(Icons.close_rounded,
                      color: _textMuted, size: 16))
            else
              const Icon(Icons.chevron_right_rounded,
                  color: _textMuted, size: 18),
          ]),
        ),
      );

  void _snack(String msg, bool err) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: err ? _red : _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
}
