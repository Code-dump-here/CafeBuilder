import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/responses/api_responses.dart';
import '../services/api_client.dart';
import '../services/project_service.dart';
import '../services/service_provider_service.dart';
import 'booking_confirmed_page.dart';
import 'hire_request_confirmed_page.dart';
import 'project_onboarding_page.dart';

class SelectProjectPage extends StatefulWidget {
  final String designerName;
  final bool isConstructor;

  const SelectProjectPage({
    super.key,
    required this.designerName,
    this.isConstructor = false,
  });

  @override
  State<SelectProjectPage> createState() => _SelectProjectPageState();
}

class _SelectProjectPageState extends State<SelectProjectPage> {
  List<ProjectResponse> _projects = [];
  int _selectedIndex = 0;
  bool _loading = true;
  String? _error;

  static const _coverImages = [
    'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=600',
    'https://images.unsplash.com/photo-1498804103079-a6351b050096?auto=format&fit=crop&q=80&w=600',
    'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&q=80&w=600',
    'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?auto=format&fit=crop&q=80&w=600',
  ];

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final shopOwnerId = await ShopOwnerService.ensureShopOwnerId();
      final result = await ProjectService.getProjects(
        ownerId: shopOwnerId,
        pageSize: 50,
      );
      if (mounted) {
        setState(() {
          _projects = result.items;
          _selectedIndex = 0;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load projects';
        });
      }
    }
  }

  String _coverFor(ProjectResponse project) =>
      _coverImages[project.id.abs() % _coverImages.length];

  String _formatDate(DateTime date) =>
      '${_months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';

  String _statusLabel(String status) {
    if (status.isEmpty) return 'Draft';
    switch (status.toLowerCase()) {
      case 'draft':
        return 'Draft Complete';
      case 'inprogress':
      case 'in_progress':
      case 'active':
        return 'Synthesis Ready';
      case 'completed':
        return 'Completed';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  bool _isHighlightedStatus(String status) {
    switch (status.toLowerCase()) {
      case 'inprogress':
      case 'in_progress':
      case 'active':
      case 'completed':
        return true;
      default:
        return false;
    }
  }

  ProjectResponse? get _selectedProject =>
      _projects.isNotEmpty ? _projects[_selectedIndex] : null;

  @override
  Widget build(BuildContext context) {
    final providerLabel = widget.isConstructor ? 'contractors' : 'designers';

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.espresso),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SELECT PROJECT',
          style: GoogleFonts.playfairDisplay(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose a project brief to share with ${widget.designerName}. Our $providerLabel will review your selection and respond within 24 hours.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.espresso),
                      ),
                    )
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadProjects,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    if (_projects.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'You don\'t have any projects yet. Create one to share with ${widget.designerName}.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      )
                    else
                      for (var i = 0; i < _projects.length; i++)
                        _buildProjectCard(i, _projects[i]),
                    _buildCreateNewCard(),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF8F6),
              border: Border(
                top: BorderSide(color: AppColors.outlineVariant.withOpacity(0.5)),
              ),
            ),
            child: ElevatedButton(
              onPressed: _projects.isEmpty || _loading
                  ? null
                  : () {
                      final project = _selectedProject!;
                      if (widget.isConstructor) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HireRequestConfirmedPage(
                              constructorName: widget.designerName,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingConfirmedPage(
                              projectTitle: project.name,
                            ),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.espresso,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(
                'CONFIRM & SEND >',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(int index, ProjectResponse project) {
    final isSelected = _selectedIndex == index;
    final statusLabel = _statusLabel(project.status);
    final highlighted = _isHighlightedStatus(project.status);

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.espresso : AppColors.outlineVariant.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.espresso.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                  child: Image.network(
                    _coverFor(project),
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.espresso : Colors.white,
                      border: Border.all(
                        color: isSelected ? AppColors.espresso : AppColors.outlineVariant,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.espresso,
                    ),
                  ),
                  if (project.address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      project.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.placeholder),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: highlighted
                              ? const Color(0xFFD9EAA3).withOpacity(0.5)
                              : const Color(0xFFEBEBEB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusLabel,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: highlighted
                                ? const Color(0xFF56642B)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.placeholder),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(project.updatedAt),
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateNewCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProjectOnboardingPage()),
        ).then((_) => _loadProjects());
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant, width: 2),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.espresso,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Create New Project',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a new brief for a different\nlocation or concept.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
