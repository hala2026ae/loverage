import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../../app/theme/app_theme.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentMenuIndex = 0; // 0 = Verifications, 1 = Reports, 2 = Audit Logs
  bool _isLoading = false;
  
  List<VerificationTask> _verifications = [];
  List<ReportTask> _reports = [];
  List<String> _auditLogs = [];

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('verification_submissions')
          .select('id, user_id, video_storage_path, status, created_at, profiles(public_name, age, profile_photos(public_url, is_primary))')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final List<VerificationTask> tasks = [];
      for (final row in (response as List)) {
        final id = row['id']?.toString() ?? '';
        final userId = row['user_id']?.toString() ?? '';
        final videoUrl = row['video_storage_path']?.toString() ?? '';
        final profilesMap = row['profiles'] as Map<String, dynamic>?;
        
        final userName = profilesMap?['public_name']?.toString() ?? 'Unknown';
        final userAge = int.tryParse(profilesMap?['age']?.toString() ?? '') ?? 0;
        
        String mainPhotoUrl = '';
        final photosList = profilesMap?['profile_photos'] as List?;
        if (photosList != null && photosList.isNotEmpty) {
          final primaryPhoto = photosList.firstWhere(
            (p) => p['is_primary'] == true,
            orElse: () => photosList.first,
          );
          mainPhotoUrl = primaryPhoto['public_url']?.toString() ?? '';
        }
        
        if (mainPhotoUrl.isEmpty) {
          mainPhotoUrl = 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400';
        }
        
        String submittedAt = 'Just now';
        final createdAtStr = row['created_at']?.toString();
        if (createdAtStr != null) {
          final createdAt = DateTime.tryParse(createdAtStr);
          if (createdAt != null) {
            final diff = DateTime.now().difference(createdAt);
            if (diff.inMinutes < 60) {
              submittedAt = '${diff.inMinutes} mins ago';
            } else if (diff.inHours < 24) {
              submittedAt = '${diff.inHours} hours ago';
            } else {
              submittedAt = '${diff.inDays} days ago';
            }
          }
        }
        
        tasks.add(
          VerificationTask(
            id: id,
            userId: userId,
            userName: userName,
            userAge: userAge,
            submittedAt: submittedAt,
            videoUrl: videoUrl,
            mainPhotoUrl: mainPhotoUrl,
          ),
        );
      }

      setState(() {
        _verifications = tasks;
        _reports = [
          ReportTask(
            id: 'r1',
            reporterName: 'Victoria',
            reportedName: 'John',
            reason: 'Scam or asking for money',
            description: 'User repeatedly sent messages asking for financial help to travel.',
            time: '3 hours ago',
          ),
        ];

        _auditLogs = [
          '[INFO] 10:15 AM - Admin approved profile ID: mock-user-991',
          '[WARNING] 09:30 AM - Admin suspended user ID: mock-user-404 due to harassment',
          '[INFO] 08:45 AM - Admin dismissed report on profile ID: mock-user-202',
        ];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading admin verifications: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveProfile(VerificationTask task) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Update submission status to approved
      await supabase
          .from('verification_submissions')
          .update({'status': 'approved'})
          .eq('id', task.id);

      // Update user profile status to active & verified
      await supabase
          .from('profiles')
          .update({
            'verification_status': 'approved',
            'profile_status': 'active',
          })
          .eq('id', task.userId);

      setState(() {
        _verifications.removeWhere((v) => v.id == task.id);
        _auditLogs.insert(0, '[INFO] ${DateTime.now().toString().substring(11, 16)} - Approved face verification for ${task.userName}');
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile ${task.userName} has been approved.'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve profile: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _rejectProfile(VerificationTask task, String reason) async {
    try {
      final supabase = Supabase.instance.client;

      // Update submission status to rejected
      await supabase
          .from('verification_submissions')
          .update({'status': 'rejected'})
          .eq('id', task.id);

      // Update user profile status to verification rejected
      await supabase
          .from('profiles')
          .update({
            'verification_status': 'rejected',
            'profile_status': 'verification_rejected',
          })
          .eq('id', task.userId);

      setState(() {
        _verifications.removeWhere((v) => v.id == task.id);
        _auditLogs.insert(0, '[REJECT] ${DateTime.now().toString().substring(11, 16)} - Rejected verification for ${task.userName}. Reason: $reason');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile ${task.userName} rejected: $reason'), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject profile: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _suspendUser(ReportTask report) {
    setState(() {
      _reports.removeWhere((r) => r.id == report.id);
      _auditLogs.insert(0, '[SUSPEND] ${DateTime.now().toString().substring(11, 16)} - Suspended reported user ${report.reportedName}');
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User ${report.reportedName} has been permanently suspended.'), backgroundColor: AppColors.error),
    );
  }

  void _dismissReport(ReportTask report) {
    setState(() {
      _reports.removeWhere((r) => r.id == report.id);
      _auditLogs.insert(0, '[DISMISS] ${DateTime.now().toString().substring(11, 16)} - Dismissed flag on ${report.reportedName}');
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report dismissed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: AppColors.primaryBurgundy,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: AppColors.accentRoseGold),
            SizedBox(width: 10.0),
            Text(
              'Loverage Admin Portal',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          // Sidebar menu
          Container(
            width: 220.0,
            color: AppColors.primaryDarkBurgundy,
            child: Column(
              children: [
                const SizedBox(height: 20.0),
                _buildSidebarItem(0, Icons.verified_user_outlined, 'Verifications'),
                _buildSidebarItem(1, Icons.report_gmailerrorred_rounded, 'Reports'),
                _buildSidebarItem(2, Icons.history_edu_rounded, 'Audit Logs'),
                const Spacer(),
                const Text('Role: Super Admin', style: TextStyle(color: Colors.white54, fontSize: 12.0)),
                const SizedBox(height: 20.0),
              ],
            ),
          ),
          
          // Main Content Board
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBurgundy))
                : Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: _buildMainContent(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = _currentMenuIndex == index;
    return ListTile(
      onTap: () => setState(() => _currentMenuIndex = index),
      leading: Icon(icon, color: isSelected ? AppColors.accentRoseGold : Colors.white60),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white60,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.white12,
    );
  }

  Widget _buildMainContent() {
    switch (_currentMenuIndex) {
      case 0:
        return _buildVerificationsQueue();
      case 1:
        return _buildReportsQueue();
      case 2:
        return _buildAuditLogsView();
      default:
        return const SizedBox();
    }
  }

  Widget _buildVerificationsQueue() {
    if (_verifications.isEmpty) {
      return const Center(child: Text('Verification queue is empty. Good job!', style: TextStyle(fontSize: 16.0, color: AppColors.textSecondary)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pending Face Verifications', style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: AppColors.primaryBurgundy)),
        const SizedBox(height: 16.0),
        Expanded(
          child: ListView.builder(
            itemCount: _verifications.length,
            itemBuilder: (context, index) {
              final task = _verifications[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.m),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Row(
                    children: [
                      // User photo
                      CircleAvatar(
                        radius: 40.0,
                        backgroundImage: NetworkImage(task.mainPhotoUrl),
                      ),
                      const SizedBox(width: 20.0),
                      
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${task.userName}, ${task.userAge}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
                            ),
                            const SizedBox(height: 6.0),
                            Text('Submitted: ${task.submittedAt}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.0)),
                            const SizedBox(height: 8.0),
                            TextButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => VideoPlayerDialog(videoUrl: task.videoUrl),
                                );
                              },
                              icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primaryBurgundy),
                              label: const Text('Play Video Submission', style: TextStyle(color: AppColors.primaryBurgundy, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      
                      // Action triggers
                      Column(
                        children: [
                          FilledButton(
                            onPressed: () => _approveProfile(task),
                            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                            child: const Text('Approve'),
                          ),
                          const SizedBox(height: 8.0),
                          OutlinedButton(
                            onPressed: () => _showRejectionReasons(task),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                            ),
                            child: const Text('Reject'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showRejectionReasons(VerificationTask task) {
    String? selectedReason;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundLight,
          title: Text('Reject ${task.userName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select a reason for rejecting the verification:'),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Reason'),
                items: [
                  'Blurry/low-quality video',
                  'Face doesn\'t match photos',
                  'Incomplete profile details',
                  'Suspicious behavior/impersonation'
                ].map((reason) {
                  return DropdownMenuItem(value: reason, child: Text(reason));
                }).toList(),
                onChanged: (val) => selectedReason = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                if (selectedReason != null) {
                  Navigator.pop(context);
                  _rejectProfile(task, selectedReason!);
                }
              },
              child: const Text('Submit Rejection', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportsQueue() {
    if (_reports.isEmpty) {
      return const Center(child: Text('No active moderation reports.', style: TextStyle(fontSize: 16.0, color: AppColors.textSecondary)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Active Moderation Reports', style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: AppColors.primaryBurgundy)),
        const SizedBox(height: 16.0),
        Expanded(
          child: ListView.builder(
            itemCount: _reports.length,
            itemBuilder: (context, index) {
              final report = _reports[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.m),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Report ID: ${report.id}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12.0),
                          ),
                          Text(report.time, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.0)),
                        ],
                      ),
                      const SizedBox(height: 12.0),
                      Text(
                        'Reporter: ${report.reporterName} ➔ Reported: ${report.reportedName}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, color: AppColors.primaryBurgundy),
                      ),
                      const SizedBox(height: 8.0),
                      Text('Reason: ${report.reason}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.error)),
                      const SizedBox(height: 6.0),
                      Text('Details: ${report.description}', style: const TextStyle(color: AppColors.textPrimary)),
                      const SizedBox(height: 16.0),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => _dismissReport(report),
                            child: const Text('Dismiss Flag'),
                          ),
                          const SizedBox(width: 12.0),
                          FilledButton(
                            onPressed: () => _suspendUser(report),
                            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                            child: const Text('Suspend User'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAuditLogsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Administrative Audit Logs', style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: AppColors.primaryBurgundy)),
        const SizedBox(height: 16.0),
        Expanded(
          child: ListView.builder(
            itemCount: _auditLogs.length,
            itemBuilder: (context, index) {
              final log = _auditLogs[index];
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                margin: const EdgeInsets.only(bottom: 8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  log,
                  style: const TextStyle(fontFamily: 'Courier', fontSize: 13.0, color: AppColors.textPrimary),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class VerificationTask {
  final String id;
  final String userId;
  final String userName;
  final int userAge;
  final String submittedAt;
  final String videoUrl;
  final String mainPhotoUrl;

  VerificationTask({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAge,
    required this.submittedAt,
    required this.videoUrl,
    required this.mainPhotoUrl,
  });
}

class ReportTask {
  final String id;
  final String reporterName;
  final String reportedName;
  final String reason;
  final String description;
  final String time;

  ReportTask({
    required this.id,
    required this.reporterName,
    required this.reportedName,
    required this.reason,
    required this.description,
    required this.time,
  });
}

class VideoPlayerDialog extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerDialog({super.key, required this.videoUrl});

  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() => _initialized = true);
        _controller.play();
        _controller.setLooping(true);
      }).catchError((e) {
        setState(() => _error = e.toString());
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black,
      contentPadding: EdgeInsets.zero,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      content: AspectRatio(
        aspectRatio: _initialized ? _controller.value.aspectRatio : 9 / 16,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_initialized)
              VideoPlayer(_controller)
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading video: $_error',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              )
            else
              const CircularProgressIndicator(color: Colors.white),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            if (_initialized)
              Positioned(
                bottom: 10,
                child: IconButton(
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_filled_rounded,
                    color: Colors.white,
                    size: 56,
                  ),
                  onPressed: () {
                    setState(() {
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
