// chat_screen.dart — Minimal Purple Theme, matching chat list UI
// pubspec.yaml deps:
//   record: ^6.0.0
//   just_audio: ^0.9.36
//   permission_handler: ^11.0.0
//   path_provider: ^2.1.2
//   cloud_firestore: ^5.0.0
//   firebase_storage: ^11.0.0

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'chat_service.dart';

// ── Design tokens — matches chat list screen ─────────────
const _primary    = Color(0xFF6C63FF); // same purple as chat list
const _primaryLt  = Color(0xFFEEECFF); // light purple tint
const _bgPage     = Color(0xFFF4F3FF); // lavender page bg
const _bgChat     = Color(0xFFEFEEFA); // chat area bg (slightly warmer)
const _sentColor  = Color(0xFF6C63FF); // sent bubble = primary purple
const _recvColor  = Colors.white;
const _sentText   = Colors.white;
const _recvText   = Color(0xFF1A1D2E);
const _tickBlue   = Color(0xFF93C5FD); // soft blue read tick
const _timeLight  = Color(0xFFBBB9CC); // time on sent bubbles
const _timeDark   = Color(0xFFAAABB5); // time on received bubbles
const _inputBg    = Colors.white;
const _borderCol  = Color(0xFFE4E2F8);

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  final String? otherUserAvatar;
  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    this.otherUserAvatar,
  });
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _svc     = ChatService();
  final _ctrl    = TextEditingController();
  final _scroll  = ScrollController();
  final _hasText = ValueNotifier(false);
  bool _sending   = false;
  bool _showEmoji = false;
  String? _reactId;
  final Map<String, String> _reactions = {};
  static const _rxSet = ['👍','❤️','😂','😮','😢','🙏'];

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => _hasText.value = _ctrl.text.isNotEmpty);
    _svc.markMessagesAsRead(widget.chatId);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _hasText.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════
  // ROOT
  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      backgroundColor: _bgChat,
      appBar: _appBar(),
      body: Column(children: [
        Expanded(child: _msgList()),
        if (_showEmoji) _emojiBar(),
        _inputBar(),
      ]),
    );
  }

  // ── APP BAR ────────────────────────────────────────────
  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleSpacing: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _borderCol),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _primary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: _contactSheet,
        child: Row(children: [
          _ava(widget.otherUserName, widget.otherUserAvatar, 40),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.otherUserName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1D2E)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Row(children: [
                Container(width: 7, height: 7,
                    decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle)),
                const SizedBox(width: 4),
                const Text('online', style: TextStyle(fontSize: 12, color: Color(0xFF9E9CB0), fontWeight: FontWeight.w400)),
              ]),
            ],
          )),
        ]),
      ),
      actions: [


        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF6B6880), size: 22),
          color: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onSelected: (v) {
            if (v == 'clear') _confirmClear();
            if (v == 'info')  _contactSheet();
          },
          itemBuilder: (_) => [
            _mi('info',  Icons.person_outline_rounded, 'Contact info'),
            _mi('clear', Icons.delete_sweep_rounded,   'Clear chat'),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  PopupMenuItem<String> _mi(String v, IconData icon, String lbl) =>
      PopupMenuItem(value: v, child: Row(children: [
        Icon(icon, size: 20, color: _primary), const SizedBox(width: 12),
        Text(lbl, style: const TextStyle(fontSize: 14, color: Color(0xFF1A1D2E))),
      ]));

  // ── MESSAGE LIST ───────────────────────────────────────
  Widget _msgList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _svc.getChatMessages(widget.chatId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(
              strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(_primary)));
        }
        if (snap.hasError) return _errState();
        final msgs = snap.data ?? [];
        if (msgs.isEmpty) return _emptyState();

        WidgetsBinding.instance.addPostFrameCallback(
                (_) => _svc.markMessagesAsRead(widget.chatId));

        // msgs come from Firestore ordered newest-first (reverse:true list).
        // We group by date. Since list is reversed, we compare each msg with
        // the NEXT item (which is older). When the date changes, insert separator.
        final items = _buildItemList(msgs);

        return GestureDetector(
          onTap: () => setState(() { _showEmoji = false; _reactId = null; }),
          child: ListView.builder(
            controller: _scroll,
            reverse: true,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              if (item['_sep'] == true) return _dateSep(item['label'] as String);
              return _msgRow(item);
            },
          ),
        );
      },
    );
  }

  // ── DATE SEPARATOR LOGIC ───────────────────────────────
  // List is reverse:true, so index 0 = newest message.
  // We compare each message's date with the next message's date (older).
  // When they differ, insert a separator AFTER the current item (visually ABOVE).
  List<Map<String, dynamic>> _buildItemList(List<Map<String, dynamic>> msgs) {
    final out = <Map<String, dynamic>>[];
    for (int i = 0; i < msgs.length; i++) {
      out.add(msgs[i]);
      final curTs  = (msgs[i]['createdAt'] as Timestamp?)?.toDate();
      final nextTs = (i + 1 < msgs.length)
          ? (msgs[i + 1]['createdAt'] as Timestamp?)?.toDate()
          : null;
      final curLbl  = curTs  != null ? _dateLabel(curTs)  : null;
      final nextLbl = nextTs != null ? _dateLabel(nextTs) : null;
      // If this is the last message OR date changes to next message → add separator
      if (curLbl != null && curLbl != nextLbl) {
        out.add({'_sep': true, 'label': curLbl});
      }
    }
    return out;
  }

  String _dateLabel(DateTime d) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dt    = DateTime(d.year, d.month, d.day);
    final diff  = today.difference(dt).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7)  return ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'][d.weekday - 1];
    return '${d.day} ${_monthName(d.month)} ${d.year}';
  }

  String _monthName(int m) => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];

  Widget _dateSep(String label) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderCol),
          boxShadow: [BoxShadow(color: _primary.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 1))],
        ),
        child: Text(label, style: const TextStyle(
            fontSize: 12, color: Color(0xFF7B78A8), fontWeight: FontWeight.w600, letterSpacing: 0.2)),
      ),
    );
  }

  // ── MESSAGE ROW ────────────────────────────────────────
  Widget _msgRow(Map<String, dynamic> msg) {
    final isSend = msg['senderId'] == _svc.currentUserId;
    final type   = msg['type'] as String? ?? 'text';
    if (type == 'system') return _sysMsg(msg['text'] as String? ?? '');

    final id       = msg['messageId'] as String? ?? '';
    final reaction = _reactions[id];
    final reacting = _reactId == id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: isSend ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (reacting) _rxPicker(msg),
          Row(
            mainAxisAlignment: isSend ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isSend) ...[
                _ava(widget.otherUserName, widget.otherUserAvatar, 30),
                const SizedBox(width: 6),
              ],
              Flexible(child: GestureDetector(
                onLongPress: () => _msgSheet(msg, isSend),
                onDoubleTap: () => setState(() => _reactId = _reactId == id ? null : id),
                child: _bubble(msg, isSend),
              )),
              if (isSend) const SizedBox(width: 2),
            ],
          ),
          if (reaction != null)
            Padding(
              padding: EdgeInsets.only(left: isSend ? 0 : 42, right: isSend ? 4 : 0, top: 3),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderCol),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)],
                ),
                child: Text(reaction, style: const TextStyle(fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _rxPicker(Map<String, dynamic> msg) {
    final id = msg['messageId'] as String? ?? '';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 40, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _borderCol),
          boxShadow: [BoxShadow(color: _primary.withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: _rxSet.map((e) {
          final sel = _reactions[id] == e;
          return GestureDetector(
            onTap: () => setState(() { sel ? _reactions.remove(id) : _reactions[id] = e; _reactId = null; }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                  color: sel ? _primary.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16)),
              child: Text(e, style: TextStyle(fontSize: sel ? 27 : 23)),
            ),
          );
        }).toList()),
      ),
    );
  }

  // ── BUBBLE ─────────────────────────────────────────────
  Widget _bubble(Map<String, dynamic> msg, bool isSend) {
    final type   = msg['type'] as String? ?? 'text';
    final text   = msg['text'] as String? ?? '';
    final ts     = msg['createdAt'] as Timestamp?;
    final readBy = List<String>.from(msg['readBy'] ?? []);
    final isRead = readBy.length > 1;
    final time   = _fmt12(ts);

    if (type == 'emoji')  return _emojiBubble(text, time, isSend, isRead);
    if (type == 'audio' && msg['audioUrl'] != null)
      return _voiceBubble(msg, isSend, time, isRead);
    return _textBubble(text, time, isSend, isRead);
  }

  // ── TEXT BUBBLE ─────────────────────────────────────────
  Widget _textBubble(String text, String time, bool isSend, bool isRead) {
    final bg       = isSend ? _sentColor : _recvColor;
    final fg       = isSend ? _sentText  : _recvText;
    final timeCol  = isSend ? _timeLight : _timeDark;
    final tickCol  = isRead ? _tickBlue  : _timeLight;

    // Time + tick widget appended inline after text (no gap)
    final timeWidget = Row(mainAxisSize: MainAxisSize.min, children: [
      Text(' $time', style: TextStyle(fontSize: 10.5, color: timeCol, fontWeight: FontWeight.w400)),
      if (isSend) ...[
        const SizedBox(width: 2),
        Icon(isRead ? Icons.done_all_rounded : Icons.done_rounded, size: 13, color: tickCol),
      ],
    ]);

    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.only(
          topLeft:     const Radius.circular(18),
          topRight:    const Radius.circular(18),
          bottomLeft:  Radius.circular(isSend ? 18 : 4),
          bottomRight: Radius.circular(isSend ? 4  : 18),
        ),
        boxShadow: [BoxShadow(
            color: (isSend ? _primary : Colors.black).withOpacity(0.10),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      // Wrap text + time so they flow together — time sits inline at end of last line
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          Text(text, style: TextStyle(fontSize: 15.5, color: fg, height: 1.38, fontWeight: FontWeight.w400)),
          timeWidget,
        ],
      ),
    );
  }

  Widget _emojiBubble(String text, String time, bool isSend, bool isRead) {
    return Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
      Text(text, style: const TextStyle(fontSize: 40)),
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text(time, style: const TextStyle(fontSize: 10.5, color: _timeDark)),
        if (isSend) ...[
          const SizedBox(width: 3),
          Icon(isRead ? Icons.done_all_rounded : Icons.done_rounded,
              size: 13, color: isRead ? _tickBlue : _timeDark),
        ],
      ]),
    ]);
  }

  Widget _voiceBubble(Map<String, dynamic> msg, bool isSend, String time, bool isRead) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.80),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: isSend ? _sentColor : _recvColor,
        borderRadius: BorderRadius.only(
          topLeft:     const Radius.circular(18),
          topRight:    const Radius.circular(18),
          bottomLeft:  Radius.circular(isSend ? 18 : 4),
          bottomRight: Radius.circular(isSend ? 4  : 18),
        ),
        boxShadow: [BoxShadow(
            color: (isSend ? _primary : Colors.black).withOpacity(0.10),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: _VoicePlayer(
        audioUrl: msg['audioUrl'] as String,
        duration: msg['audioDuration'] as String? ?? '0:00',
        isSend: isSend,
        avatarName: isSend ? 'me' : widget.otherUserName,
        avatarUrl: isSend ? null : widget.otherUserAvatar,
        time: time, isRead: isRead,
      ),
    );
  }

  Widget _sysMsg(String text) {
    return Center(child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderCol)),
      child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF7B78A8), fontWeight: FontWeight.w500)),
    ));
  }

  // ── EMOJI BAR ──────────────────────────────────────────
  Widget _emojiBar() {
    const emojis = ['😊','😂','❤️','👍','🎉','🔥','🙏','😍','😎','🤔','👏','💯','✨','🚀','💪','🙌'];
    return Container(
      height: 54,
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: _borderCol))),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: emojis.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _sendEmoji(emojis[i]),
          child: Container(width: 46, alignment: Alignment.center,
              child: Text(emojis[i], style: const TextStyle(fontSize: 25))),
        ),
      ),
    );
  }

  // ── INPUT BAR ──────────────────────────────────────────
  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _borderCol, width: 1)),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          // Emoji toggle
          GestureDetector(
            onTap: () => setState(() => _showEmoji = !_showEmoji),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10, right: 8),
              child: Icon(
                  _showEmoji ? Icons.keyboard_rounded : Icons.emoji_emotions_outlined,
                  color: _primary, size: 24),
            ),
          ),
          // Text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _bgPage,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _borderCol, width: 1.2),
              ),
              child: TextField(
                controller: _ctrl,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 15.5, color: Color(0xFF1A1D2E), height: 1.4),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15.5),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send / Mic button — TAP for both
          ValueListenableBuilder<bool>(
            valueListenable: _hasText,
            builder: (_, hasText, __) {
              return GestureDetector(
                onTap: hasText
                    ? (_sending ? null : _doSend)
                    : _openVoice,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _primary,
                    boxShadow: [BoxShadow(color: _primary.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: Center(
                    child: _sending
                        ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Icon(hasText ? Icons.send_rounded : Icons.mic_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              );
            },
          ),
        ]),
      ),
    );
  }

  // ── MESSAGE OPTIONS SHEET ──────────────────────────────
  void _msgSheet(Map<String, dynamic> msg, bool isSend) {
    final text = msg['text'] as String? ?? '';
    final type = msg['type'] as String? ?? 'text';
    final id   = msg['messageId'] as String? ?? '';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          // Reaction row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: _rxSet.map((e) {
              final sel = _reactions[id] == e;
              return GestureDetector(
                onTap: () { Navigator.pop(ctx); setState(() { sel ? _reactions.remove(id) : _reactions[id] = e; }); },
                child: AnimatedScale(
                    scale: sel ? 1.35 : 1.0, duration: const Duration(milliseconds: 150),
                    child: Text(e, style: const TextStyle(fontSize: 30))),
              );
            }).toList()),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          if (type == 'text' || type == 'emoji')
            _optTile(Icons.copy_rounded, 'Copy', const Color(0xFF1A1D2E), () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(ctx);
              _snack('Copied');
            }),
          _optTile(Icons.reply_rounded,   'Reply',   const Color(0xFF1A1D2E), () => Navigator.pop(ctx)),
          _optTile(Icons.forward_rounded, 'Forward', const Color(0xFF1A1D2E), () => Navigator.pop(ctx)),
          if (isSend)
            _optTile(Icons.delete_outline_rounded, 'Delete message', Colors.red.shade400, () async {
              Navigator.pop(ctx);
              await _svc.deleteMessage(widget.chatId, id);
              if (mounted) _snack('Deleted');
            }),
        ]),
      ),
    );
  }

  Widget _optTile(IconData icon, String lbl, Color col, VoidCallback fn) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        leading: Icon(icon, color: col, size: 22),
        title: Text(lbl, style: TextStyle(color: col, fontSize: 15, fontWeight: FontWeight.w400)),
        dense: true, onTap: fn,
      );

  // ── SEND TEXT ──────────────────────────────────────────
  void _doSend() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() { _sending = true; _showEmoji = false; });
    _ctrl.clear();
    try {
      await _svc.sendTextMessage(widget.chatId, text);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.animateTo(0,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      });
    } catch (_) { if (mounted) _snack('Failed to send', err: true); }
    finally { if (mounted) setState(() => _sending = false); }
  }


  void _sendEmoji(String e) async {
    setState(() => _showEmoji = false);
    try { await _svc.sendEmojiMessage(widget.chatId, e); }
    catch (_) { if (mounted) _snack('Failed', err: true); }
  }

  // ── VOICE RECORDER ─────────────────────────────────────
  void _openVoice() async {
    if (kIsWeb) {
      _snack('Voice recording not supported on web yet', err: false);
      return;
    }
    // Android / iOS
    PermissionStatus status;
    try {
      status = await Permission.microphone.request();
    } catch (e) {
      if (mounted) _snack('Permission error: $e', err: true);
      return;
    }

    if (!status.isGranted) {
      if (mounted) {
        if (status.isPermanentlyDenied) {
          _showPermDeniedDialog();
        } else {
          _snack('Microphone permission required', err: true);
        }
      }
      return;
    }

    String? tmp;
    try {
      tmp = (await getTemporaryDirectory()).path;
    } catch (_) {
      try {
        tmp = (await getApplicationDocumentsDirectory()).path;
      } catch (e) {
        if (mounted) _snack('Cannot access storage: $e', err: true);
        return;
      }
    }
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _VoiceRecorder(
        tmpDir: tmp!,
        onSend: (file, dur) async {
          try {
            setState(() => _sending = true);
            await _svc.sendVoiceMessage(widget.chatId, file, dur);
          } catch (e) {
            if (mounted) _snack('Send failed: $e', err: true);
          } finally {
            if (mounted) setState(() => _sending = false);
          }
        },
      ),
    );
  }

  void _showPermDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Microphone Required', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Please enable microphone access in your device Settings to use voice messages.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); openAppSettings(); },
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Clear chat', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('All messages will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600]))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try { await _svc.clearChat(widget.chatId); if (mounted) _snack('Chat cleared'); }
      catch (_) { if (mounted) _snack('Failed', err: true); }
    }
  }

  void _contactSheet() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          _ava(widget.otherUserName, widget.otherUserAvatar, 72),
          const SizedBox(height: 12),
          Text(widget.otherUserName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1D2E))),
          const SizedBox(height: 4),
          const Text('online', style: TextStyle(color: Color(0xFF9E9CB0), fontSize: 13)),
        ]),
      ),
    );
  }

  // ── HELPERS ────────────────────────────────────────────
  Widget _ava(String name, String? url, double size) {
    // Same avatar colors as chat list screen
    final colors = [
      _primary, const Color(0xFF5B8DEF), const Color(0xFFFF6B6B),
      const Color(0xFFFFB347), const Color(0xFF26C6DA), const Color(0xFFAB47BC),
    ];
    final col = colors[name.hashCode.abs() % colors.length];
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: url == null || url.isEmpty ? col.withOpacity(0.15) : null,
        image: url != null && url.isNotEmpty
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
      ),
      child: url == null || url.isEmpty
          ? Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(color: col, fontSize: size * 0.4, fontWeight: FontWeight.w700)))
          : null,
    );
  }

  String _fmt12(Timestamp? ts) {
    if (ts == null) return '';
    final d = ts.toDate();
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  void _snack(String msg, {bool err = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
      backgroundColor: err ? Colors.red.shade400 : _primary,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  Widget _errState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _primaryLt, shape: BoxShape.circle),
        child: const Icon(Icons.error_outline_rounded, size: 36, color: _primary)),
    const SizedBox(height: 14),
    const Text('Failed to load messages', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1D2E))),
    const SizedBox(height: 14),
    ElevatedButton(onPressed: () => setState(() {}),
        style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10)),
        child: const Text('Retry')),
  ]));

  Widget _emptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _primaryLt, shape: BoxShape.circle),
        child: const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: _primary)),
    const SizedBox(height: 14),
    const Text('No messages yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1D2E))),
    const SizedBox(height: 6),
    const Text('Say hello! 👋', style: TextStyle(color: Color(0xFF9E9CB0), fontSize: 14)),
  ]));
}

