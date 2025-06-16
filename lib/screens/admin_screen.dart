import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/theme_provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isLoading = false;
  String _statusMessage = '';
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
  }

  // Clear all events
  Future<void> _clearAllEvents() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Clearing all events...';
      _isSuccess = false;
    });

    try {
      final response = await http.delete(
        Uri.parse('http://192.168.178.248:3000/api/admin/events'),
      );

      setState(() {
        _isLoading = false;
        if (response.statusCode == 200) {
          _statusMessage = 'All events successfully cleared!';
          _isSuccess = true;
        } else {
          _statusMessage = 'Error clearing events: ${response.body}';
          _isSuccess = false;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Network error: $e';
        _isSuccess = false;
      });
    }
  }

  // Reset user preferences
  Future<void> _resetPreferences() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Resetting user preferences...';
      _isSuccess = false;
    });

    try {
      final response = await http.delete(
        Uri.parse('http://192.168.178.248:3000/api/admin/preferences'),
      );

      setState(() {
        _isLoading = false;
        if (response.statusCode == 200) {
          _statusMessage = 'Preferences successfully reset!';
          _isSuccess = true;
        } else {
          _statusMessage = 'Error resetting preferences: ${response.body}';
          _isSuccess = false;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Network error: $e';
        _isSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Panel',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    _statusMessage,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status message
                  if (_statusMessage.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: _isSuccess
                            ? Colors.green.withOpacity(isDarkMode ? 0.2 : 0.1)
                            : Colors.red.withOpacity(isDarkMode ? 0.2 : 0.1),
                        border: Border.all(
                          color: _isSuccess
                              ? Colors.green.withOpacity(0.5)
                              : Colors.red.withOpacity(0.5),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isSuccess ? Icons.check_circle : Icons.error,
                            color: _isSuccess ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _statusMessage,
                              style: TextStyle(
                                color: _isSuccess ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              setState(() {
                                _statusMessage = '';
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color: _isSuccess ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                    ),

                  // Data Management
                  _buildSectionTitle('Data Management'),
                  Card(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.clear_all,
                              color: Colors.red,
                            ),
                            title: const Text('Clear All Events'),
                            subtitle: const Text(
                              'Permanently delete all events from the database',
                            ),
                            contentPadding: EdgeInsets.zero,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_forever),
                              onPressed: () => _showConfirmationDialog(
                                context,
                                'Clear All Events',
                                'This will permanently delete all events from the database. This action cannot be undone. Are you sure you want to continue?',
                                _clearAllEvents,
                              ),
                              tooltip: 'Clear all events',
                              color: Colors.red,
                            ),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(
                              Icons.restart_alt,
                              color: Colors.orange,
                            ),
                            title: const Text('Reset User Preferences'),
                            subtitle: const Text(
                              'Reset all user preferences to default values',
                            ),
                            contentPadding: EdgeInsets.zero,
                            trailing: IconButton(
                              icon: const Icon(Icons.settings_backup_restore),
                              onPressed: () => _showConfirmationDialog(
                                context,
                                'Reset User Preferences',
                                'This will reset all user preferences to default values. This action cannot be undone. Are you sure you want to continue?',
                                _resetPreferences,
                              ),
                              tooltip: 'Reset preferences',
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // System Information
                  _buildSectionTitle('System Information'),
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                              'Backend API', 'http://192.168.178.248:3000'),
                          const SizedBox(height: 8),
                          _buildInfoRow('App Version', '1.0.0'),
                          const SizedBox(height: 8),
                          _buildInfoRow('Environment', 'Development'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).brightness == Brightness.dark
              ? ThemeProvider.notionGray
              : Colors.grey[700],
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[300]
                : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Future<void> _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
    Function() onConfirm,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }
}
