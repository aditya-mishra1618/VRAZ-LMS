import 'package:flutter/material.dart';
import 'package:vraz_application/Student/service/feedback_service.dart';
import 'models/feedback_model.dart';
import 'models/faculty_model.dart';

class FeedbackFormScreen extends StatefulWidget {
  final FeedbackFormAssignment formAssignment;
  final FeedbackService feedbackService;

  const FeedbackFormScreen({
    super.key,
    required this.formAssignment,
    required this.feedbackService,
  });

  @override
  State<FeedbackFormScreen> createState() => _FeedbackFormScreenState();
}

class _FeedbackFormScreenState extends State<FeedbackFormScreen> {
  FeedbackFormDetails? _formDetails;
  List<FacultyModel>? _facultyList;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSubmitting = false;

  // For GENERAL forms
  final Map<String, TextEditingController> _answerControllers = {};

  // For FACULTY_REVIEW forms
  final Map<String, int> _facultyRatings = {}; // facultyId -> rating
  final Map<String, TextEditingController> _facultyComments = {}; // facultyId -> comment

  @override
  void initState() {
    super.initState();
    print('🎬 DEBUG: FeedbackFormScreen initialized');
    print('📝 DEBUG: Form Title: ${widget.formAssignment.form.title}');
    print('📝 DEBUG: Form Type: ${widget.formAssignment.form.formType}');
    _loadFormData();
  }

