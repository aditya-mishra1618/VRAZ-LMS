import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'teacher_app_drawer.dart'; // Import your central drawer

// Data for the JEE Class selection
final List<String> jeeClasses = [
  '11th JEE Mains',
  '12th JEE Mains',
  '11th JEE Advanced',
  '12th JEE Advanced',
];

// Sample data for JEE Maths Syllabus with dependent sub-topics
final Map<String, List<String>> jeeMathsSyllabus = {
  'Algebra': [
    'Complex Numbers and Quadratic Equations',
    'Matrices and Determinants',
    'Permutations and Combinations',
    'Binomial Theorem',
    'Sequences and Series',
  ],
  'Calculus': [
    'Limits, Continuity and Differentiability',
    'Integral Calculus',
    'Differential Equations',
    'Co-ordinate Geometry',
  ],
  'Vectors and 3D Geometry': [
    'Vector Algebra',
    'Three Dimensional Geometry',
  ],
  'Trigonometry': [
    'Trigonometric Functions',
    'Inverse Trigonometric Functions',
    'Properties of Triangles',
  ],
  'Statistics and Probability': [
    'Statistics',
    'Probability',
  ],
};

class SyllabusTrackingScreen extends StatefulWidget {
  const SyllabusTrackingScreen({super.key});

  @override
  State<SyllabusTrackingScreen> createState() => _SyllabusTrackingScreenState();
}

class _SyllabusTrackingScreenState extends State<SyllabusTrackingScreen> {
  DateTime _selectedDate = DateTime.now(); // Starts with the current date

  String? _selectedClass;
  String? _selectedMainTopic;
  String? _selectedSubTopic;
  List<String> _subTopics = [];

  final TextEditingController _descriptionController = TextEditingController();

  void _saveSyllabus() {
    // Basic validation
    if (_selectedClass == null ||
        _selectedMainTopic == null ||
        _selectedSubTopic == null ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields to save the syllabus.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // If validation passes, proceed to save
    print('--- SAVING SYLLABUS ---');
    print('Class: $_selectedClass');
    print('Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}');
    print('Main Topic: $_selectedMainTopic');
    print('Sub-Topic: $_selectedSubTopic');
    print('Description: ${_descriptionController.text}');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Syllabus entry saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      // --- ADD THE DRAWER ---
      drawer: const TeacherAppDrawer(),
      appBar: AppBar(
        // --- REMOVED THE LEADING BACK BUTTON ---
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Syllabus Tracking',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdownFormField(
              label: '',
              hint: 'Select a Class',
              value: _selectedClass,
              items: jeeClasses,
              onChanged: (newValue) {
                setState(() {
                  _selectedClass = newValue;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildDateSelector(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Syllabus",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // You can add logic here if needed, e.g., adding multiple entries
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDropdownFormField(
              label: 'What has been taught today (Topic)',
              hint: 'Select a main topic',
              value: _selectedMainTopic,
              items: jeeMathsSyllabus.keys.toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedMainTopic = newValue;
                  _selectedSubTopic = null;
                  _subTopics = jeeMathsSyllabus[newValue] ?? [];
                });
              },
            ),
            const SizedBox(height: 16),
            _buildDropdownFormField(
              label: 'Sub-topic',
              hint: 'Select a sub-topic',
              value: _selectedSubTopic,
              items: _subTopics,
              onChanged: _selectedMainTopic == null
                  ? null
                  : (newValue) {
                      setState(() {
                        _selectedSubTopic = newValue;
                      });
                    },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Description of the syllabus',
              hint: 'Describe what was taught in detail...',
              controller: _descriptionController,
              maxLines: 4,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ElevatedButton.icon(
          onPressed: _saveSyllabus,
          icon: const Icon(Icons.save_alt_rounded, color: Colors.white),
          label: const Text('Save Syllabus',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
            },
          ),
          Text(
            DateFormat('MMMM d, yyyy').format(_selectedDate),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              // Prevent selecting a future date
              if (!DateUtils.isSameDay(_selectedDate, DateTime.now())) {
                setState(() {
                  _selectedDate = _selectedDate.add(const Duration(days: 1));
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFormField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }
}
