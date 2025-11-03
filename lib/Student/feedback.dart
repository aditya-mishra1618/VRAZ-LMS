import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vraz_application/Student/service/feedback_service.dart';
import '../student_session_manager.dart';
import 'app_drawer.dart';
import 'feedback_form_screen.dart';
import 'models/feedback_model.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FeedbackService _feedbackService = FeedbackService();

  List<FeedbackFormAssignment>? _feedbackForms;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('🎬 DEBUG: FeedbackScreen initialized');
    print('📅 DEBUG: Current Date/Time: ${DateTime.now().toUtc().toIso8601String()}');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWithSessionManager();
    });
  }

  Future<void> _initializeWithSessionManager() async {
    print('🔧 DEBUG: Initializing FeedbackService with SessionManager');

    final sessionManager = Provider.of<SessionManager>(context, listen: false);

    if (!sessionManager.isLoggedIn) {
      print('❌ DEBUG: User is not logged in');
      setState(() {
        _errorMessage = 'Please login to view feedback forms';
      });
      return;
    }

    final authToken = sessionManager.authToken;

    if (authToken == null || authToken.isEmpty) {
      print('❌ DEBUG: Auth token is null or empty');
      setState(() {
        _errorMessage = 'Authentication token not found. Please login again.';
      });
      return;
    }

    print('✅ DEBUG: Auth token retrieved from SessionManager');
    print('🔐 DEBUG: Token preview: ${authToken.substring(0, 20)}...');

    _feedbackService.setAuthToken(authToken);
    await _fetchFeedbackForms();
  }

  Future<void> _fetchFeedbackForms() async {
    print('🔄 DEBUG: Starting to fetch feedback forms from API');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final forms = await _feedbackService.getMyFeedbackForms();

      print('✅ DEBUG: Successfully fetched ${forms.length} feedback forms');

      setState(() {
        _feedbackForms = forms;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ DEBUG: Error fetching feedback forms: $e');

      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _fetchFeedbackForms,
            ),
          ),
        );
      }
    }
  }

  Future<void> _openFeedbackForm(FeedbackFormAssignment formAssignment) async {
    print('📝 DEBUG: Opening feedback form: ${formAssignment.form.title}');

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FeedbackFormScreen(
          formAssignment: formAssignment,
          feedbackService: _feedbackService,
        ),
      ),
    );

    // Refresh list if feedback was submitted
    if (result == true) {
      print('✅ DEBUG: Feedback submitted, refreshing list');
      _fetchFeedbackForms();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4F8),
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.black54),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Feedback Forms',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _fetchFeedbackForms,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
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
            Text('Loading feedback forms...'),
          ],
        ),
      );
    }

    if (_errorMessage != null && _feedbackForms == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Error loading forms',
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
              onPressed: _fetchFeedbackForms,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_feedbackForms == null || _feedbackForms!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feedback_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No feedback forms available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new forms',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchFeedbackForms,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    // Separate forms into categories
    final availableForms = _feedbackForms!.where((f) => f.isAvailableNow()).toList();
    final submittedForms = _feedbackForms!.where((f) => f.hasSubmitted).toList();
    final expiredForms = _feedbackForms!.where((f) => f.isExpired() && !f.hasSubmitted).toList();
    final upcomingForms = _feedbackForms!.where((f) => f.isUpcoming()).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
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
                    'Your feedback helps us improve. Please be honest and constructive.',
                    style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Available Forms
          if (availableForms.isNotEmpty) ...[
            _buildSectionHeader('Available Now', availableForms.length, Colors.green),
            const SizedBox(height: 12),
            ...availableForms.map((form) => _buildFeedbackFormCard(form, true)),
            const SizedBox(height: 24),
          ],

          // Submitted Forms
          if (submittedForms.isNotEmpty) ...[
            _buildSectionHeader('Submitted', submittedForms.length, Colors.blue),
            const SizedBox(height: 12),
            ...submittedForms.map((form) => _buildFeedbackFormCard(form, false)),
            const SizedBox(height: 24),
          ],

          // Upcoming Forms
          if (upcomingForms.isNotEmpty) ...[
            _buildSectionHeader('Upcoming', upcomingForms.length, Colors.orange),
            const SizedBox(height: 12),
            ...upcomingForms.map((form) => _buildFeedbackFormCard(form, false)),
            const SizedBox(height: 24),
          ],

          // Expired Forms
          if (expiredForms.isNotEmpty) ...[
            _buildSectionHeader('Expired', expiredForms.length, Colors.red),
            const SizedBox(height: 12),
            ...expiredForms.map((form) => _buildFeedbackFormCard(form, false)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackFormCard(FeedbackFormAssignment form, bool isClickable) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (form.hasSubmitted) {
      statusColor = Colors.green;
      statusText = 'Submitted';
      statusIcon = Icons.check_circle;
    } else if (form.isExpired()) {
      statusColor = Colors.red;
      statusText = 'Expired';
      statusIcon = Icons.cancel;
    } else if (form.isUpcoming()) {
      statusColor = Colors.orange;
      statusText = 'Upcoming';
      statusIcon = Icons.schedule;
    } else if (form.isAvailableNow()) {
      statusColor = Colors.blue;
      statusText = 'Available';
      statusIcon = Icons.pending_actions;
    } else {
      statusColor = Colors.grey;
      statusText = 'Inactive';
      statusIcon = Icons.block;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isClickable ? statusColor.withOpacity(0.3) : Colors.grey.shade200,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: isClickable ? () => _openFeedbackForm(form) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      form.form.isFacultyReview()
                          ? Icons.person_outline
                          : Icons.feedback_outlined,
                      color: statusColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          form.form.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          form.form.description,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Due: ${_formatDate(form.endDate)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: form.form.isFacultyReview()
                          ? Colors.purple.shade50
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      form.form.isFacultyReview() ? 'Faculty Review' : 'General',
                      style: TextStyle(
                        color: form.form.isFacultyReview()
                            ? Colors.purple.shade700
                            : Colors.blue.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isClickable) ...[
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios, size: 14, color: statusColor),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}