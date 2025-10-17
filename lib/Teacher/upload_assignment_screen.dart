import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'create_mcq_assignment_screen.dart'; // Import the new screen
import 'teacher_app_drawer.dart';

class UploadAssignmentScreen extends StatefulWidget {
  const UploadAssignmentScreen({super.key});

  @override
  State<UploadAssignmentScreen> createState() => _UploadAssignmentScreenState();
}

class _UploadAssignmentScreenState extends State<UploadAssignmentScreen> {
  String? _selectedClass;
  String? _selectedSubject;
  File? _selectedFile; // To hold the selected file (image or PDF)

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();

  // --- Function to handle Text/MCQ button press ---
  void _createTextAssignment() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an assignment title first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateMcqAssignmentScreen(
          assignmentTitle: _titleController.text,
        ),
      ),
    );
  }

  // --- Function to pick an image from the gallery ---
  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedFile = File(image.path);
      });
    }
  }

  // --- Function to pick an image using the camera ---
  Future<void> _pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedFile = File(image.path);
      });
    }
  }

  // --- Function to pick a PDF/Doc file ---
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      drawer: const TeacherAppDrawer(),
      appBar: AppBar(
        title: const Text('Upload Assignment',
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
            _buildLabeledDropdown(
              label: 'Class/Section',
              hint: 'Select Class/Section',
              value: _selectedClass,
              options: const [
                '11th JEE MAINS',
                '12th JEE MAINS',
                '11th JEE ADV',
                '12th JEE ADV'
              ],
              onChanged: (newValue) =>
                  setState(() => _selectedClass = newValue),
            ),
            const SizedBox(height: 24),
            _buildLabeledDropdown(
              label: 'Subject',
              hint: 'Select Subject',
              value: _selectedSubject,
              options: const [
                'Algebra',
                'Calculus',
                'Coordinate Geometry',
                'Trigonometry'
              ],
              onChanged: (newValue) =>
                  setState(() => _selectedSubject = newValue),
            ),
            const SizedBox(height: 24),
            _buildLabeledTextField(
              label: 'Assignment Title',
              hint: 'e.g., Algebra Worksheet',
              controller: _titleController,
            ),
            const SizedBox(height: 24),
            // ... Other text fields ...
            const SizedBox(height: 24),
            _buildUploadTypeSection(),
            const SizedBox(height: 16),
            // Display selected file name if any
            if (_selectedFile != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Selected: ${_selectedFile!.path.split('/').last}',
                        style: TextStyle(color: Colors.grey.shade800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => setState(() => _selectedFile = null),
                    )
                  ],
                ),
              ),
            const SizedBox(height: 32),
            _buildUploadButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    // ... This widget remains unchanged ...
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    // ... This widget remains unchanged, just pass controller...
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Type',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _buildUploadTypeButton(
                Icons.text_fields, 'Text/MCQ', _createTextAssignment),
            _buildUploadTypeButton(
                Icons.image_outlined, 'Image', _pickImageFromGallery),
            _buildUploadTypeButton(
                Icons.picture_as_pdf_outlined, 'PDF/Doc', _pickFile),
            _buildUploadTypeButton(Icons.camera_alt_outlined, 'Camera',
                _pickImageFromCamera), // New button
          ],
        ),
      ],
    );
  }

  Widget _buildUploadTypeButton(
      IconData icon, String label, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.black54),
      label: Text(
        label,
        style: const TextStyle(color: Colors.black87),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context) {
    // ... This widget remains unchanged ...
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assignment uploaded successfully!')),
          );
        },
        icon: const Icon(Icons.upload_file_outlined, color: Colors.white),
        label: const Text(
          'Upload Assignment',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
