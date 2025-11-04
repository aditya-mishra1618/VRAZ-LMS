import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vraz_application/Parents/service/meeting_api.dart';

import 'models/meeting_model.dart';
import 'parent_app_drawer.dart';

class ParentTeacherMeetingScreen extends StatefulWidget {
  const ParentTeacherMeetingScreen({super.key});

  @override
  State<ParentTeacherMeetingScreen> createState() =>
      _ParentTeacherMeetingScreenState();
}

class _ParentTeacherMeetingScreenState
    extends State<ParentTeacherMeetingScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Meeting> _upcomingMeetings = [];
  List<Meeting> _pastMeetings = [];
  List<Meeting> _declinedMeetings = [];
  bool _isLoading = true;
  String? _authToken;
  int? _admissionId;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('parent_auth_token');
      _admissionId = prefs.getInt('selected_child_id');

      if (_authToken == null || _authToken!.isEmpty) {
        _showError('Session expired. Please login again.');
        return;
      }

      final meetings = await MeetingApi.fetchMeetings(authToken: _authToken!);

      _upcomingMeetings.clear();
      _pastMeetings.clear();
      _declinedMeetings.clear();

      for (var meeting in meetings) {
        if (meeting.isDeclined) {
          _declinedMeetings.add(meeting);
        } else if (meeting.isUpcoming || meeting.isPending) {
          _upcomingMeetings.add(meeting);
        } else if (meeting.isPast || meeting.isCompleted) {
          _pastMeetings.add(meeting);
        }
      }

      print('[PTMScreen] ✅ Upcoming: ${_upcomingMeetings.length}, Past: ${_pastMeetings.length}, Declined: ${_declinedMeetings.length}');
    } catch (e) {
      print('[PTMScreen] ❌ Error: $e');
      _showError('Failed to load meetings');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  // ✅ ACCEPT/DECLINE LOGIC
  Future<void> _handleAcceptDecline(Meeting meeting, String newStatus) async {
    final isAccept = newStatus == 'ACCEPTED';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAccept ? 'Accept Meeting?' : 'Decline Meeting?'),
        content: Text(
          isAccept
              ? 'Do you want to accept this meeting with ${meeting.teacher.fullName}?'
              : 'Are you sure you want to decline this meeting?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isAccept ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isAccept ? 'Accept' : 'Decline'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    setState(() => _isLoading = true);

    try {
      print('[PTMScreen] 🔄 Updating meeting ${meeting.id} to $newStatus');

      final success = await MeetingApi.updateMeetingStatus(
        authToken: _authToken!,
        meetingId: meeting.id,
        newStatus: newStatus,
      );

      if (success) {
        _showSuccess(isAccept ? '✅ Meeting accepted!' : '❌ Meeting declined');
        await _loadMeetings(); // Reload meetings
      } else {
        _showError('Failed to update meeting status');
      }
    } catch (e) {
      print('[PTMScreen] ❌ Error: $e');
      _showError('An error occurred');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black54),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'Parent-Teacher Meetings',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      drawer: const ParentAppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadMeetings,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Upcoming', _upcomingMeetings.length),
              const SizedBox(height: 12),
              if (_upcomingMeetings.isEmpty)
                _buildEmptyState('No upcoming meetings', Icons.event_available)
              else
                ..._upcomingMeetings.map((meeting) => _buildMeetingCard(meeting)),

              const SizedBox(height: 24),

              _buildSectionHeader('Past', _pastMeetings.length),
              const SizedBox(height: 12),
              if (_pastMeetings.isEmpty)
                _buildEmptyState('No past meetings', Icons.history)
              else
                ..._pastMeetings.map((meeting) => _buildMeetingCard(meeting)),

              const SizedBox(height: 24),

              if (_declinedMeetings.isNotEmpty) ...[
                _buildSectionHeader('Declined', _declinedMeetings.length),
                const SizedBox(height: 12),
                ..._declinedMeetings.map((meeting) => _buildMeetingCard(meeting)),
                const SizedBox(height: 80),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await _showRequestModal(context);
          if (result == true) {
            _loadMeetings();
          }
        },
        label: const Text('Request Meeting'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingCard(Meeting meeting) {
    final statusInfo = _getStatusInfo(meeting);
    final bool showButtons = meeting.isPending && meeting.isAdminInitiated;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: showButtons ? 2 : 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: showButtons
            ? BorderSide(color: Colors.orange.shade300, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusInfo['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    statusInfo['icon'],
                    color: statusInfo['color'],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meeting.reason,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusInfo['bgColor'],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          meeting.displayStatus,
                          style: TextStyle(
                            color: statusInfo['color'],
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildInitiatorBadge(meeting),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            Row(
              children: [
                Icon(Icons.person_outline, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    meeting.teacher.fullName,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${meeting.formattedDate} · ${meeting.formattedTime}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // ✅ ACCEPT/DECLINE BUTTONS
            if (showButtons) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleAcceptDecline(meeting, 'DECLINED'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Decline', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleAcceptDecline(meeting, 'ACCEPTED'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Accept', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInitiatorBadge(Meeting meeting) {
    if (meeting.isAdminInitiated) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Text(
          'Admin',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.purple.shade700,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Text(
          'You',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
      );
    }
  }

  Map<String, dynamic> _getStatusInfo(Meeting meeting) {
    if (meeting.isPending) {
      return {
        'icon': Icons.schedule,
        'color': Colors.orange.shade600,
        'bgColor': Colors.orange.shade50,
      };
    } else if (meeting.isScheduled || meeting.isAccepted) {
      return {
        'icon': Icons.check_circle,
        'color': Colors.green.shade600,
        'bgColor': Colors.green.shade50,
      };
    } else if (meeting.isCompleted) {
      return {
        'icon': Icons.task_alt,
        'color': Colors.blue.shade600,
        'bgColor': Colors.blue.shade50,
      };
    } else if (meeting.isDeclined) {
      return {
        'icon': Icons.cancel,
        'color': Colors.red.shade600,
        'bgColor': Colors.red.shade50,
      };
    } else if (meeting.isCancelled) {
      return {
        'icon': Icons.event_busy,
        'color': Colors.grey.shade600,
        'bgColor': Colors.grey.shade50,
      };
    } else {
      return {
        'icon': Icons.help_outline,
        'color': Colors.grey.shade600,
        'bgColor': Colors.grey.shade50,
      };
    }
  }

  Future<bool?> _showRequestModal(BuildContext context) async {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return RequestMeetingModal(
          authToken: _authToken!,
          admissionId: _admissionId!,
        );
      },
    );
  }
}

// Keep your existing RequestMeetingModal unchanged
class RequestMeetingModal extends StatefulWidget {
  final String authToken;
  final int admissionId;

  const RequestMeetingModal({
    super.key,
    required this.authToken,
    required this.admissionId,
  });

  @override
  State<RequestMeetingModal> createState() => _RequestMeetingModalState();
}


class _RequestMeetingModalState extends State<RequestMeetingModal> {
  String? _selectedTeacherName;
  String? _selectedTeacherId; // ✅ Store teacher ID
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  DateTime? _selectedDate2; // ✅ Second date
  TimeOfDay? _selectedTime2; // ✅ Second time

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _dateController2 = TextEditingController();
  final TextEditingController _timeController2 = TextEditingController();
  final TextEditingController _reasonController = TextEditingController(); // ✅ Reason

  bool _isSubmitting = false;

  // ✅ TODO: Replace with API to fetch teachers
  final List<Map<String, String>> _teachers = [
    {
      'name': 'Prof. Zeeshan Sir',
      'subject': 'Physics',
      'id': 'b1493af7-f743-4def-aecc-2951f16fe25c'
    },
    {
      'name': 'Prof. RamSwaroop Sir',
      'subject': 'Mathematics',
      'id': 'fedc3011-1d8d-41df-93d9-3471ee03ee66'
    },
    {
      'name': 'Prof. Ankit Sir',
      'subject': 'Chemistry',
      'id': 'teacher-id-3'
    },
  ];

  Future<void> _selectDate(BuildContext context, bool isFirst) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null) {
      setState(() {
        if (isFirst) {
          _selectedDate = picked;
          _dateController.text = DateFormat('MMM d, yyyy').format(picked);
        } else {
          _selectedDate2 = picked;
          _dateController2.text = DateFormat('MMM d, yyyy').format(picked);
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isFirst) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isFirst) {
          _selectedTime = picked;
          _timeController.text = picked.format(context);
        } else {
          _selectedTime2 = picked;
          _timeController2.text = picked.format(context);
        }
      });
    }
  }

  Future<void> _submitRequest() async {
    // Validation
    if (_selectedTeacherId == null) {
      _showError('Please select a teacher');
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      _showError('Please enter a reason for the meeting');
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      _showError('Please select at least one time slot');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Build time slots
      List<DateTime> timeSlots = [];

      // First slot
      final slot1 = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      timeSlots.add(slot1);

      // Second slot (optional)
      if (_selectedDate2 != null && _selectedTime2 != null) {
        final slot2 = DateTime(
          _selectedDate2!.year,
          _selectedDate2!.month,
          _selectedDate2!.day,
          _selectedTime2!.hour,
          _selectedTime2!.minute,
        );
        timeSlots.add(slot2);
      }

      print('[RequestMeeting] Creating meeting with ${timeSlots.length} time slots');

      // ✅ Call API
      final success = await MeetingApi.createMeetingRequest(
        authToken: widget.authToken,
        admissionId: widget.admissionId,
        teacherId: _selectedTeacherId!,
        reason: _reasonController.text.trim(),
        requestedTimeSlots: timeSlots,
      );

      if (success) {
        if (mounted) {
          Navigator.pop(context, true); // ✅ Return true to reload
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Meeting request submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          _showError('Failed to submit meeting request. Please try again.');
        }
      }
    } catch (e) {
      print('[RequestMeeting] Error: $e');
      if (mounted) {
        _showError('An error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _dateController2.dispose();
    _timeController2.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: const BoxDecoration(
          color: Color(0xFFF0F4F8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Request a Meeting',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Select Teacher',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedTeacherName,
                  items: _teachers.map((teacher) {
                    return DropdownMenuItem<String>(
                        value: teacher['name'],
                        child:
                        Text('${teacher['name']} - ${teacher['subject']}'));
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedTeacherName = newValue;
                      // ✅ Find teacher ID
                      _selectedTeacherId = _teachers.firstWhere(
                              (t) => t['name'] == newValue)['id'];
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Select a teacher',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Reason for Meeting',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g., Discuss student progress...',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Preferred Time Slot 1 (Required)',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dateController,
                      readOnly: true,
                      onTap: () => _selectDate(context, true),
                      decoration: InputDecoration(
                        hintText: 'Select Date',
                        fillColor: Colors.white,
                        filled: true,
                        prefixIcon: const Icon(Icons.calendar_today, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _timeController,
                      readOnly: true,
                      onTap: () => _selectTime(context, true),
                      decoration: InputDecoration(
                        hintText: 'Select Time',
                        fillColor: Colors.white,
                        filled: true,
                        prefixIcon: const Icon(Icons.access_time, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Preferred Time Slot 2 (Optional)',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dateController2,
                      readOnly: true,
                      onTap: () => _selectDate(context, false),
                      decoration: InputDecoration(
                        hintText: 'Select Date',
                        fillColor: Colors.white,
                        filled: true,
                        prefixIcon: const Icon(Icons.calendar_today, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _timeController2,
                      readOnly: true,
                      onTap: () => _selectTime(context, false),
                      decoration: InputDecoration(
                        hintText: 'Select Time',
                        fillColor: Colors.white,
                        filled: true,
                        prefixIcon: const Icon(Icons.access_time, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey[400],
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text('Submit Request',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}