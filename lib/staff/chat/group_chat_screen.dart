import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'chat_service.dart';

class GroupChatScreen extends StatefulWidget {
  final Map<String, dynamic> chatData;

  const GroupChatScreen({super.key, required this.chatData});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> with TickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _hasText = ValueNotifier<bool>(false);

  bool _isEmojiPickerVisible = false;
  bool _isSending = false;

  late String _chatId;
  late String _groupName;
  late bool _isAdmin;

  static const _primary = Color(0xFF6C63FF);
  static const _surface = Color(0xFFF0F2F7);
  static const _cardBg = Colors.white;
  static const _textPrimary = Color(0xFF1A1D2E);
  static const _textSecondary = Color(0xFF8B8FA8);

  final List<String> _quickEmojis = ['👍', '❤️', '😂', '😊', '🎉', '🔥', '👏', '🙏', '😍', '🤔', '😎', '💯', '✨', '🚀', '💪', '🙌'];

  @override
  void initState() {
    super.initState();
    _chatId = widget.chatData['chatId'] as String;
    _groupName = widget.chatData['groupName'] as String? ?? 'Group';
    _isAdmin = _chatService.isGroupAdmin(widget.chatData);

    _messageController.addListener(() => _hasText.value = _messageController.text.isNotEmpty);
    _chatService.markMessagesAsRead(_chatId);
    WidgetsBinding.instance.addPostFrameCallback((_) => _chatService.markMessagesAsRead(_chatId));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _hasText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memberCount = (widget.chatData['participants'] as List?)?.length ?? 0;

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () => _showGroupInfo(),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_primary, Color(0xFF9C94FF)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.groups_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_groupName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _textPrimary, letterSpacing: -0.3), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('$memberCount members • Tap for info', style: const TextStyle(fontSize: 11, color: _textSecondary, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [

          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: _textPrimary),
            onPressed: _showOptionsMenu,
          ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: const Color(0xFFF0F0F5))),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getChatMessages(_chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: _primary, strokeWidth: 2.5));
                }
                if (snapshot.hasError) return _buildErrorState();
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) return _buildEmptyState();

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  itemCount: _buildItems(messages).length,
                  itemBuilder: (_, i) {
                    final item = _buildItems(messages)[i];
                    if (item['_sep'] == true) return _buildDateSep(item['label'] as String);
                    return _buildMessageItem(item);
                  },
                );
              },
            ),
          ),
          if (_isEmojiPickerVisible) _buildEmojiPicker(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  // ── DATE SEPARATOR HELPERS ─────────────────────────────
  List<Map<String, dynamic>> _buildItems(List<Map<String, dynamic>> msgs) {
    final out = <Map<String, dynamic>>[];
    for (int i = 0; i < msgs.length; i++) {
      out.add(msgs[i]);
      final curTs  = (msgs[i]['createdAt'] as Timestamp?)?.toDate();
      final nextTs = (i + 1 < msgs.length)
          ? (msgs[i + 1]['createdAt'] as Timestamp?)?.toDate() : null;
      final curLbl  = curTs  != null ? _dateLabel(curTs)  : null;
      final nextLbl = nextTs != null ? _dateLabel(nextTs) : null;
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

  String _monthName(int m) =>
      ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];

  Widget _buildDateSep(String label) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE4E2F8)),
          boxShadow: [BoxShadow(color: _primary.withOpacity(0.06), blurRadius: 6, offset: const Offset(0,1))],
        ),
        child: Text(label, style: const TextStyle(
            fontSize: 12, color: Color(0xFF7B78A8), fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message) {
    final type = message['type'] as String? ?? 'text';

    if (type == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE4E2F8)),
            ),
            child: Text(
              message['text'] as String? ?? '',
              style: const TextStyle(fontSize: 12, color: Color(0xFF7B78A8), fontWeight: FontWeight.w500),
            ),
          ),
        ),
      );
    }

    final isSender    = message['senderId'] == _chatService.currentUserId;
    final text        = message['text'] as String? ?? '';
    final senderName  = message['senderName'] as String? ?? '';
    final createdAt   = message['createdAt'] as Timestamp?;
    final readBy      = List<String>.from(message['readBy'] ?? []);
    final timeString  = _chatService.formatTimestamp(createdAt);
    final isRead      = readBy.length > 1;
    final isAudio     = type == 'audio' && message['audioUrl'] != null;

    final bubbleBg    = isSender ? _primary : _cardBg;
    final textColor   = isSender ? Colors.white : _textPrimary;
    final timeColor   = isSender ? Colors.white.withOpacity(0.65) : _textSecondary;
    final tickColor   = isRead ? Colors.white : Colors.white.withOpacity(0.65);

    // Inline time widget — floats at end of last text line (no gap)
    final timeRow = Row(mainAxisSize: MainAxisSize.min, children: [
      Text(' $timeString', style: TextStyle(fontSize: 10.5, color: timeColor, fontWeight: FontWeight.w400)),
      if (isSender) ...[
        const SizedBox(width: 2),
        Icon(isRead ? Icons.done_all_rounded : Icons.done_rounded, size: 13, color: tickColor),
      ],
    ]);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSender)
            Container(
              width: 30, height: 30,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: _getAvatarColor(senderName),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Text(
                  senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(message),
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                padding: isAudio
                    ? const EdgeInsets.fromLTRB(10, 10, 10, 8)
                    : const EdgeInsets.fromLTRB(12, 9, 12, 7),
                decoration: BoxDecoration(
                  color: bubbleBg,
                  borderRadius: BorderRadius.only(
                    topLeft:     const Radius.circular(18),
                    topRight:    const Radius.circular(18),
                    bottomLeft:  Radius.circular(isSender ? 18 : 4),
                    bottomRight: Radius.circular(isSender ? 4 : 18),
                  ),
                  boxShadow: [BoxShadow(
                    color: isSender ? _primary.withOpacity(0.2) : Colors.black.withOpacity(0.06),
                    blurRadius: 8, offset: const Offset(0, 2),
                  )],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sender name (group only, for received messages)
                    if (!isSender)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(senderName,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                color: _getAvatarColor(senderName))),
                      ),
                    // Voice message OR text (Wrap so time flows inline)
                    if (isAudio)
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        _VoiceMessagePlayer(
                          audioUrl: message['audioUrl'] as String,
                          duration: message['audioDuration'] as String? ?? '0:00',
                          isSender: isSender,
                        ),
                        timeRow,
                      ])
                    else
                      Wrap(
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          Text(text, style: TextStyle(
                              fontSize: 15, color: textColor, height: 1.4, fontWeight: FontWeight.w500)),
                          timeRow,
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF6C63FF), const Color(0xFF34C759), const Color(0xFFFF9500),
      const Color(0xFFFF3B30), const Color(0xFF00C7BE), const Color(0xFFFF2D55),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  Widget _buildEmojiPicker() {
    return Container(
      height: 200,
      decoration: const BoxDecoration(color: _cardBg, border: Border(top: BorderSide(color: Color(0xFFF0F0F5)))),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Quick Reactions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textPrimary)),
            IconButton(icon: const Icon(Icons.close_rounded, size: 20, color: _textSecondary), onPressed: () => setState(() => _isEmojiPickerVisible = false)),
          ]),
        ),
        Expanded(child: GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8, mainAxisSpacing: 8, crossAxisSpacing: 8),
          itemCount: _quickEmojis.length,
          itemBuilder: (_, i) => InkWell(
            onTap: () => _sendEmoji(_quickEmojis[i]),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(_quickEmojis[i], style: const TextStyle(fontSize: 24))),
            ),
          ),
        )),
      ]),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(color: _cardBg, border: Border(top: BorderSide(color: Color(0xFFF0F0F5)))),
      child: SafeArea(
        child: Row(children: [
          IconButton(
            icon: Icon(_isEmojiPickerVisible ? Icons.keyboard_rounded : Icons.mood_rounded, color: _primary, size: 24),
            onPressed: () => setState(() => _isEmojiPickerVisible = !_isEmojiPickerVisible),
            splashRadius: 20,
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFEEF0F4)),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 15, color: _textPrimary, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Message group...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          ValueListenableBuilder<bool>(
            valueListenable: _hasText,
            builder: (context, hasText, _) {
              if (hasText) {
                return _buildIconButton(icon: Icons.arrow_upward_rounded, color: _primary, onTap: _isSending ? null : _sendTextMessage, loading: _isSending);
              }
              return _buildIconButton(icon: Icons.mic_rounded, color: _primary, bg: _primary.withOpacity(0.1), onTap: _openVoiceRecorder);
            },
          ),
        ]),
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required Color color, Color? bg, VoidCallback? onTap, bool loading = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: bg ?? color,
          borderRadius: BorderRadius.circular(13),
          boxShadow: bg == null ? [BoxShadow(color: color.withOpacity(0.28), blurRadius: 8, offset: const Offset(0, 2))] : null,
        ),
        child: Center(
          child: loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Icon(icon, color: bg == null ? Colors.white : color, size: 22),
        ),
      ),
    );
  }

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() { _isSending = true; _isEmojiPickerVisible = false; });
    _messageController.clear();
    try {
      await _chatService.sendTextMessage(_chatId, text);
    } catch (e) {
      if (mounted) _showSnackBar('Failed to send', isError: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _sendEmoji(String emoji) async {
    setState(() => _isEmojiPickerVisible = false);
    try {
      await _chatService.sendEmojiMessage(_chatId, emoji);
    } catch (e) {
      if (mounted) _showSnackBar('Failed to send', isError: true);
    }
  }



  Future<void> _openVoiceRecorder() async {
    if (kIsWeb) {
      _showSnackBar('Voice recording not supported on web yet');
      return;
    }
    // Mobile: use record package
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _showSnackBar('Microphone permission required', isError: true);
      return;
    }

    String? tempPath;
    try { tempPath = (await getTemporaryDirectory()).path; } catch (_) {
      try { tempPath = (await getApplicationDocumentsDirectory()).path; } catch (_) {}
    }
    if (tempPath == null || !mounted) return;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VoiceRecorderSheet(
        tempDirPath: tempPath!,
        onSend: (audioFile, duration) async {
          try {
            setState(() => _isSending = true);
            await _chatService.sendVoiceMessage(_chatId, audioFile, duration);
          } catch (e) {
            if (mounted) _showSnackBar('Failed to send voice message', isError: true);
          } finally {
            if (mounted) setState(() => _isSending = false);
          }
        },
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _sheetHandle(),
          _sheetTile(Icons.info_outline_rounded, 'Group Info', _primary, () { Navigator.pop(ctx); _showGroupInfo(); }),
          if (_isAdmin) _sheetTile(Icons.person_add_rounded, 'Add Members', const Color(0xFF34C759), () { Navigator.pop(ctx); _showAddMembers(); }),
          _sheetTile(Icons.exit_to_app_rounded, 'Leave Group', Colors.orange, () { Navigator.pop(ctx); _confirmLeave(); }),
          if (_isAdmin) _sheetTile(Icons.delete_outline_rounded, 'Delete Group', Colors.red, () { Navigator.pop(ctx); _confirmDelete(); }),
        ]),
      ),
    );
  }

  void _showGroupInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('chats').doc(_chatId).snapshots(),
          builder: (ctx, snapshot) {
            final data = snapshot.data?.data() as Map<String, dynamic>? ?? widget.chatData;
            final participants = List<String>.from(data['participants'] ?? []);
            final participantNames = List<String>.from(data['participantNames'] ?? []);
            final participantRoles = List<String>.from(data['participantRoles'] ?? []);
            final adminIds = List<String>.from(data['adminIds'] ?? []);
            final description = data['description'] as String? ?? '';
            final createdByName = data['createdByName'] as String? ?? '';

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              builder: (_, scrollCtrl) => ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_primary, Color(0xFF9C94FF)]),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.groups_rounded, color: Colors.white, size: 36),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(child: Text(_groupName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _textPrimary))),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Center(child: Text(description, style: const TextStyle(fontSize: 13, color: _textSecondary), textAlign: TextAlign.center)),
                  ],
                  const SizedBox(height: 4),
                  Center(child: Text('Created by $createdByName', style: const TextStyle(fontSize: 12, color: _textSecondary))),
                  const SizedBox(height: 20),
                  Text('${participants.length} Members', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _textSecondary, letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  ...List.generate(participants.length, (i) {
                    final uid = i < participants.length ? participants[i] : '';
                    final name = i < participantNames.length ? participantNames[i] : 'Unknown';
                    final role = i < participantRoles.length ? participantRoles[i] : '';
                    final isThisAdmin = adminIds.contains(uid);
                    final isCurrentUser = uid == _chatService.currentUserId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: _getAvatarColor(name), borderRadius: BorderRadius.circular(12)),
                            child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(isCurrentUser ? '$name (You)' : name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textPrimary)),
                                  if (isThisAdmin) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                      child: const Text('Admin', style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ]),
                                Text(role, style: const TextStyle(fontSize: 12, color: _textSecondary)),
                              ],
                            ),
                          ),
                          if (_isAdmin && !isCurrentUser && !isThisAdmin)
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline_rounded, color: Colors.red.shade400, size: 20),
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await _removeMember(uid, name);
                              },
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _removeMember(String uid, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Member', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Remove $name from the group?', style: const TextStyle(color: _textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _chatService.removeMemberFromGroup(_chatId, uid);
        if (mounted) _showSnackBar('$name removed from group');
      } catch (e) {
        if (mounted) _showSnackBar('Failed to remove member', isError: true);
      }
    }
  }

  void _showAddMembers() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _AddMembersScreen(chatId: _chatId, chatService: _chatService)));
  }

  Future<void> _confirmLeave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Leave Group', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to leave this group?', style: TextStyle(color: _textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Leave', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _chatService.leaveGroup(_chatId);
        if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
      } catch (e) {
        if (mounted) _showSnackBar('Failed to leave group', isError: true);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Group', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('This will permanently delete the group and all messages. This cannot be undone.', style: TextStyle(color: _textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _chatService.deleteGroupChat(_chatId);
        if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
      } catch (e) {
        if (mounted) _showSnackBar('Failed to delete group', isError: true);
      }
    }
  }

  void _showMessageOptions(Map<String, dynamic> message) {
    final isMine = message['senderId'] == _chatService.currentUserId;
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _sheetHandle(),
          _sheetTile(Icons.copy_rounded, 'Copy', _primary, () {
            Clipboard.setData(ClipboardData(text: message['text'] ?? ''));
            Navigator.pop(ctx);
            _showSnackBar('Copied');
          }),
          if (isMine && _isAdmin) _sheetTile(Icons.delete_outline_rounded, 'Delete', Colors.red, () {
            Navigator.pop(ctx);
            _chatService.deleteMessage(_chatId, message['messageId'] as String);
          }),
        ]),
      ),
    );
  }

  Widget _buildErrorState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
    const SizedBox(height: 12),
    TextButton(onPressed: () => setState(() {}), child: const Text('Retry')),
  ]));

  Widget _buildEmptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 90, height: 90, decoration: BoxDecoration(color: _primary.withOpacity(0.08), borderRadius: BorderRadius.circular(26)), child: const Icon(Icons.groups_rounded, size: 46, color: _primary)),
    const SizedBox(height: 20),
    const Text('No messages yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textPrimary)),
    const SizedBox(height: 8),
    const Text('Start the conversation! 👋', style: TextStyle(fontSize: 14, color: _textSecondary)),
  ]));

  Widget _sheetHandle() => Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16, top: 4), alignment: Alignment.center, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)));

  Widget _sheetTile(IconData icon, String label, Color color, VoidCallback onTap) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
    title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color == Colors.red ? Colors.red : _textPrimary, fontSize: 15)),
    onTap: onTap,
  );

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? Colors.red : _primary,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }
}

