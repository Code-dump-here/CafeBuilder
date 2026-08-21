import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_colors.dart';
import '../services/chat_service.dart';
import '../services/api_client.dart';

class ChatThreadPage extends StatefulWidget {
  final String conversationId;
  final String title;

  /// Optional line under the title — the other party's role, so the thread
  /// always says who is on the far end of it.
  final String? subtitle;

  const ChatThreadPage({
    super.key,
    required this.conversationId,
    required this.title,
    this.subtitle,
  });

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessageResponse> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  String? _currentAccountId;

  final List<PlatformFile> _selectedFiles = [];
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _currentAccountId = await ApiClient.getAccountId();
    await _loadMessages();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollMessages();
    });
  }

  Future<void> _pollMessages() async {
    if (!mounted) return;
    try {
      final response = await ChatService.getMessages(widget.conversationId);
      if (mounted) {
        setState(() {
          final oldLen = _messages.length;
          _messages = response.items;
          _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          // If new messages arrived, scroll to bottom
          if (_messages.length > oldLen) {
            _scrollToBottom();
          }
        });
      }
    } catch (_) {
      // Quietly ignore polling errors so it doesn't disrupt the user
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ChatService.getMessages(widget.conversationId);
      if (mounted) {
        setState(() {
          _messages = response.items;
          // Sort messages to have oldest first (assuming standard chat flow)
          _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load messages. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickFiles() async {
    try {
      // withData: true forces bytes to be populated even on platforms
      // where file_picker would otherwise only give a path. On Web, .paths
      // throws (browsers don't expose real filesystem paths) — .bytes is
      // the only thing that ever works there, so this is required, not
      // just a nice-to-have.
      FilePickerResult? result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: true,
      );
      if (result != null) {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error picking file')));
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedFiles.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final uploadFiles = _selectedFiles
          .map(
            (f) => UploadFile(filename: f.name, bytes: f.bytes, path: f.path),
          )
          .toList();
      final newMessage = await ChatService.postMessage(
        widget.conversationId,
        text,
        files: uploadFiles.isNotEmpty ? uploadFiles : null,
      );

      if (mounted) {
        setState(() {
          _messages.add(newMessage);
          _textController.clear();
          _selectedFiles.clear();
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.espresso),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),
            if ((widget.subtitle ?? '').isNotEmpty)
              Text(
                widget.subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessagesArea()),
          if (widget.conversationId.isNotEmpty && _selectedFiles.isNotEmpty)
            _buildAttachmentPreview(),
          if (widget.conversationId.isNotEmpty) _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessagesArea() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.espresso),
      );
    }
    if (_error != null || _messages.isEmpty) {
      final isNoCollab = widget.conversationId.isEmpty;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F3F1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isNoCollab ? Icons.forum_outlined : Icons.error_outline,
                  size: 64,
                  color: AppColors.espresso,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isNoCollab
                    ? 'No Active Collab Yet'
                    : (_error != null
                          ? 'Oops, something went wrong'
                          : 'No messages yet'),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.espresso,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isNoCollab
                    ? 'It looks like there is no active contract or engagement for this project yet. Once accepted, your chat will appear here.'
                    : (_error != null
                          ? _error!
                          : 'Start the conversation by sending a message below!'),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (!isNoCollab && _error != null)
                ElevatedButton.icon(
                  onPressed: _loadMessages,
                  icon: const Icon(
                    Icons.refresh,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.espresso,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMine =
            _currentAccountId != null && message.senderId == _currentAccountId;
        return _buildMessageBubble(message, isMine);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessageResponse message, bool isMine) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFFD9EAA3),
              child: Icon(Icons.person, size: 16, color: Color(0xFF56642B)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMine ? AppColors.espresso : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMine ? 16 : 0),
                  bottomRight: Radius.circular(isMine ? 0 : 16),
                ),
                boxShadow: [
                  if (!isMine)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (message.body.isNotEmpty)
                    Text(
                      message.body,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isMine ? Colors.white : AppColors.espresso,
                      ),
                    ),
                  if (message.fileUrls.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: message.fileUrls.map((url) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isMine
                                ? Colors.white.withOpacity(0.2)
                                : const Color(0xFFF6F3F1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.insert_drive_file,
                                size: 14,
                                color: isMine
                                    ? Colors.white
                                    : AppColors.espresso,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Attachment',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isMine
                                      ? Colors.white
                                      : AppColors.espresso,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isMine)
            const SizedBox(width: 22), // space equivalent to avatar + spacing
        ],
      ),
    );
  }

  Widget _buildAttachmentPreview() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _selectedFiles.length,
          itemBuilder: (context, index) {
            final name = _selectedFiles[index].name;
            return Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F3F1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.attach_file,
                    size: 16,
                    color: AppColors.placeholder,
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.espresso,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.placeholder,
                    ),
                    onPressed: () => _removeFile(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppColors.placeholder,
            ),
            onPressed: _pickFiles,
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: GoogleFonts.inter(color: AppColors.placeholder),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF6F3F1),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          _isSending
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.espresso,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.send, color: AppColors.espresso),
                  onPressed: _sendMessage,
                ),
        ],
      ),
    );
  }
}
