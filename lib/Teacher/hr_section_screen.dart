import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Import your necessary files (adjust paths as needed)
import '../teacher_session_manager.dart'; // For getting the auth token
import 'models/leave_application_model.dart'; // Import the updated model
import 'services/leave_api_service.dart'; // Import the new API service
import 'teacher_app_drawer.dart'; // Your app drawer

class HRSectionScreen extends StatefulWidget {
  const HRSectionScreen({super.key});

  @override
  State<HRSectionScreen> createState() => _HRSectionScreenState();
}

class _HRSectionScreenState extends State<HRSectionScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // API Service
  final LeaveApiService _leaveApiService = LeaveApiService();

  // State
  String? _authToken; // Store the token
  int _sickLeavesTaken = 0; // Will be calculated if needed
  int _casualLeavesTaken = 0; // Will be calculated if needed
  final int _totalSickLeaves = 10; // Assuming fixed totals for UI
  final int _totalCasualLeaves = 10;

  List<LeaveApplication> _leaveApplications = []; // Use the new model
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDeleting = false; // State for delete operation

  @override
  void initState() {
    super.initState();
    // Fetch token and initial data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeAndFetchLeaves();
    });
  }

  // Get token and perform initial fetch
  Future<void> _initializeAndFetchLeaves() async {
    // --- Using TeacherSessionManager ---
    final sessionManager = TeacherSessionManager();
    final session = await sessionManager.getSession();

    if (session == null || session['token'] == null) {
      print('[ERROR] No session found in HR screen.');
      if (mounted) {
        setState(() {
          _errorMessage =
              "Authentication token not found. Please log in again.";
          _isLoading = false;
        });
      }
      return;
    }
    _authToken = session['token'] as String;

    if (_authToken!.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = "Authentication token is empty. Please log in again.";
          _isLoading = false;
        });
      }
      return;
    }

    print('HR Screen: Auth Token found.');
    await _fetchLeaves();
  }

  // Fetch leaves from API
  Future<void> _fetchLeaves() async {
    if (_authToken == null) return; // Guard against null token

    // Don't show loading indicator if already deleting
    if (!_isDeleting) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final leaves = await _leaveApiService.getMyLeaves(_authToken!);
      if (mounted) {
        setState(() {
          _leaveApplications = leaves;
          // Optionally calculate balance after fetching
          _calculateLeaveBalance(leaves);
          _isLoading = false;
          _isDeleting = false; // Reset delete flag
        });
      }
    } catch (e) {
      print('Error setting leave state: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
          _isDeleting = false; // Reset delete flag on error too
        });
      }
    }
  }

  // --- (Optional) Calculate leave balance from fetched data ---
  void _calculateLeaveBalance(List<LeaveApplication> leaves) {
    int sickTaken = 0;
    int casualTaken = 0;
    for (var leave in leaves) {
      // Only count Approved leaves towards balance
      if (leave.status == 'APPROVED') {
        // Calculate duration inclusively (e.g., Nov 6 to Nov 6 is 1 day)
        int duration = leave.endDate.difference(leave.startDate).inDays + 1;
        if (leave.deductedAs == 'SICK') {
          // Use deductedAs
          sickTaken += duration;
        } else if (leave.deductedAs == 'CASUAL') {
          casualTaken += duration;
        }
      }
    }
    if (mounted) {
      // Check if still mounted before calling setState
      setState(() {
        _sickLeavesTaken = sickTaken;
        _casualLeavesTaken = casualTaken;
      });
    }
  }

  // Show Apply Leave Modal
  void _showApplyLeaveModal() {
    if (_authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cannot apply: Not authenticated.'),
            backgroundColor: Colors.red),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Pass the service, token and a refresh callback
        return ApplyLeaveModal(
          apiService: _leaveApiService, // Pass the service instance
          authToken: _authToken!, // Pass the token
          onApplied: () {
            // Refresh the list after successful application
            _fetchLeaves();
          },
        );
      },
    );
  }

  // --- Show Leave Details Dialog ---
  void _showLeaveDetailsDialog(LeaveApplication application) {
    showDialog(
      context: context,
      builder: (context) => LeaveDetailsDialog(
        application: application,
        onDelete: () async {
          // Call delete method when delete is confirmed
          Navigator.of(context).pop(); // Close the details dialog first
          await _deleteLeaveApplication(application.id);
        },
      ),
    );
  }

  // --- Delete Leave Application Method ---
  Future<void> _deleteLeaveApplication(int leaveId) async {
    if (_authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cannot delete: Not authenticated.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    // Optional: Show confirmation dialog before deleting
    bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Confirm Deletion'),
              content: const Text(
                  'Are you sure you want to delete this pending leave application? This action cannot be undone.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete',
                        style: TextStyle(color: Colors.red))),
              ],
            ));

    if (confirm != true) return; // User cancelled

    setState(() => _isDeleting = true); // Use specific flag for delete loading

    try {
      await _leaveApiService.deleteLeave(leaveId, _authToken!);

      // Re-fetch the list to ensure UI is consistent with backend
      await _fetchLeaves(); // Calls setState internally on completion

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Leave application deleted successfully.'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('Error deleting leave from UI: $e');
      if (mounted) {
        setState(() => _isDeleting = false); // Reset flag on error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to delete leave: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalLeavesTaken = _sickLeavesTaken + _casualLeavesTaken;
    int totalAvailableLeaves = _totalSickLeaves + _totalCasualLeaves;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4F8),
      drawer: const TeacherAppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.black54),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('HR Portal',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: Stack(
        // Use Stack to overlay deleting indicator
        children: [
          RefreshIndicator(
            onRefresh: _fetchLeaves,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTeacherInfoCard(),
                  const SizedBox(height: 24),
                  const Text('Leave Balance Overview',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildLeaveBalance(totalLeavesTaken, totalAvailableLeaves),
                  const SizedBox(height: 24),
                  const Text('Leave Application Status',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildLeaveStatusSection(),
                  const SizedBox(
                      height: 80), // Add padding at the bottom for FAB
                ],
              ),
            ),
          ),
          // --- Deleting Indicator Overlay ---
          if (_isDeleting)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Deleting leave...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showApplyLeaveModal,
        label: const Text('Apply for Leave'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
    );
  }

  // Section to handle loading/error/list display
  Widget _buildLeaveStatusSection() {
    // Show loading only if not deleting
    if (_isLoading && !_isDeleting) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: CircularProgressIndicator(),
      ));
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 8),
              Text('Error: $_errorMessage',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _fetchLeaves, child: const Text('Retry'))
            ],
          ),
        ),
      );
    }
    if (_leaveApplications.isEmpty && !_isLoading) {
      // Check loading flag too
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32.0),
          child: Text('No leave applications submitted yet.',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    // If data is available, build the list
    return _buildLeaveStatusList();
  }

  Widget _buildTeacherInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prof. Ramswaroop Sir', // Example Name
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
            // backgroundColor: Color(0xFFF0F4F8), // Use background image instead if needed
            backgroundImage: AssetImage('assets/profile.png'), // Placeholder
            onBackgroundImageError: null, // Handle image load error
            child: Icon(Icons.person,
                size: 30, color: Colors.grey), // Fallback Icon
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveBalance(int totalTaken, int totalAvailable) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLeaveIndicator('Sick Leaves Taken', _sickLeavesTaken,
            _totalSickLeaves, Colors.red),
        _buildLeaveIndicator('Casual Leaves Taken', _casualLeavesTaken,
            _totalCasualLeaves, Colors.blue),
        // Optional: Show available instead of total taken if desired
        // _buildLeaveIndicator('Total Available', totalAvailable - totalTaken, totalAvailable, Colors.purple),
      ],
    );
  }

  Widget _buildLeaveIndicator(String label, int value, int total, Color color) {
    double progress = total > 0 ? value / total : 0.0;
    int available = total - value; // Calculate available leaves

    return Column(
      children: [
        SizedBox(
          height: 80,
          width: 80,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: progress, // Represents portion taken
                strokeWidth: 7,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Center(
                  child: Text('$value/$total', // Show Taken / Total
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold))), // Slightly smaller font
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            textAlign: TextAlign.center, // Center label text
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        Text('Available: $available', // Show available leaves
            style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  // Uses the _leaveApplications state variable
  Widget _buildLeaveStatusList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _leaveApplications.length,
      itemBuilder: (context, index) {
        final application = _leaveApplications[index];
        return _buildLeaveStatusCard(application); // Pass the API data model
      },
    );
  }

  // Takes the updated LeaveApplication model
  Widget _buildLeaveStatusCard(LeaveApplication application) {
    Color statusColor;
    String statusText = application.displayStatus; // Use helper getter
    switch (application.status) {
      // Use API status
      case 'APPROVED':
        statusColor = Colors.green;
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        break;
      default: // PENDING
        statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05), // Softer shadow
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () =>
            _showLeaveDetailsDialog(application), // Show details on tap
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          title: Text(
            application.displayLeaveType, // Use helper getter
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            // Use dateRangeDisplay helper and API reason
            '${application.dateRangeDisplay}\nReason: ${application.reason}',
            style: TextStyle(color: Colors.grey[700], fontSize: 12),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          isThreeLine: true,
        ),
      ),
    );
  }
} // End _HRSectionScreenState

