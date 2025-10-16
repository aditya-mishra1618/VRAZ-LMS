import 'package:flutter/material.dart';

import 'app_drawer.dart'; // Import the shared drawer

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _selectedTeacher;
  final List<String> _teachers = [
    'Zeeshan Sir - Physics',
    'Ankit Sir - Chemistry',
    'Ramswaroop Sir - Maths',
  ];

  // State for star ratings
  int _clarityRating = 0;
  int _engagementRating = 0;
  int _approachabilityRating = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4F8),
      drawer: const AppDrawer(), // Add the shared app drawer
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.black54),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Teacher Feedback',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your feedback helps us improve. Please be honest and constructive.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),
            _buildTeacherDropdown(),
            const SizedBox(height: 20),
            _buildFeedbackCard(
              title: 'Clarity of Explanations',
              question:
                  'Were the concepts explained clearly and understandably?',
              rating: _clarityRating,
              onRatingUpdate: (rating) =>
                  setState(() => _clarityRating = rating),
              hintText: 'Optional: Provide specific examples...',
            ),
            const SizedBox(height: 20),
            _buildFeedbackCard(
              title: 'Engagement',
              question: 'How engaging and interactive were the lessons?',
              rating: _engagementRating,
              onRatingUpdate: (rating) =>
                  setState(() => _engagementRating = rating),
              hintText: 'Optional: What made the classes engaging or not?',
            ),
            const SizedBox(height: 20),
            _buildFeedbackCard(
              title: 'Approachability',
              question:
                  'Did you feel comfortable approaching the teacher with questions?',
              rating: _approachabilityRating,
              onRatingUpdate: (rating) =>
                  setState(() => _approachabilityRating = rating),
              hintText: 'Optional: Any specific instances to share?',
            ),
            const SizedBox(height: 20),
            _buildAdditionalFeedbackCard(),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // In a real app, you would submit the feedback data here
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Thank you for your feedback!')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Submit Feedback',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!)),
      child: DropdownButtonFormField<String>(
        value: _selectedTeacher,
        hint: const Text('Select Teacher'),
        items: _teachers.map((String teacher) {
          return DropdownMenuItem<String>(
            value: teacher,
            child: Text(teacher),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            _selectedTeacher = newValue;
          });
        },
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildFeedbackCard({
    required String title,
    required String question,
    required int rating,
    required ValueChanged<int> onRatingUpdate,
    required String hintText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(question, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () => onRatingUpdate(index + 1),
                icon: Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors
                      .amber, // This is the standard yellow/gold for stars
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            maxLines: 2,
            decoration: InputDecoration(
              hintText: hintText,
              fillColor: Colors.grey[100],
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAdditionalFeedbackCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Additional Feedback',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Any other comments, suggestions, or praise?',
              fillColor: Colors.grey[100],
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          )
        ],
      ),
    );
  }
}