// ═══════════════════════════════════════════════════════
// VOICE PLAYER — clean minimal style
// ═══════════════════════════════════════════════════════
class _VoicePlayer extends StatefulWidget {
  final String audioUrl, duration, avatarName, time;
  final String? avatarUrl;
  final bool isSend, isRead;
  const _VoicePlayer({
    required this.audioUrl, required this.duration, required this.isSend,
    required this.avatarName, this.avatarUrl, required this.time, required this.isRead,
  });
  @override State<_VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<_VoicePlayer> {
  late final AudioPlayer _p;
  bool _loading = false, _playing = false;
  Duration _pos = Duration.zero, _total = Duration.zero;
  StreamSubscription? _posSub, _stateSub;

  static const _primary = Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();
    _p = AudioPlayer();
    _posSub = _p.positionStream.listen((v) { if (mounted) setState(() => _pos = v); });
    _stateSub = _p.playerStateStream.listen((s) {
      if (mounted) setState(() => _playing = s.playing);
      if (s.processingState == ProcessingState.completed) {
        _p.seek(Duration.zero);
        if (mounted) setState(() { _playing = false; _pos = Duration.zero; });
      }
    });
  }

  @override
  void dispose() { _posSub?.cancel(); _stateSub?.cancel(); _p.dispose(); super.dispose(); }

