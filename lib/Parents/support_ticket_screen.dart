import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// Import your drawer and the chat screen
import 'parent_app_drawer.dart'; // Make sure this path is correct
import 'support_chat_screen.dart';

// --- Data Model for a Support Ticket ---
class SupportTicket {
  final String id;
  final String title;
  final DateTime date;
  String status; // 'Resolved', 'In Progress', 'Pending'
  final String? category;
  final String? details;
  final String? imagePath;

  SupportTicket({
    required this.id,
    required this.title,
    required this.date,
    required this.status,
    this.category,
    this.details,
    this.imagePath,
  });
}

class SupportTicketScreen extends StatefulWidget {
  const SupportTicketScreen({super.key});

  @override
  State<SupportTicketScreen> createState() => _SupportTicketScreenState();
}

class _SupportTicketScreenState extends State<SupportTicketScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- Dummy Data for Past Tickets ---
  final List<SupportTicket> _pastTickets = [
    SupportTicket(
        id: '1',
        title: 'Academic: Problem with Course Material',
        date: DateTime(2024, 1, 10),
        status: 'In Progress',
        category: 'Academic',
        details: 'Link for Physics Chapter 3 PDF is broken.'),
    SupportTicket(
        id: '2',
        title: 'Attendance: Issue with Attendance',
        date: DateTime(2024, 1, 15),
        status: 'Resolved',
        category: 'Attendance',
        details: 'Marked absent on a day child was present.'),
    SupportTicket(
      id: '3',
      title: 'Payment: Fee Payment Confirmation',
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: 'Pending',
      category: 'Payment',
      details: 'Payment made via UPI, not reflecting in portal yet.',
    )
  ];

  // Method to add a new ticket to the list
  void _addTicket(SupportTicket ticket) {
    setState(() {
      _pastTickets.insert(0, ticket);
    });
  }

  // --- Navigation to Chat Screen ---
  void _navigateToChat(SupportTicket ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupportChatScreen(
          // Navigate to the chat screen
          grievanceTitle: ticket.title,
          navigationSource: 'support_ticket_screen', // Pass the source
        ),
      ),
    );
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
        title: const Text('Support Tickets',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      drawer: ParentAppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Past Tickets',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_pastTickets.isEmpty)
              const Center(
                  child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Text('No tickets raised yet.',
                    style: TextStyle(color: Colors.grey)),
              ))
            else
              ..._pastTickets.map((ticket) => _buildTicketCard(ticket)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showTicketModal(context);
        },
        // --- RENAMED ---
        label: const Text('Raise Ticket'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showTicketModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return RaiseSupportTicketModal(onAddTicket: _addTicket);
      },
    );
  }

  // --- This card now handles navigation ---
  Widget _buildTicketCard(SupportTicket ticket) {
    final bool isResolved = ticket.status == 'Resolved';
    final bool canChat = !isResolved; // Enable chat if not resolved
    final DateFormat formatter = DateFormat('MMM dd, yyyy');

    Color statusColor;
    Color statusBgColor;
    switch (ticket.status) {
      case 'Resolved':
        statusColor = Colors.green.shade700;
        statusBgColor = Colors.green.shade50;
        break;
      case 'In Progress':
        statusColor = Colors.blue.shade700;
        statusBgColor = Colors.blue.shade50;
        break;
      default: // Pending
        statusColor = Colors.orange.shade700;
        statusBgColor = Colors.orange.shade50;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.1),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        // --- ADDED: onTap handler ---
        onTap: () => _navigateToChat(ticket),
        title: Text(ticket.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(formatter.format(ticket.date)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ticket.status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            // --- Show chat icon ---
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(Icons.chat_bubble_outline,
                  color: Colors.blueAccent, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Modal for raising a new ticket
// --------------------------------------------------------------------------
class RaiseSupportTicketModal extends StatefulWidget {
  final Function(SupportTicket) onAddTicket;

  const RaiseSupportTicketModal({super.key, required this.onAddTicket});

  @override
  State<RaiseSupportTicketModal> createState() =>
      _RaiseSupportTicketModalState();
}

class _RaiseSupportTicketModalState extends State<RaiseSupportTicketModal> {
  String? _selectedCategory = 'Academic';
  File? _attachedImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _attachedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to pick image.')));
      }
    }
  }

  void _submitTicket() {
    if (_titleController.text.trim().isEmpty ||
        _selectedCategory == null ||
        _detailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please fill all required fields.'),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    final newTicket = SupportTicket(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      // Combine category and title
      title: '${_selectedCategory!}: ${_titleController.text.trim()}',
      date: DateTime.now(),
      status: 'Pending',
      category: _selectedCategory,
      details: _detailsController.text.trim(),
      imagePath: _attachedImage?.path,
    );

    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      widget.onAddTicket(newTicket); // Call the callback
      setState(() => _isLoading = false);
      Navigator.pop(context); // Close modal
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Your grievance has been submitted.'),
          backgroundColor: Colors.green));
    });
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
                    'Raise New Ticket', // Renamed
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
              _buildDropdown(), // Category first
              const SizedBox(height: 20),
              _buildTitleField(_titleController),
              const SizedBox(height: 20),
              _buildDescriptionField(_detailsController),
              const SizedBox(height: 20),
              _buildAttachmentSection(),
              if (_attachedImage != null) _buildImagePreview(),
              const SizedBox(height: 30),
              _buildSubmitButton(_isLoading, _submitTicket),
              const SizedBox(height: 16), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ticket Title *',
            style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'e.g., Unable to access course materials',
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category *', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedCategory,
            items: ['Academic', 'Payment', 'Attendance', 'Timetable', 'Other']
                .map((String category) {
              return DropdownMenuItem<String>(
                  value: category, child: Text(category));
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedCategory = newValue;
              });
            },
            decoration: const InputDecoration(
              hintText: 'Select a category',
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Issue Details *',
            style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Please describe the issue in detail...',
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Attachments (Optional)',
            style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: _buildAttachmentButton(Icons.camera_alt_outlined,
                    'Camera', () => _pickImage(ImageSource.camera))),
            const SizedBox(width: 16),
            Expanded(
                child: _buildAttachmentButton(Icons.photo_library_outlined,
                    'Gallery', () => _pickImage(ImageSource.gallery))),
          ],
        ),
      ],
    );
  }

  Widget _buildAttachmentButton(
      IconData icon, String label, VoidCallback onPressed) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 20),
      label: Text(label),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey[700],
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Colors.grey[300]!),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 150),
                child: Image.file(_attachedImage!, fit: BoxFit.cover)),
          ),
          InkWell(
            onTap: () => setState(() => _attachedImage = null),
            child: const CircleAvatar(
              radius: 12,
              backgroundColor: Colors.black54,
              child: Icon(Icons.close, color: Colors.white, size: 14),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isLoading, VoidCallback onSubmit) {
    return ElevatedButton(
      onPressed: isLoading ? null : onSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        disabledBackgroundColor: Colors.grey.shade400,
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Text('Submit Grievance', // Renamed
              style: TextStyle(color: Colors.white, fontSize: 16)),
    );
  }
}