// ── ADD MEMBERS SCREEN ──────────────────────────────────────
class _AddMembersScreen extends StatefulWidget {
  final String chatId;
  final ChatService chatService;
  const _AddMembersScreen({required this.chatId, required this.chatService});

  @override
  State<_AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends State<_AddMembersScreen> {
  final List<String> _selectedIds = [];
  final Map<String, String> _selectedNames = {};
  bool _isAdding = false;

  static const _primary = Color(0xFF6C63FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Add Members', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          if (_selectedIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: _isAdding ? null : _addMembers,
                style: TextButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                child: _isAdding
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Add (${_selectedIds.length})', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: widget.chatService.getAvailableUsers(),
        builder: (ctx, snapshot) {
          final users = snapshot.data ?? [];
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (ctx, i) {
              final user = users[i];
              final uid = user['uid'] as String;
              final name = user['name'] as String? ?? '';
              final role = user['role'] as String? ?? '';
              final isSelected = _selectedIds.contains(uid);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) { _selectedIds.remove(uid); _selectedNames.remove(uid); }
                    else { _selectedIds.add(uid); _selectedNames[uid] = name; }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? _primary.withOpacity(0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSelected ? _primary.withOpacity(0.4) : Colors.transparent, width: 1.5),
                  ),
                  child: Row(children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(color: isSelected ? _primary : const Color(0xFFEEEDF8), borderRadius: BorderRadius.circular(13)),
                      child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: isSelected ? Colors.white : _primary))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(role, style: const TextStyle(fontSize: 12, color: Color(0xFF8B8FA8))),
                    ])),
                    if (isSelected) const Icon(Icons.check_circle_rounded, color: _primary, size: 22),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addMembers() async {
    setState(() => _isAdding = true);
    try {
      await widget.chatService.addMembersToGroup(widget.chatId, _selectedIds);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Members added!'), backgroundColor: _primary, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  VOICE MESSAGE PLAYER — Fixed version with just_audio
// ═══════════════════════════════════════════════════════════════════
class _VoiceMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final String duration;
  final bool isSender;

  const _VoiceMessagePlayer({required this.audioUrl, required this.duration, required this.isSender});

  @override
  State<_VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<_VoiceMessagePlayer> {
  late AudioPlayer _player;
  bool _isLoading = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  StreamSubscription? _posSub;
  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _posSub = _player.positionStream.listen((pos) { if (mounted) setState(() => _position = pos); });
    _stateSub = _player.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
      if (state.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        if (mounted) setState(() { _isPlaying = false; _position = Duration.zero; });
      }
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isLoading) return;
    if (_player.processingState == ProcessingState.idle) {
      setState(() => _isLoading = true);
      try {
        await _player.setUrl(widget.audioUrl);
        if (mounted) setState(() { _total = _player.duration ?? Duration.zero; _isLoading = false; });
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
    }
    _isPlaying ? await _player.pause() : await _player.play();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  int _parseDuration(String s) {
    final parts = s.split(':');
    if (parts.length == 2) return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.isSender ? Colors.white : const Color(0xFF6C63FF);
    final fgMuted = widget.isSender ? Colors.white.withOpacity(0.6) : Colors.grey[400]!;
    final sliderActive = widget.isSender ? Colors.white : const Color(0xFF6C63FF);
    final sliderInactive = widget.isSender ? Colors.white.withOpacity(0.35) : const Color(0xFFE0E0E0);

    final totalSecs = _total.inSeconds > 0 ? _total.inSeconds.toDouble() : _parseDuration(widget.duration).toDouble().clamp(1.0, double.infinity);
    final posSecs = _position.inSeconds.clamp(0, totalSecs.toInt()).toDouble();

    return SizedBox(
      width: 220,
      child: Row(children: [
        GestureDetector(
          onTap: _togglePlay,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: widget.isSender ? Colors.white.withOpacity(0.2) : const Color(0xFF6C63FF).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(child: _isLoading
                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
                : Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: fg, size: 24)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: sliderActive,
              inactiveTrackColor: sliderInactive,
              thumbColor: sliderActive,
              overlayColor: sliderActive.withOpacity(0.15),
            ),
            child: Slider(value: posSecs, min: 0, max: totalSecs, onChanged: (v) async => await _player.seek(Duration(seconds: v.toInt()))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(_fmt(_position), style: TextStyle(fontSize: 10, color: fgMuted, fontWeight: FontWeight.w600)),
              Text(widget.duration, style: TextStyle(fontSize: 10, color: fgMuted, fontWeight: FontWeight.w600)),
            ]),
          ),
        ])),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  VOICE RECORDER SHEET — Fixed version
// ═══════════════════════════════════════════════════════════════════
class _VoiceRecorderSheet extends StatefulWidget {
  final String tempDirPath;
  final Future<void> Function(File audioFile, String duration) onSend;
  const _VoiceRecorderSheet({required this.tempDirPath, required this.onSend});

  @override
  State<_VoiceRecorderSheet> createState() => _VoiceRecorderSheetState();
}

class _VoiceRecorderSheetState extends State<_VoiceRecorderSheet> with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  String? _audioPath;
  bool _isRecording = false;
  bool _hasRecorded = false;
  int _seconds = 0;
  Timer? _timer;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  static const _primary = Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRecording());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      _audioPath = '${widget.tempDirPath}/vm_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 44100, bitRate: 128000),
        path: _audioPath!,
      );
      if (mounted) setState(() { _isRecording = true; _hasRecorded = false; _seconds = 0; });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() => _seconds++); });
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mic error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    _timer?.cancel();
    _pulseCtrl.stop();
    try {
      await _recorder.stop();
      if (mounted) setState(() { _isRecording = false; _hasRecorded = true; });
    } catch (_) { if (mounted) Navigator.pop(context); }
  }

  Future<void> _send() async {
    if (_audioPath == null) { if (mounted) Navigator.pop(context); return; }
    final file = File(_audioPath!);
    if (!await file.exists()) { if (mounted) Navigator.pop(context); return; }
    if (mounted) { Navigator.pop(context); widget.onSend(file, _fmt(_seconds)); }
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    try {
      if (_isRecording) await _recorder.stop();
      if (_audioPath != null) { final f = File(_audioPath!); if (await f.exists()) await f.delete(); }
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  Future<void> _reRecord() async {
    _timer?.cancel();
    try {
      if (_isRecording) await _recorder.stop();
      if (_audioPath != null) { final f = File(_audioPath!); if (await f.exists()) await f.delete(); }
    } catch (_) {}
    setState(() { _isRecording = false; _hasRecorded = false; _seconds = 0; });
    _pulseCtrl.repeat(reverse: true);
    await _startRecording();
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final micColor = _hasRecorded ? const Color(0xFF34C759) : _isRecording ? Colors.red : _primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.14), blurRadius: 28, offset: const Offset(0, -6))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Transform.scale(
            scale: _isRecording ? _pulseAnim.value : 1.0,
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(color: micColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: micColor.withOpacity(0.35), blurRadius: 24, spreadRadius: 4)]),
              child: Icon(_hasRecorded ? Icons.check_rounded : Icons.mic_rounded, color: Colors.white, size: 44),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          _hasRecorded ? 'Ready to send' : _isRecording ? 'Recording...' : 'Starting...',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _hasRecorded ? const Color(0xFF34C759) : _isRecording ? Colors.red : Colors.grey[500]),
        ),
        const SizedBox(height: 6),
        Text(_fmt(_seconds), style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -2, color: micColor)),
        const SizedBox(height: 18),
        if (_isRecording) ...[_buildWaveform(), const SizedBox(height: 28)] else const SizedBox(height: 28),
        if (_isRecording)
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _btn(icon: Icons.close_rounded, bg: Colors.grey[100]!, fg: Colors.grey[700]!, onTap: _cancel),
            _btn(icon: Icons.stop_rounded, bg: Colors.red, fg: Colors.white, size: 68, onTap: _stopRecording),
            const SizedBox(width: 60),
          ])
        else if (_hasRecorded)
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _btn(icon: Icons.close_rounded, bg: Colors.grey[100]!, fg: Colors.grey[700]!, onTap: _cancel),
            _btn(icon: Icons.refresh_rounded, bg: _primary.withOpacity(0.1), fg: _primary, onTap: _reRecord),
            _btn(icon: Icons.send_rounded, bg: const Color(0xFF34C759), fg: Colors.white, size: 68, onTap: _send),
          ]),
        const SizedBox(height: 10),
        Text(_isRecording ? 'Tap ■ to stop' : _hasRecorded ? 'Tap ► to send' : '', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
      ]),
    );
  }

  Widget _buildWaveform() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(26, (i) {
          final seed = (i % 7 + 1) * 4.0;
          final h = (seed + _pulseCtrl.value * seed * 0.7).clamp(4.0, 36.0);
          return AnimatedContainer(
            duration: Duration(milliseconds: 80 + i * 15),
            width: 3, height: h,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.4 + (i % 4) * 0.12), borderRadius: BorderRadius.circular(2)),
          );
        }),
      ),
    );
  }

  Widget _btn({required IconData icon, required Color bg, required Color fg, required VoidCallback onTap, double size = 56}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * 0.28), boxShadow: [BoxShadow(color: bg.withOpacity(0.28), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Center(child: Icon(icon, color: fg, size: size * 0.44)),
      ),
    );
  }
}