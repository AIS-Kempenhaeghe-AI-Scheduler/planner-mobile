import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../theme/theme_provider.dart';
import 'calendar/my_schedule_page.dart';
import 'email_entry_screen.dart';

class NewLoginScreen extends StatefulWidget {
  final String? prefilledEmail;

  const NewLoginScreen({super.key, this.prefilledEmail});

  @override
  State<NewLoginScreen> createState() => _NewLoginScreenState();
}

class _NewLoginScreenState extends State<NewLoginScreen>
    with TickerProviderStateMixin {
  final _pinController = TextEditingController();
  String _enteredPin = '';
  String _username = '';
  String _userEmail = '';
  List<Map<String, dynamic>> _users = [];
  int _selectedUserIndex = 0;
  bool _isLoggingIn = false;
  bool _showError = false;

  late AnimationController _animationController;
  late AnimationController _errorController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<Offset> _errorShakeAnimation;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _errorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _errorShakeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.05, 0),
    ).animate(CurvedAnimation(
      parent: _errorController,
      curve: Curves.elasticIn,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _animationController.dispose();
    _errorController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      final users = await authService.getUsers();

      setState(() {
        _users = users;
        if (users.isNotEmpty) {
          if (widget.prefilledEmail != null &&
              widget.prefilledEmail!.isNotEmpty) {
            final userIndex = users
                .indexWhere((user) => user['email'] == widget.prefilledEmail);
            if (userIndex != -1) {
              _selectedUserIndex = userIndex;
            } else {
              // User not found in the list, but we still have the email
              // Use the first user for display but keep the prefilled email for login
              _selectedUserIndex = 0;
            }
          }
          _updateSelectedUser();
        }

        // Always ensure we have the email for login, even if user loading fails
        if (widget.prefilledEmail != null &&
            widget.prefilledEmail!.isNotEmpty) {
          _userEmail = widget.prefilledEmail!;
          if (_username.isEmpty) {
            _username = 'User';
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      // Fallback: use prefilled email even if user loading fails
      if (widget.prefilledEmail != null && widget.prefilledEmail!.isNotEmpty) {
        setState(() {
          _userEmail = widget.prefilledEmail!;
          _username = 'User';
        });
      }
    }
  }

  void _updateSelectedUser() {
    if (_users.isNotEmpty && _selectedUserIndex < _users.length) {
      final user = _users[_selectedUserIndex];
      setState(() {
        _username = user['name'] ?? 'User';
        _userEmail = user['email'] ?? '';
      });
    }
  }

  void _addDigit(String digit) {
    if (_enteredPin.length < 6 && !_isLoggingIn) {
      setState(() {
        _enteredPin += digit;
        _showError = false;
      });

      if (_enteredPin.length == 6) {
        _login();
      }
    }
  }

  void _removeDigit() {
    if (_enteredPin.isNotEmpty && !_isLoggingIn) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _showError = false;
      });
    }
  }

  void _clearPin() {
    if (!_isLoggingIn) {
      setState(() {
        _enteredPin = '';
        _showError = false;
      });
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoggingIn = true;
      _showError = false;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Use email as username since backend searches by email
      final username =
          _userEmail.isNotEmpty ? _userEmail : widget.prefilledEmail ?? '';
      debugPrint('LOGIN: Attempting login with email: $username');

      if (username.isEmpty) {
        throw Exception('No email available for login');
      }

      final success = await authService.login(username, _enteredPin);

      if (!mounted) return;

      if (success) {
        // Save login state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('savedEmail', username);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MySchedulePage()),
        );
      } else {
        _showLoginError();
      }
    } catch (e) {
      debugPrint('Login failed: $e');
      if (mounted) {
        _showLoginError();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  void _showLoginError() {
    setState(() {
      _showError = true;
      _enteredPin = '';
    });
    _errorController.forward().then((_) {
      _errorController.reverse();
    });
  }

  void _showUserSelectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildUserSelectionSheet(),
    );
  }

  Widget _buildUserSelectionSheet() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFE5E5E5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode
                      ? const Color(0xFF2D2D2D)
                      : const Color(0xFFE5E5E5),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeProvider.notionBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.people_outline,
                    color: ThemeProvider.notionBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Select Your Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color:
                          isDarkMode ? Colors.white : ThemeProvider.notionBlack,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: isDarkMode
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // User list
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              shrinkWrap: true,
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                final isSelected = index == _selectedUserIndex;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ThemeProvider.notionBlue.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(
                            color: ThemeProvider.notionBlue.withOpacity(0.3))
                        : null,
                  ),
                  child: ListTile(
                    onTap: () {
                      setState(() {
                        _selectedUserIndex = index;
                        _enteredPin = '';
                        _showError = false;
                      });
                      _updateSelectedUser();
                      Navigator.of(context).pop();
                    },
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor:
                          ThemeProvider.notionBlue.withOpacity(0.1),
                      child: Text(
                        (user['name'] ?? 'U').isNotEmpty
                            ? user['name'][0].toUpperCase()
                            : "U",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ThemeProvider.notionBlue,
                        ),
                      ),
                    ),
                    title: Text(
                      user['name'] ?? 'User',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode
                            ? Colors.white
                            : ThemeProvider.notionBlack,
                      ),
                    ),
                    subtitle: user['email'] != null && user['email'].isNotEmpty
                        ? Text(
                            user['email'],
                            style: TextStyle(
                              fontSize: 13,
                              color: isDarkMode
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF6B7280),
                            ),
                          )
                        : null,
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: ThemeProvider.notionBlue,
                            size: 20,
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? ThemeProvider.notionBlack : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SlideTransition(
              position: _errorShakeAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo section
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF1A1A1A)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDarkMode
                                  ? const Color(0xFF2D2D2D)
                                  : const Color(0xFFE5E5E5),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(isDarkMode ? 0.3 : 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/logo/Kempenhaeghe_logo.png',
                            width: 160,
                            height: 50,
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // User selection card
                        InkWell(
                          onTap: _showUserSelectionDialog,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF1A1A1A)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDarkMode
                                    ? const Color(0xFF2D2D2D)
                                    : const Color(0xFFE5E5E5),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(isDarkMode ? 0.2 : 0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor:
                                      ThemeProvider.notionBlue.withOpacity(0.1),
                                  child: Text(
                                    _username.isNotEmpty
                                        ? _username[0].toUpperCase()
                                        : "U",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: ThemeProvider.notionBlue,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome back',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDarkMode
                                              ? const Color(0xFF9CA3AF)
                                              : const Color(0xFF6B7280),
                                        ),
                                      ),
                                      Text(
                                        _username,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isDarkMode
                                              ? Colors.white
                                              : ThemeProvider.notionBlack,
                                        ),
                                      ),
                                      if (_userEmail.isNotEmpty)
                                        Text(
                                          _userEmail,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDarkMode
                                                ? const Color(0xFF9CA3AF)
                                                : const Color(0xFF6B7280),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.expand_more,
                                  color: isDarkMode
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF6B7280),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // PIN section
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF1A1A1A)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDarkMode
                                  ? const Color(0xFF2D2D2D)
                                  : const Color(0xFFE5E5E5),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(isDarkMode ? 0.2 : 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Header
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: ThemeProvider.notionBlue
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.lock_outline,
                                      size: 20,
                                      color: ThemeProvider.notionBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Enter your PIN',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isDarkMode
                                                ? Colors.white
                                                : ThemeProvider.notionBlack,
                                          ),
                                        ),
                                        Text(
                                          'Enter your 6-digit PIN to continue',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDarkMode
                                                ? const Color(0xFF9CA3AF)
                                                : const Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // PIN display
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: List.generate(6, (index) {
                                  final isFilled = index < _enteredPin.length;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isFilled
                                          ? ThemeProvider.notionBlue
                                          : (isDarkMode
                                              ? const Color(0xFF111111)
                                              : const Color(0xFFF8F9FA)),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isFilled
                                            ? ThemeProvider.notionBlue
                                            : (isDarkMode
                                                ? const Color(0xFF2D2D2D)
                                                : const Color(0xFFE5E5E5)),
                                        width: 2,
                                      ),
                                    ),
                                    child: _isLoggingIn && isFilled
                                        ? const Center(
                                            child: SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            ),
                                          )
                                        : isFilled
                                            ? const Center(
                                                child: Icon(
                                                  Icons.circle,
                                                  color: Colors.white,
                                                  size: 12,
                                                ),
                                              )
                                            : null,
                                  );
                                }),
                              ),

                              if (_showError) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFEF4444)
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Color(0xFFEF4444),
                                        size: 16,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Incorrect PIN. Please try again.',
                                          style: TextStyle(
                                            color: Color(0xFFEF4444),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              // Keypad
                              _buildKeypad(isDarkMode),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Back to email button
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const EmailEntryScreen()),
                            );
                          },
                          child: Text(
                            'Use different email',
                            style: TextStyle(
                              color: isDarkMode
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF6B7280),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(bool isDarkMode) {
    return Column(
      children: [
        // Numbers 1-3
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3']
              .map((digit) => _buildKeypadButton(digit, isDarkMode))
              .toList(),
        ),
        const SizedBox(height: 12),
        // Numbers 4-6
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6']
              .map((digit) => _buildKeypadButton(digit, isDarkMode))
              .toList(),
        ),
        const SizedBox(height: 12),
        // Numbers 7-9
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9']
              .map((digit) => _buildKeypadButton(digit, isDarkMode))
              .toList(),
        ),
        const SizedBox(height: 12),
        // Bottom row: Clear, 0, Backspace
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadButton('⌫', isDarkMode,
                isSpecial: true, onTap: _removeDigit),
            _buildKeypadButton('0', isDarkMode),
            _buildKeypadButton('✕', isDarkMode,
                isSpecial: true, onTap: _clearPin),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String label, bool isDarkMode,
      {bool isSpecial = false, VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoggingIn ? null : (onTap ?? () => _addDigit(label)),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color:
                isDarkMode ? const Color(0xFF111111) : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDarkMode
                  ? const Color(0xFF2D2D2D)
                  : const Color(0xFFE5E5E5),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isSpecial ? 18 : 20,
                fontWeight: FontWeight.w600,
                color: isSpecial
                    ? (isDarkMode
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280))
                    : (isDarkMode ? Colors.white : ThemeProvider.notionBlack),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