// --- Apply Leave Modal ---
class ApplyLeaveModal extends StatefulWidget {
  final LeaveApiService apiService;
  final String authToken;
  final VoidCallback onApplied;

  const ApplyLeaveModal({
    super.key,
    required this.apiService,
    required this.authToken,
    required this.onApplied,
  });

  @override
  State<ApplyLeaveModal> createState() => _ApplyLeaveModalState();
}

class _ApplyLeaveModalState extends State<ApplyLeaveModal> {
  String? _selectedLeaveTypeApiValue; // Store "SICK" or "CASUAL"
  DateTime? _startDate;
  DateTime? _endDate;

  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final now = DateTime.now();
    final initialPickerDate = isStartDate
        ? (_startDate ?? now) // Use selected start date or today
        : (_endDate ??
            _startDate ??
            now); // Use selected end date, or start date, or today

    // Define the range allowed for selection
    // Allow applying for leave starting today or in the future
    final firstAllowedDate = isStartDate
        ? DateTime(now.year, now.month, now.day) // Today
        : _startDate ??
            DateTime(now.year, now.month, now.day); // 'To' must be >= 'From'

    final lastAllowedDate =
        DateTime(now.year + 1, now.month, now.day); // Approx 1 year in future

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialPickerDate.isBefore(firstAllowedDate)
          ? firstAllowedDate
          : initialPickerDate, // Ensure initial is within range
      firstDate: firstAllowedDate,
      lastDate: lastAllowedDate,
    );

    if (picked != null) {
      setState(() {
        final formattedDate = DateFormat('MMM dd, yyyy').format(picked);
        if (isStartDate) {
          _startDate = picked;
          _startController.text = formattedDate;
          // If 'To' date is before new 'From' date, reset 'To' date
          if (_endDate != null && _startDate!.isAfter(_endDate!)) {
            _endDate = null; // Reset end date
            _endController.text = ''; // Clear end date text field
          }
          // If 'To' date is null, set it to the same as 'From' date initially
          else if (_endDate == null) {
            _endDate = _startDate;
            _endController.text = formattedDate;
          }
        } else {
          // isEndDate
          // Ensure the selected end date is not before the start date
          if (_startDate != null && picked.isBefore(_startDate!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('End date cannot be before start date.'),
                  backgroundColor: Colors.orange),
            );
            return; // Don't update if invalid
          }
          _endDate = picked;
          _endController.text = formattedDate;
        }
      });
    }
  }

  Future<void> _submitLeaveApplication() async {
    if (_selectedLeaveTypeApiValue == null ||
        _startDate == null ||
        _endDate == null ||
        _reasonController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please fill all fields.');
      return;
    }

    // Add check: End date cannot be before Start date
    if (_endDate!.isBefore(_startDate!)) {
      setState(() => _errorMessage = 'End date cannot be before start date.');
      return;
    }

    // --- Add Debug Prints ---
    print('--- Submitting Leave ---');
    print('Type: $_selectedLeaveTypeApiValue');
    print('Reason: ${_reasonController.text.trim()}');
    print('Start Date (Local): $_startDate');
    print('End Date (Local): $_endDate');
    print('Auth Token: ${widget.authToken.substring(0, 10)}...');
    print('-----------------------');
    // --- End Debug Prints ---

    setState(() {
      _isSubmitting = true;
      _errorMessage = null; // Clear previous error
    });

    try {
      // Call the API service passed from the parent
      await widget.apiService.applyLeave(
        leaveType: _selectedLeaveTypeApiValue!, // Send "SICK" or "CASUAL"
        reason: _reasonController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        authToken: widget.authToken,
      );

      // If successful, call the onApplied callback and close
      if (mounted) {
        widget.onApplied(); // Notify parent to refresh
        Navigator.pop(context); // Close the modal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave application submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error in modal submit: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Adjust padding based on keyboard visibility
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20.0), // Padding inside the container
        decoration: const BoxDecoration(
          color: Color(0xFFF0F4F8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          // Makes content scrollable
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Apply for Leave',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed:
                        _isSubmitting ? null : () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 20),
              // Use API values "SICK", "CASUAL" but display friendly names
              _buildDropdown('Leave Type', 'Select Leave Type',
                  {'Sick Leave': 'SICK', 'Casual Leave': 'CASUAL'}),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _buildDatePicker('From', _startController,
                          () => _selectDate(context, true))),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildDatePicker('To', _endController,
                          () => _selectDate(context, false))),
                ],
              ),
              const SizedBox(height: 16),
              _buildReasonField(),
              // Display error message if any
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitLeaveApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey.shade400,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ))
                      : const Text('Apply Leave',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String hint, Map<String, String> items) {
    // ... remains the same
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
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                )
              ]),
          child: DropdownButtonFormField<String>(
            value: _selectedLeaveTypeApiValue,
            hint: Text(hint, style: TextStyle(color: Colors.grey[600])),
            items: items.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.value,
                child: Text(entry.key),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() => _selectedLeaveTypeApiValue = newValue);
            },
            decoration: const InputDecoration(border: InputBorder.none),
            isExpanded: true, // Make dropdown take full width
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(
      String label, TextEditingController controller, VoidCallback onTap) {
    // ... remains the same
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
            hintText: 'Select Date',
            filled: true,
            fillColor: Colors.white,
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              // Add border when not focused
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              // Add border when focused
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blueAccent),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildReasonField() {
    // ... remains the same
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reason', style: TextStyle(fontWeight: FontWeight.w500)),
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
            enabledBorder: OutlineInputBorder(
              // Add border when not focused
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              // Add border when focused
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blueAccent),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
        ),
      ],
    );
  }
} // End _ApplyLeaveModalState

