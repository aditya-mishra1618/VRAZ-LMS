import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for date formatting

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

  // These lists are now mutable to allow adding new meetings
  final List<Map<String, String>> _upcomingMeetings = [
    {
      'title': 'Math',
      'teacher': 'Prof. RamSwaroop ',
      'date': 'Oct 10, 2025',
      'time': '10:00 AM',
      'status': 'SCHEDULED'
    },
    {
      'title': 'Physics ',
      'teacher': 'Prof. Zeeshan ',
      'date': 'Oct 5, 2025',
      'time': '11:00 AM',
      'status': 'SCHEDULED'
    },
  ];
  final List<Map<String, String>> _pastMeetings = [
    {
      'title': 'Chemistry',
      'teacher': 'Prof. Ankit ',
      'date': 'Sep 15, 2025',
      'time': '9:00 AM',
      'status': 'COMPLETED'
    },
  ];

  // --- NEW: Method to add a meeting to the list ---
  void _addMeeting(Map<String, String> newMeeting) {
    setState(() {
      _upcomingMeetings.insert(0, newMeeting); // Add to the top of the list
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upcoming',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._upcomingMeetings.map((meeting) => _buildMeetingCard(meeting)),
            const SizedBox(height: 24),
            const Text('Past',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._pastMeetings.map((meeting) => _buildMeetingCard(meeting)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showRequestModal(context);
        },
        label: const Text('Request a Meeting'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showRequestModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        // --- UPDATED: Pass the _addMeeting function to the modal ---
        return RequestMeetingModal(onAddMeeting: _addMeeting);
      },
    );
  }

  Widget _buildMeetingCard(Map<String, String> meeting) {
    final bool isScheduled = meeting['status'] == 'SCHEDULED';
    final Color iconColor = isScheduled ? Colors.blueAccent : Colors.grey;
    final Color statusColor = isScheduled ? Colors.blue : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(
            isScheduled
                ? Icons.calendar_month_outlined
                : Icons.check_circle_outline,
            color: iconColor,
          ),
        ),
        title: Text(meeting['title']!,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(meeting['teacher']!),
            Text('${meeting['date']!} · ${meeting['time']!}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            meeting['status']!,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- UPDATED: The RequestMeetingModal now handles state and callbacks ---
class RequestMeetingModal extends StatefulWidget {
  final Function(Map<String, String>) onAddMeeting;

  const RequestMeetingModal({super.key, required this.onAddMeeting});

  @override
  State<RequestMeetingModal> createState() => _RequestMeetingModalState();
}

class _RequestMeetingModalState extends State<RequestMeetingModal> {
  String? _selectedTeacherName;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  final List<Map<String, String>> _teachers = [
    {'name': 'Prof. Zeeshan Sir', 'subject': 'Physics'},
    {'name': 'Prof. RamSwaroop Sir', 'subject': 'Mathematics'},
    {'name': 'Prof. Ankit Sir', 'subject': 'Chemistry'},
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('MMM d, yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  void _submitRequest() {
    // Basic validation
    if (_selectedTeacherName == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields.')));
      return;
    }

    // Find the subject for the selected teacher
    final teacherData = _teachers
        .firstWhere((teacher) => teacher['name'] == _selectedTeacherName);
    final subject = teacherData['subject']!;

    // Create the new meeting object
    final newMeeting = {
      'title': subject,
      'teacher': _selectedTeacherName!,
      'date': DateFormat('MMM d, yyyy').format(_selectedDate!),
      'time': _selectedTime!.format(context),
      'status': 'SCHEDULED'
    };

    // Call the callback function to update the main screen
    widget.onAddMeeting(newMeeting);

    Navigator.pop(context); // Close the modal
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting request submitted!')));
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
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
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Select a teacher',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Schedule Date and Time',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dateController,
                      readOnly: true,
                      onTap: () => _selectDate(context),
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
                      onTap: () => _selectTime(context),
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
                onPressed: _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Submit Request',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
