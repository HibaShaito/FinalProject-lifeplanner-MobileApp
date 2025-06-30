import 'package:flutter/material.dart';
import 'package:lifeplanner/services/groq_service.dart';
import 'package:lifeplanner/services/chat_service.dart';
import 'package:lifeplanner/widgets/base_scaffold.dart';
import 'package:lifeplanner/widgets/voice_wave_animaion.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lifeplanner/services/open_router_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  int? _speakingMessageIndex;
  late final SpeechToText _stt;
  bool _speechAvailable = false;
  bool _listening = false;
  final _controller = TextEditingController();
  bool _isLoading = false;
  final FlutterTts _tts = FlutterTts();

  static const int _loadLimit = 50;

  @override
  void initState() {
    super.initState();
    _stt = SpeechToText();
    _initSpeech();
    _tts.setCompletionHandler(
      () => setState(() => _speakingMessageIndex = null),
    );
    _tts.setCancelHandler(() => setState(() => _speakingMessageIndex = null));
    _tts.setPauseHandler(() => setState(() => _speakingMessageIndex = null));
  }

  // ── FIRESTORE PERSISTENCE ──────────────────────────────────────────

  Future<void> _addUserMessage(String text) async {
    await context.read<ChatService>().addMessage(text, true);
  }

  Future<void> _addBotMessage(String text) async {
    await context.read<ChatService>().addMessage(text, false);
  }

  // ── SENDING / LLM LOGIC ────────────────────────────────────────────

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final openRouter = context.read<OpenRouterService>();
    final groq = context.read<GroqService>();

    // 1️⃣ persist & show user
    await _addUserMessage(text);
    setState(() => _isLoading = true);
    _controller.clear();

    try {
      // 2️⃣ ask Groq first, fallback to OpenRouter
      final reply = await groq
          .sendMessage(text)
          .catchError((_) => openRouter.sendMessage(text));

      // 3️⃣ persist & show bot reply
      await _addBotMessage(reply);
    } catch (_) {
      // 4️⃣ final fallback
      final fallback = await openRouter.sendMessage(text);
      await _addBotMessage(fallback);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── SPEECH / TTS ───────────────────────────────────────────────────

  Future<void> _listen() async {
    if (!_speechAvailable) {
      await _addBotMessage("Speech recognition not available.");
      return;
    }

    if (!_listening) {
      setState(() => _listening = true);
      try {
        await _stt.listen(
          onResult: (result) {
            _controller.text = result.recognizedWords;
            _controller.selection = TextSelection.collapsed(
              offset: _controller.text.length,
            );
            if (result.finalResult) {
              _stt.stop();
              setState(() => _listening = false);
              final spoken = result.recognizedWords.trim();
              if (spoken.isNotEmpty) _sendMessage(spoken);
            }
          },
          localeId: 'en_US',
          listenOptions: SpeechListenOptions(partialResults: true),
        );
      } catch (e) {
        setState(() => _listening = false);
        await _addBotMessage("Voice input error: $e");
      }
    } else {
      setState(() => _listening = false);
      await _stt.stop();
      final spoken = _controller.text.trim();
      if (spoken.isNotEmpty) _sendMessage(spoken);
    }
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _stt.initialize(
      onStatus: (status) {
        if (status == 'notListening' && mounted) {
          setState(() => _listening = false);
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _listening = false);
          _addBotMessage("Speech error: ${error.errorMsg}");
        }
      },
    );
    if (mounted) setState(() {});
  }

  // ── PERMISSIONS ───────────────────────────────────────────────────

  Future<void> _checkAndStartListening() async {
    if (!_speechAvailable) {
      await _addBotMessage(
        "Speech recognition not available.Please enable it in device permissions.",
      );
      return;
    }
    var status = await Permission.microphone.status;
    if (status.isDenied || status.isRestricted) {
      status = await Permission.microphone.request();
    }
    if (!mounted) return;
    if (status.isGranted) {
      _listen();
    } else if (status.isPermanentlyDenied) {
      _showPermissionDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission denied')),
      );
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Permission required'),
            content: const Text(
              'Microphone permission is permanently denied. Please enable it from app settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
    );
  }

  // ── MESSAGE TILE WITH TIMESTAMP ────────────────────────────────────

  Widget _buildMessageTile(
    BuildContext ctx, {
    required String text,
    required bool isUser,
    required String messageId,
    required Timestamp? timestamp,
  }) {
    // format to e.g. “10:45 PM”
    final timeLabel =
        timestamp != null ? DateFormat.jm().format(timestamp.toDate()) : '';

    return GestureDetector(
      onLongPress: () {
        showModalBottomSheet(
          context: ctx,
          builder:
              (_) => SafeArea(
                child: Wrap(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.copy),
                      title: const Text('Copy'),
                      onTap: () {
                        Navigator.pop(ctx);
                        Clipboard.setData(ClipboardData(text: text));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete),
                      title: const Text('Delete'),
                      onTap: () {
                        Navigator.pop(ctx);
                        ctx.read<ChatService>().deleteMessage(messageId);
                      },
                    ),
                  ],
                ),
              ),
        );
      },
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUser ? Colors.blue.shade100 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text),
              const SizedBox(height: 6),
              Text(
                timeLabel,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              if (!isUser)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(
                      _speakingMessageIndex == messageId.hashCode
                          ? Icons.stop
                          : Icons.volume_up,
                      size: 20,
                    ),
                    onPressed: () {
                      if (_speakingMessageIndex == messageId.hashCode) {
                        _tts.stop();
                      } else {
                        setState(
                          () => _speakingMessageIndex = messageId.hashCode,
                        );
                        _tts.speak(text);
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Chatbot Help'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SizedBox(height: 8),
                  Text("• Use voice or type messages."),
                  SizedBox(height: 8),
                  Text(
                    "• If voice doesn't work, check microphone permissions.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "• Long‑press a message to copy or delete it.",
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it!'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.read<ChatService>();

    return BaseScaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD27F),
        title: Row(
          children: const [
            CircleAvatar(
              backgroundImage: AssetImage('assets/img/bot_avatar.png'),
              radius: 16,
            ),
            SizedBox(width: 8),
            Text('Bot'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'clear') chat.clearHistory();
            },
            itemBuilder:
                (_) => [
                  const PopupMenuItem(
                    value: 'clear',
                    child: Text('Clear history'),
                  ),
                ],
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<
              List<QueryDocumentSnapshot<Map<String, dynamic>>>
            >(
              stream: chat.streamRecent(_loadLimit),
              builder: (ctx, snap) {
                final docs = snap.data ?? [];
                // we reversed _loadLimit descending, now old→new top→bottom
                final messages = docs.reversed.toList();
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final doc = messages[i];
                    final data = doc.data();
                    return _buildMessageTile(
                      ctx,
                      text: data['text'] as String,
                      isUser: data['isUser'] as bool,
                      messageId: doc.id,
                      timestamp: data['timestamp'] as Timestamp?,
                    );
                  },
                );
              },
            ),
          ),

          if (_isLoading) const LinearProgressIndicator(),

          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _listening ? Icons.mic : Icons.mic_none,
                    color: _listening ? Colors.red : null,
                  ),
                  onPressed: _checkAndStartListening,
                ),
                if (_listening) ...[
                  const SizedBox(width: 4),
                  const Text('Listening…', style: TextStyle(color: Colors.red)),
                  const SizedBox(width: 8),
                  const VoiceWaveAnimation(),
                ],
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: _sendMessage,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed:
                      _listening ? null : () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
