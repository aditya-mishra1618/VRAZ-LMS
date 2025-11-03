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

  List<Map<String, String>> _upcomingMeetings = [];
  List<Map<String, String>> _pastMeetings = [];
  bool _isLoading = true;
  String? _authToken;
  int? _admissionId; // ✅ NEW: For API call

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
      _admissionId = prefs.getInt('selected_child_id'); // ✅ Get admission ID

      print('[PTMScreen] Auth Token: ${_authToken != null ? "Found" : "Missing"}');
      print('[PTMScreen] Admission ID: $_admissionId');

      if (_authToken == null || _authToken!.isEmpty) {
        print('[PTMScreen] ❌ No auth token found');
        return;
      }

      final meetings = await MeetingApi.fetchMeetings(authToken: _authToken!);

      _upcomingMeetings.clear();
      _pastMeetings.clear();

      for (var meeting in meetings) {
        final meetingMap = {
          'title': meeting.reason,
          'teacher': meeting.teacher.fullName,
          'date': meeting.formattedDate,
          'time': meeting.formattedTime,
          'status': meeting.displayStatus,
        };

        if (meeting.isUpcoming || meeting.isPending) {
          _upcomingMeetings.add(meetingMap);
        } else if (meeting.isPast || meeting.isCompleted) {
          _pastMeetings.add(meetingMap);
        }
      }

      print('[PTMScreen] ✅ Loaded: ${_upcomingMeetings.length} upcoming, ${_pastMeetings.length} past');
    } catch (e) {
      print('[PTMScreen] ❌ Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addMeeting(Map<String, String> newMeeting) {
    setState(() {
      _upcomingMeetings.insert(0, newMeeting);
    });
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
        title: const Text('Parent-Teacher Meetings',
            style:
            TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      drawer: const ParentAppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadMeetings, // ✅ Pull to refresh
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Upcoming',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (_upcomingMeetings.isEmpty)
                const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No upcoming meetings'),
                    ))
              else
                ..._upcomingMeetings
                    .map((meeting) => _buildMeetingCard(meeting)),
              const SizedBox(height: 24),
              const Text('Past',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (_pastMeetings.isEmpty)
                const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No past meetings'),
                    ))
              else
                ..._pastMeetings
                    .map((meeting) => _buildMeetingCard(meeting)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // ✅ Pass auth token and admission ID
          final result = await _showRequestModal(context);
          if (result == true) {
            _loadMeetings(); // ✅ Reload after creating meeting
          }
        },
        label: const Text('Request a Meeting'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<bool?> _showRequestModal(BuildContext context) async {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return RequestMeetingModal(
          onAddMeeting: _addMeeting,
          authToken: _authToken!, // ✅ Pass token
          admissionId: _admissionId!, // ✅ Pass admission ID
        );
      },
    );
  }

  Widget _buildMeetingCard(Map<String, String> meeting) {
    final String status = meeting['status']!;

    // ✅ Enhanced status styling
    final bool isScheduled = status == 'SCHEDULED' || status == 'ACCEPTED';
    final bool isPending = status == 'PENDING';
    final bool isCompleted = status == 'COMPLETED';
    final bool isDeclined = status == 'DECLINED';

    // ✅ Dynamic colors based on status
    Color iconColor;
    Color statusColor;
    Color statusBgColor;
    IconData iconData;

    if (isPending) {
      iconColor = Colors.orange;
      statusColor = Colors.orange.shade700;
      statusBgColor = Colors.orange.shade50;
      iconData = Icons.pending_outlined;
    } else if (isScheduled) {
      iconColor = Colors.blueAccent;
      statusColor = Colors.blue.shade700;
      statusBgColor = Colors.blue.shade50;
      iconData = Icons.calendar_month_outlined;
    } else if (isCompleted) {
      iconColor = Colors.green;
      statusColor = Colors.green.shade700;
      statusBgColor = Colors.green.shade50;
      iconData = Icons.check_circle_outline;
    } else if (isDeclined) {
      iconColor = Colors.red;
      statusColor = Colors.red.shade700;
      statusBgColor = Colors.red.shade50;
      iconData = Icons.cancel_outlined;
    } else {
      iconColor = Colors.grey;
      statusColor = Colors.grey.shade700;
      statusBgColor = Colors.grey.shade50;
      iconData = Icons.event_busy;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isPending ? 2 : 0, // ✅ Elevated for pending
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPending
            ? BorderSide(color: Colors.orange.shade300, width: 2) // ✅ Orange border for pending
            : BorderSide.none,
      ),
      child: Container(
        decoration: isPending
            ? BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade50.withOpacity(0.3),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        )
            : null,
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: iconColor.withOpacity(0.15),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 26,
                ),
              ),
              // ✅ Pulsing indicator for pending
              if (isPending)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  meeting['title']!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isPending ? Colors.orange.shade900 : Colors.black87,
                  ),
                ),
              ),
              // ✅ "Waiting" badge for pending
              if (isPending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade300, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hourglass_empty, size: 12, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Waiting',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                meeting['teacher']!,
                style: TextStyle(
                  fontWeight: isPending ? FontWeight.w600 : FontWeight.normal,
                  color: isPending ? Colors.black87 : Colors.black54,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: isPending ? Colors.orange.shade700 : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${meeting['date']!} · ${meeting['time']!}',
                    style: TextStyle(
                      color: isPending ? Colors.orange.shade700 : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: isPending ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isPending ? Colors.orange.shade300 : statusColor.withOpacity(0.3),
                width: isPending ? 1.5 : 1,
              ),
              boxShadow: isPending
                  ? [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
                  : null,
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }}

// ✅ UPDATED REQUEST MODAL with API Integration
class RequestMeetingModal extends StatefulWidget {
  final Function(Map<String, String>) onAddMeeting;
  final String authToken;
  final int admissionId;

  const RequestMeetingModal({
    super.key,
    required this.onAddMeeting,
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