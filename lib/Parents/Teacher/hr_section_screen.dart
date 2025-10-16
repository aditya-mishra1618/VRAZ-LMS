import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'teacher_app_drawer.dart'; // Import your central drawer

class HRSectionScreen extends StatefulWidget {
  const HRSectionScreen({super.key});

  @override
  State<HRSectionScreen> createState() => _HRSectionScreenState();
}

class _HRSectionScreenState extends State<HRSectionScreen> {
  // State for the form fields
  String? _selectedLeaveType;
  DateTime? _fromDate;
  DateTime? _toDate;

  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  // Function to show the date picker and update the state
  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      // Teacher can only apply for leaves starting from today
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        final formattedDate = DateFormat('MM/dd/yyyy').format(picked);
        if (isFromDate) {
          _fromDate = picked;
          _fromController.text = formattedDate;
          // Reset 'To' date if 'From' date is after it
          if (_toDate != null && _fromDate!.isAfter(_toDate!)) {
            _toDate = null;
            _toController.clear();
          }
        } else {
          _toDate = picked;
          _toController.text = formattedDate;
        }
      });
    }
  }

  void _applyForLeave() {
    // Basic validation
    if (_selectedLeaveType == null ||
        _fromController.text.isEmpty ||
        _toController.text.isEmpty ||
        _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all the fields before applying.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Logic to handle leave application
    print(
        'Leave Applied: $_selectedLeaveType from ${_fromController.text} to ${_toController.text}');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Leave application submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // Clear the form
    setState(() {
      _selectedLeaveType = null;
      _fromDate = null;
      _toDate = null;
      _fromController.clear();
      _toController.clear();
      _reasonController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      // --- The drawer is correctly connected ---
      drawer: const TeacherAppDrawer(),
      appBar: AppBar(
        // --- The leading back button is removed, which is correct ---
        title: const Text('HR Portal',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTeacherInfoCard(),
            const SizedBox(height: 24),
            const Text('Leave Balance Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildLeaveBalance(),
            const SizedBox(height: 24),
            _buildApplyForLeaveForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prof. Ramswaroop Sir',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('ID: 123456', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text('Mathematics Teacher',
                    style: TextStyle(color: Colors.blueAccent[700])),
              ],
            ),
          ),
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFFF0F4F8),
            backgroundImage: AssetImage('assets/profile.png'), // Placeholder
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveBalance() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLeaveIndicator('Sick Leave', 5, 10, Colors.red),
        _buildLeaveIndicator('Casual Leave', 3, 10, Colors.blue),
        _buildLeaveIndicator('Earned/Annual', 10, 15, Colors.green),
      ],
    );
  }

  Widget _buildLeaveIndicator(String label, int value, int total, Color color) {
    return Column(
      children: [
        SizedBox(
          height: 80,
          width: 80,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value / total,
                strokeWidth: 7,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Center(
                  child: Text('$value\n/$total',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildApplyForLeaveForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Apply for Leave',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildDropdown('Leave Type', 'Select Leave Type',
            ['Sick Leave', 'Casual Leave', 'Earned/Annual Leave']),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildDatePicker(
                    'From', _fromController, () => _selectDate(context, true))),
            const SizedBox(width: 16),
            Expanded(
                child: _buildDatePicker(
                    'To', _toController, () => _selectDate(context, false))),
          ],
        ),
        const SizedBox(height: 16),
        _buildReasonField(),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _applyForLeave, // Updated onPressed handler
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Apply Leave',
                style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String hint, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedLeaveType,
            hint: Text(hint),
            items: items.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (newValue) {
              setState(() => _selectedLeaveType = newValue);
            },
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(
      String label, TextEditingController controller, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: 'mm/dd/yyyy',
            filled: true,
            fillColor: Colors.white,
            suffixIcon: const Icon(Icons.calendar_today_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReasonField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reason',
            style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: _reasonController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Please provide a reason for your leave',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
