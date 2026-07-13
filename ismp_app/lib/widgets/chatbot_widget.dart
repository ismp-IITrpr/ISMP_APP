import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/chatbot_service.dart';
import '../theme/app_theme.dart';

/// A floating, draggable AI chatbot button that opens a chat overlay.
class ChatbotWidget extends StatefulWidget {
  final Widget child;
  const ChatbotWidget({super.key, required this.child});

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget>
    with SingleTickerProviderStateMixin {
  // ── FAB position ──────────────────────────────────────────────────
  double _fabX = double.infinity; // will be set in didChangeDependencies
  double _fabY = double.infinity;
  bool _positionInitialized = false;

  // ── Chat state ────────────────────────────────────────────────────
  bool _isChatOpen = false;
  bool _isSending = false;
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  String _sessionId = '';

  // Animation
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_positionInitialized) {
      final size = MediaQuery.of(context).size;
      _fabX = size.width - 72;
      _fabY = size.height - 160;
      _positionInitialized = true;
    }
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Send message ──────────────────────────────────────────────────
  Future<void> _send() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isSending = true;
    });
    _msgController.clear();
    _scrollToBottom();

    final reply = await ChatbotService.sendMessage(
      message: text,
      sessionId: _sessionId,
    );

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(text: reply, isUser: false));
      _isSending = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Clamp FAB inside screen ───────────────────────────────────────
  void _clampFab(Size screenSize) {
    _fabX = _fabX.clamp(0, screenSize.width - 56);
    _fabY = _fabY.clamp(0, screenSize.height - 56);
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    _clampFab(screenSize);

    return Stack(
      children: [
        widget.child,

        // ── Chat overlay ────────────────────────────────────────────
        if (_isChatOpen) _buildChatOverlay(screenSize),

        // ── Draggable FAB ───────────────────────────────────────────
        Positioned(
          left: _fabX,
          top: _fabY,
          child: GestureDetector(
            onPanUpdate: (d) {
              setState(() {
                _fabX += d.delta.dx;
                _fabY += d.delta.dy;
                _clampFab(screenSize);
              });
            },
            onTap: () => setState(() => _isChatOpen = !_isChatOpen),
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFC107),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFC107).withValues(
                          alpha: 0.3 + _pulseController.value * 0.25,
                        ),
                        blurRadius: 16 + _pulseController.value * 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isChatOpen ? Icons.close : Icons.smart_toy_rounded,
                    color: const Color(0xFFF0F0F0),
                    size: 28,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── Chat overlay ──────────────────────────────────────────────────
  Widget _buildChatOverlay(Size screenSize) {
    final chatWidth = min(screenSize.width - 32, 380.0);
    final chatHeight = min(screenSize.height * 0.65, 520.0);

    return Positioned(
      right: 16,
      bottom: 90,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: chatWidth,
          height: chatHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1025),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                _buildChatHeader(),
                Expanded(child: _buildMessageList()),
                _buildInputBar(),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1),
    );
  }

  // ── Header ────────────────────────────────────────────────────────
  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2D1B4E),
            AppColors.primary.withValues(alpha: 0.2),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [const Color(0xFF7C3AED), AppColors.primary],
              ),
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RAGnarok AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Iota Cluster • IIT Ropar',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Clear chat
          IconButton(
            icon: Icon(Icons.delete_sweep_rounded,
                color: Colors.white.withValues(alpha: 0.5), size: 20),
            onPressed: () => setState(() {
              _messages.clear();
              _sessionId =
                  'session_${DateTime.now().millisecondsSinceEpoch}';
            }),
            tooltip: 'Clear chat',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          // Close
          IconButton(
            icon: Icon(Icons.close_rounded,
                color: Colors.white.withValues(alpha: 0.5), size: 20),
            onPressed: () => setState(() => _isChatOpen = false),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ── Message list ──────────────────────────────────────────────────
  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.smart_toy_rounded,
                  size: 48,
                  color: AppColors.primary.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(
                'Ask me anything about\nIIT Ropar & ISMP!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isSending) {
          return _buildTypingIndicator();
        }
        final msg = _messages[index];
        return _buildBubble(msg);
      },
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.white.withValues(alpha: 0.9),
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(
          begin: isUser ? 0.1 : -0.1,
          curve: Curves.easeOut,
        );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: const Text('●',
                  style: TextStyle(color: AppColors.primary, fontSize: 10)),
            )
                .animate(
                  onPlay: (c) => c.repeat(),
                )
                .fadeIn(duration: 400.ms, delay: (i * 200).ms)
                .then()
                .fadeOut(duration: 400.ms);
          }),
        ),
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: Border(
          top:
              BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ask something...',
                hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 14),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [const Color(0xFF7C3AED), AppColors.primary],
                ),
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}