  Future<void> _toggle() async {
    if (_loading) return;
    if (_p.processingState == ProcessingState.idle) {
      setState(() => _loading = true);
      try {
        await _p.setUrl(widget.audioUrl);
        if (mounted) setState(() { _total = _p.duration ?? Duration.zero; _loading = false; });
      } catch (_) { if (mounted) setState(() => _loading = false); return; }
    }
    _playing ? _p.pause() : _p.play();
  }

  String _fmtD(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2,'0')}:${d.inSeconds.remainder(60).toString().padLeft(2,'0')}';

  int _parseSecs(String s) {
    final p = s.split(':');
    return p.length == 2 ? (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0) : 0;
  }

  @override
  Widget build(BuildContext ctx) {
    final total = _total.inSeconds > 0
        ? _total.inSeconds.toDouble()
        : _parseSecs(widget.duration).toDouble().clamp(1.0, double.infinity);
    final pos = _pos.inSeconds.clamp(0, total.toInt()).toDouble();

    final playCol  = widget.isSend ? Colors.white         : _primary;
    final playBg   = widget.isSend ? Colors.white.withOpacity(0.22) : _primary.withOpacity(0.1);
    final trackAct = widget.isSend ? Colors.white         : _primary;
    final trackIn  = widget.isSend ? Colors.white.withOpacity(0.3) : _primary.withOpacity(0.2);
    final timeCol  = widget.isSend ? _timeLight           : _timeDark;

    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      // Avatar circle
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isSend ? Colors.white.withOpacity(0.2) : _primary.withOpacity(0.1),
          image: widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
              ? DecorationImage(image: NetworkImage(widget.avatarUrl!), fit: BoxFit.cover) : null,
        ),
        child: widget.avatarUrl == null || widget.avatarUrl!.isEmpty
            ? Center(child: Text(
            widget.avatarName.isNotEmpty ? widget.avatarName[0].toUpperCase() : '?',
            style: TextStyle(color: playCol, fontSize: 15, fontWeight: FontWeight.w700)))
            : null,
      ),
      const SizedBox(width: 8),
      Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          // Play/pause button
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(shape: BoxShape.circle, color: playBg),
              child: Center(child: _loading
                  ? SizedBox(width: 15, height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2, color: playCol))
                  : Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: playCol, size: 20)),
            ),
          ),
          const SizedBox(width: 6),
          // Waveform slider
          Expanded(child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: trackAct,
              inactiveTrackColor: trackIn,
              thumbColor: trackAct,
              overlayColor: trackAct.withOpacity(0.12),
            ),
            child: Slider(value: pos, min: 0, max: total,
                onChanged: (v) => _p.seek(Duration(seconds: v.toInt()))),
          )),
        ]),
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 0, 2, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(_playing || _pos > Duration.zero ? _fmtD(_pos) : widget.duration,
                style: TextStyle(fontSize: 11, color: timeCol, fontWeight: FontWeight.w400)),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(widget.time, style: TextStyle(fontSize: 10.5, color: timeCol)),
              if (widget.isSend) ...[
                const SizedBox(width: 3),
                Icon(widget.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 13, color: widget.isRead ? _tickBlue : _timeLight),
              ],
            ]),
          ]),
        ),
      ])),
    ]);
  }
}

