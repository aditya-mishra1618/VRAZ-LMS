import 'package:flutter/material.dart';

class CreateMcqAssignmentScreen extends StatefulWidget {
  final String assignmentTitle;
  const CreateMcqAssignmentScreen({super.key, required this.assignmentTitle});

  @override
  State<CreateMcqAssignmentScreen> createState() =>
      _CreateMcqAssignmentScreenState();
}

class _CreateMcqAssignmentScreenState extends State<CreateMcqAssignmentScreen> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _optionAController = TextEditingController();
  final TextEditingController _optionBController = TextEditingController();
  final TextEditingController _optionCController = TextEditingController();
  final TextEditingController _optionDController = TextEditingController();
  int? _correctAnswerIndex; // 0 for A, 1 for B, etc.

  @override
  void dispose() {
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    // Basic validation
    if (_questionController.text.isEmpty ||
        _optionAController.text.isEmpty ||
        _optionBController.text.isEmpty ||
        _optionCController.text.isEmpty ||
        _optionDController.text.isEmpty ||
        _correctAnswerIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select a correct answer.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Here you would add the question to a list
    print('Question Added: ${_questionController.text}');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Question added to the assignment!'),
        backgroundColor: Colors.green,
      ),
    );

    // Clear fields for the next question
    _questionController.clear();
    _optionAController.clear();
    _optionBController.clear();
    _optionCController.clear();
    _optionDController.clear();
    setState(() {
      _correctAnswerIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(widget.assignmentTitle,
            style: const TextStyle(
                color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(_questionController, 'Enter Question', maxLines: 3),
            const SizedBox(height: 24),
            const Text('Options',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildOptionField(_optionAController, 'A'),
            _buildOptionField(_optionBController, 'B'),
            _buildOptionField(_optionCController, 'C'),
            _buildOptionField(_optionDController, 'D'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addQuestion,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Add Question'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: () {
            // Logic to save the entire assignment
            Navigator.pop(context); // Go back after saving
          },
          icon: const Icon(Icons.save, color: Colors.white),
          label: const Text('Save Full Assignment',
              style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return TextField(
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
    );
  }

  Widget _buildOptionField(TextEditingController controller, String option) {
    int optionIndex;
    switch (option) {
      case 'A':
        optionIndex = 0;
        break;
      case 'B':
        optionIndex = 1;
        break;
      case 'C':
        optionIndex = 2;
        break;
      default:
        optionIndex = 3;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Radio<int>(
            value: optionIndex,
            groupValue: _correctAnswerIndex,
            onChanged: (value) {
              setState(() {
                _correctAnswerIndex = value;
              });
            },
          ),
          Expanded(
            child: _buildTextField(controller, 'Option $option'),
          ),
        ],
      ),
    );
  }
}