// --- Leave Details Dialog Widget ---
class LeaveDetailsDialog extends StatelessWidget {
  final LeaveApplication application;
  final VoidCallback onDelete; // Callback for delete action

  const LeaveDetailsDialog({
    super.key,
    required this.application,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (application.status) {
      case 'APPROVED':
        statusColor = Colors.green;
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange; // PENDING
    }

    // Only show delete button if status is PENDING
    final bool canDelete = application.status == 'PENDING';

    return AlertDialog(
      title: Text(application.displayLeaveType),
      content: SingleChildScrollView(
        // Make content scrollable if long
        child: ListBody(
          children: <Widget>[
            _buildDetailRow('Status:', application.displayStatus, statusColor),
            const SizedBox(height: 10),
            _buildDetailRow('Dates:', application.dateRangeDisplay),
            const SizedBox(height: 10),
            _buildDetailRow('Reason:', application.reason),
            const SizedBox(height: 10),
            _buildDetailRow(
                'Deducted As:',
                application.deductedAs.isNotEmpty
                    ? application.deductedAs
                    : 'N/A'),
            const SizedBox(height: 10),
            // Calculate duration
            _buildDetailRow('Duration:',
                '${application.endDate.difference(application.startDate).inDays + 1} day(s)'),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        // Conditionally show delete button
        if (canDelete)
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: onDelete, // Call the provided callback
          ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
            width: 90, // Allocate fixed width for label
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: valueColor ?? Colors.black87),
          ),
        ),
      ],
    );
  }
} // End LeaveDetailsDialog