// ═══════════════════════════════════════════════════════
// VOICE RECORDER SHEET
// ═══════════════════════════════════════════════════════
class _VoiceRecorder extends StatefulWidget {
  final String tmpDir;
  final Future<void> Function(File, String) onSend;
  const _VoiceRecorder({required this.tmpDir, required this.onSend});
  @override State<_VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<_VoiceRecorder> with SingleTickerProviderStateMixin {
  final _rec = AudioRecorder();
  String? _path;
  bool _recording = false, _done = false;
  int _secs = 0;
  Timer? _timer;
  late AnimationController _pulse;
  late Animation<double> _anim;

  static const _primary = Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _anim = Tween(begin: 0.88, end: 1.0).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    // Start recording immediately when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() { _timer?.cancel(); _pulse.dispose(); _rec.dispose(); super.dispose(); }

  Future<void> _start() async {
    try {
      _path = '${widget.tmpDir}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _rec.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 44100, bitRate: 128000),
        path: _path!,
      );
      if (mounted) {
        setState(() { _recording = true; _done = false; _secs = 0; });
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() => _secs++);
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Microphone error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _stop() async {
    if (!_recording) return;
    _timer?.cancel();
    _pulse.stop();
    try {
      await _rec.stop();
      if (mounted) setState(() { _recording = false; _done = true; });
    } catch (_) { if (mounted) Navigator.pop(context); }
  }

  Future<void> _send() async {
    if (_path == null) { if (mounted) Navigator.pop(context); return; }
    final f = File(_path!);
    if (!await f.exists()) { if (mounted) Navigator.pop(context); return; }
    if (mounted) { Navigator.pop(context); widget.onSend(f, _fmt(_secs)); }
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    try {
      if (_recording) await _rec.stop();
      if (_path != null) { final f = File(_path!); if (await f.exists()) await f.delete(); }
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  Future<void> _redo() async {
    _timer?.cancel();
    try {
      if (_recording) await _rec.stop();
      if (_path != null) { final f = File(_path!); if (await f.exists()) await f.delete(); }
    } catch (_) {}
    if (mounted) {
      setState(() { _recording = false; _done = false; _secs = 0; });
      _pulse.repeat(reverse: true);
      await _start();
    }
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2,'0')}:${(s % 60).toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext ctx) {
    final col = _done ? _primary : _recording ? Colors.red.shade400 : Colors.grey;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 30),
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.14), blurRadius: 30, offset: const Offset(0, -4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle bar
        Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
        // Pulsing mic button
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Transform.scale(
            scale: _recording ? _anim.value : 1.0,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _done ? _primary.withOpacity(0.12) : _recording ? Colors.red.shade50 : Colors.grey.shade100,
                border: Border.all(color: col, width: 2),
                boxShadow: [BoxShadow(color: col.withOpacity(0.25), blurRadius: 20, spreadRadius: 3)],
              ),
              child: Icon(_done ? Icons.check_rounded : Icons.mic_rounded, color: col, size: 36),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _done ? 'Ready to send' : _recording ? 'Recording...' : 'Starting...',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: col),
        ),
        const SizedBox(height: 4),
        // Timer
        Text(_fmt(_secs), style: TextStyle(
            fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -2,
            color: _done ? _primary : _recording ? Colors.red.shade400 : Colors.grey)),
        const SizedBox(height: 14),
        if (_recording) ...[_wave(), const SizedBox(height: 20)] else const SizedBox(height: 20),
        // Buttons
        if (_recording)
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _btn(Icons.close_rounded, Colors.grey.shade100, Colors.grey.shade600, _cancel),
            _btn(Icons.stop_rounded, Colors.red.shade400, Colors.white, _stop, sz: 60),
            const SizedBox(width: 46),
          ])
        else if (_done)
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _btn(Icons.close_rounded,   Colors.grey.shade100,       Colors.grey.shade600, _cancel),
            _btn(Icons.refresh_rounded, _primary.withOpacity(0.1),  _primary,             _redo),
            _btn(Icons.send_rounded,    _primary,                   Colors.white,         _send, sz: 60),
          ]),
        const SizedBox(height: 6),
        Text(
          _recording ? 'Tap ■ to stop recording' : _done ? 'Tap ▶ to send' : '',
          style: const TextStyle(fontSize: 12, color: Color(0xFF9E9CB0)),
        ),
      ]),
    );
  }

  Widget _wave() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(28, (i) {
          final seed = (i % 7 + 1) * 4.0;
          final h = (seed + _pulse.value * seed * 0.85).clamp(4.0, 32.0);
          return AnimatedContainer(
            duration: Duration(milliseconds: 60 + i * 11),
            width: 3, height: h, margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
                color: Colors.red.shade300.withOpacity(0.55 + (i % 4) * 0.1),
                borderRadius: BorderRadius.circular(2)),
          );
        }),
      ),
    );
  }

  Widget _btn(IconData icon, Color bg, Color fg, VoidCallback fn, {double sz = 50}) {
    return GestureDetector(
      onTap: fn,
      child: Container(
        width: sz, height: sz,
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(sz * 0.3),
            boxShadow: [BoxShadow(color: bg == Colors.grey.shade100 ? Colors.black12 : bg.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]),
        child: Center(child: Icon(icon, color: fg, size: sz * 0.44)),
      ),
    );
  }
}