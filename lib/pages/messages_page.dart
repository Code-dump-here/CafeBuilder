import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/responses/api_responses.dart';
import '../services/project_working_service.dart';
import '../services/chat_service.dart';
import 'chat_thread_page.dart';

/// Picks who to talk to before opening a thread.
///
/// Chat used to be a single button that resolved the design engagement — or,
/// when there wasn't one, whichever engagement the API happened to return
/// first. On a project with both a designer and a constructor that meant one of
/// them was unreachable, and the thread could open against someone who had
/// already been rejected. Every conversation now starts from an explicit
/// choice on this screen.
class MessagesPage extends StatefulWidget {
  final String projectId;
  final String? projectName;

  const MessagesPage({super.key, required this.projectId, this.projectName});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<ProjectWorkingResponse> _contacts = [];
  bool _isLoading = true;
  String? _error;

  /// Engagement whose conversation is being resolved, so the tapped row can
  /// show a spinner and a second tap can't open two threads.
  String? _openingId;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final workings = await ProjectWorkingService.getProjectWorkings(
        projectShopOwnerId: widget.projectId,
        pageSize: 50,
      );

      // 'rejected' and 'terminated' engagements are over — opening a thread
      // against one would message somebody no longer on the project.
      const talkable = {'requested', 'accepted', 'completed'};
      final contacts = workings.items
          .where((w) => talkable.contains(w.status.toLowerCase()))
          .toList();
      contacts.sort((a, b) {
        final byStatus = _statusRank(a.status).compareTo(_statusRank(b.status));
        if (byStatus != 0) return byStatus;
        return b.updatedAt.compareTo(a.updatedAt);
      });

      if (mounted) {
        setState(() {
          _contacts = contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Active collaborators first, then people still deciding, then finished work.
  int _statusRank(String status) => switch (status.toLowerCase()) {
    'accepted' => 0,
    'requested' => 1,
    _ => 2,
  };

  String _roleLabel(String contractType) => switch (contractType.toLowerCase()) {
    'design' => 'Designer',
    'construction' => 'Constructor',
    'both' => 'Design & Build',
    final other => other.isEmpty ? 'Provider' : other,
  };

  String _statusLabel(String status) => switch (status.toLowerCase()) {
    'accepted' => 'Working together',
    'requested' => 'Invitation pending',
    'completed' => 'Work completed',
    final other => other,
  };

  Color _statusColor(String status) => switch (status.toLowerCase()) {
    'accepted' => const Color(0xFF2E7D32),
    'requested' => const Color(0xFFB26A00),
    _ => AppColors.textSecondary,
  };

  String _initial(String name) =>
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  Future<void> _openThread(ProjectWorkingResponse working) async {
    if (_openingId != null) return;
    setState(() => _openingId = working.id);

    try {
      // The engagement id is not a conversation id — resolve (or create) the
      // real thread for this specific person before opening it.
      final conversationId = await ChatService.getOrCreateConversation(
        working.id,
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatThreadPage(
            conversationId: conversationId,
            title: working.providerDisplayName.isNotEmpty
                ? working.providerDisplayName
                : 'Chat',
            subtitle: _roleLabel(working.contractType),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open this conversation: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _openingId = null);
    }
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
              'Messages',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),
            if ((widget.projectName ?? '').isNotEmpty)
              Text(
                widget.projectName!,
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.espresso),
      );
    }
    if (_error != null) {
      return _buildMessage(
        icon: Icons.error_outline,
        title: 'Oops, something went wrong',
        body: _error!,
        action: ElevatedButton.icon(
          onPressed: _loadContacts,
          icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
          label: const Text('Try Again'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.espresso,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
    if (_contacts.isEmpty) {
      return _buildMessage(
        icon: Icons.forum_outlined,
        title: 'No one to message yet',
        body:
            'Once you invite a designer or a constructor to this project — or '
            'accept an application — they will show up here and you can start '
            'the conversation.',
      );
    }

    return RefreshIndicator(
      color: AppColors.espresso,
      onRefresh: _loadContacts,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        itemCount: _contacts.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Who would you like to talk to?',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }
          return _buildContactRow(_contacts[index - 1]);
        },
      ),
    );
  }

  Widget _buildContactRow(ProjectWorkingResponse working) {
    final isOpening = _openingId == working.id;
    final name = working.providerDisplayName.isNotEmpty
        ? working.providerDisplayName
        : 'Provider #${working.serviceProviderProfileId}';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isOpening ? null : () => _openThread(working),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEDE7E3)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFF1EAE4),
                child: Text(
                  _initial(name),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.espresso,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.espresso,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F3F1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _roleLabel(working.contractType),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.espresso,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _statusLabel(working.status),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: _statusColor(working.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isOpening)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.espresso,
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.placeholder,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String body,
    Widget? action,
  }) {
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
              child: Icon(icon, size: 64, color: AppColors.espresso),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 32), action],
          ],
        ),
      ),
    );
  }
}