  @override
  void dispose() {
    // Clean up controllers
    for (var controller in _answerControllers.values) {
      controller.dispose();
    }
    for (var controller in _facultyComments.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadFormData() async {
    print('🔄 DEBUG: Loading form data...');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get form details
      final formDetails = await widget.feedbackService.getFormDetails(widget.formAssignment.id);
      print('✅ DEBUG: Form details loaded: ${formDetails.form.title}');

      setState(() {
        _formDetails = formDetails;
      });

      // If GENERAL form, initialize answer controllers
      if (formDetails.form.isGeneralForm() && formDetails.form.questions != null) {
        print('📝 DEBUG: Initializing ${formDetails.form.questions!.length} answer controllers');
        for (int i = 0; i < formDetails.form.questions!.length; i++) {
          _answerControllers['q${i + 1}'] = TextEditingController();
        }
      }

      // If FACULTY_REVIEW form, load faculty list
      if (formDetails.form.isFacultyReview()) {
        print('👥 DEBUG: Loading faculty list...');
        final faculties = await widget.feedbackService.getBatchFaculty();
        print('✅ DEBUG: Loaded ${faculties.length} faculty members');

        setState(() {
          _facultyList = faculties;
        });

        // Initialize faculty comment controllers
        for (var faculty in faculties) {
          _facultyComments[faculty.id] = TextEditingController();
          _facultyRatings[faculty.id] = 0; // Default no rating
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ DEBUG: Error loading form data: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _submitFeedback() async {
    print('📤 DEBUG: ========== FEEDBACK SUBMISSION ==========');
    print('📤 DEBUG: Form ID: ${widget.formAssignment.id}');
    print('📤 DEBUG: Form Type: ${_formDetails!.form.formType}');
    print('📤 DEBUG: Submission Time: ${DateTime.now().toUtc().toIso8601String()}');

    // Validation
    if (_formDetails!.form.isGeneralForm()) {
      // Check if at least one answer is provided
      bool hasAnswer = false;
      for (var controller in _answerControllers.values) {
        if (controller.text.trim().isNotEmpty) {
          hasAnswer = true;
          break;
        }
      }

      if (!hasAnswer) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please answer at least one question'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    } else if (_formDetails!.form.isFacultyReview()) {
      // Check if at least one faculty has rating
      bool hasRating = _facultyRatings.values.any((rating) => rating > 0);

      if (!hasRating) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please rate at least one faculty member'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_formDetails!.form.isGeneralForm()) {
        // Submit GENERAL feedback
        final answers = <String, String>{};
        _answerControllers.forEach((key, controller) {
          if (controller.text.trim().isNotEmpty) {
            answers[key] = controller.text.trim();
          }
        });

        print('📝 DEBUG: General answers: $answers');

        await widget.feedbackService.submitGeneralFeedback(
          formAssignmentId: widget.formAssignment.id,
          answers: answers,
        );
      } else {
        // Submit FACULTY_REVIEW feedback
        final facultyFeedback = <FacultyFeedbackSubmission>[];

        _facultyRatings.forEach((facultyId, rating) {
          if (rating > 0) {
            facultyFeedback.add(
              FacultyFeedbackSubmission(
                teacherId: facultyId,
                rating: rating,
                comment: _facultyComments[facultyId]?.text.trim() ?? '',
              ),
            );
          }
        });

        print('📝 DEBUG: Faculty feedback count: ${facultyFeedback.length}');

        await widget.feedbackService.submitFacultyFeedback(
          formAssignmentId: widget.formAssignment.id,
          facultyFeedback: facultyFeedback,
        );
      }

      setState(() {
        _isSubmitting = false;
      });

      print('✅ DEBUG: Feedback submitted successfully!');
      print('📤 DEBUG: ========================================');

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback! ✅'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Return to list with success flag
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print('❌ DEBUG: Submission failed: $e');

      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.formAssignment.form.title,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildBody(),
      bottomNavigationBar: _formDetails != null && !_isLoading
          ? _buildSubmitButton()
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading form...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Error loading form',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadFormData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_formDetails!.form.isGeneralForm()) {
      return _buildGeneralFeedbackForm();
    } else {
      return _buildFacultyReviewForm();
    }
  }

  Widget _buildGeneralFeedbackForm() {
    final questions = _formDetails!.form.questions ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade800),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formDetails!.form.description,
                    style: TextStyle(color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Questions
          ...List.generate(questions.length, (index) {
            final question = questions[index];
            final questionKey = 'q${index + 1}';

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Q${index + 1}',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          question.text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _answerControllers[questionKey],
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Type your answer here...',
                      fillColor: Colors.grey[100],
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFacultyReviewForm() {
    if (_facultyList == null || _facultyList!.isEmpty) {
      return const Center(
        child: Text('No faculty members found'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.star_outline, color: Colors.purple.shade800),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formDetails!.form.description,
                    style: TextStyle(color: Colors.purple.shade900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Rate Your Faculty',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap stars to rate (1-5) and add optional comments',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 20),

          // Faculty List
          ..._facultyList!.map((faculty) => _buildFacultyReviewCard(faculty)),
        ],
      ),
    );
  }

  Widget _buildFacultyReviewCard(FacultyModel faculty) {
    final rating = _facultyRatings[faculty.id] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rating > 0 ? Colors.purple.shade200 : Colors.grey.shade200,
          width: rating > 0 ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Faculty Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.purple.shade100,
                backgroundImage: faculty.hasPhoto() ? NetworkImage(faculty.photoUrl) : null,
                child: !faculty.hasPhoto()
                    ? Text(
                  faculty.getInitials(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      faculty.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (rating > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        _getRatingText(rating),
                        style: TextStyle(
                          color: _getRatingColor(rating),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Star Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                  setState(() {
                    _facultyRatings[faculty.id] = index + 1;
                  });
                  print('⭐ DEBUG: Rated ${faculty.fullName}: ${index + 1} stars');
                },
                icon: Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: index < rating ? Colors.amber : Colors.grey,
                  size: 36,
                ),
              );
            }),
          ),

          if (rating > 0) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _facultyComments[faculty.id],
              enabled: !_isSubmitting,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add your comments (optional)...',
                fillColor: Colors.grey[100],
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.purple.shade300, width: 2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitFeedback,
          style: ElevatedButton.styleFrom(
            backgroundColor: _formDetails!.form.isFacultyReview()
                ? Colors.purple
                : Colors.blueAccent,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          child: _isSubmitting
              ? const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Submitting...',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ],
          )
              : const Text(
            'Submit Feedback',
            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 5:
        return 'Excellent!';
      case 4:
        return 'Very Good';
      case 3:
        return 'Good';
      case 2:
        return 'Fair';
      case 1:
        return 'Needs Improvement';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    if (rating >= 4) return Colors.green;
    if (rating == 3) return Colors.orange;
    return Colors.red;
  }
}