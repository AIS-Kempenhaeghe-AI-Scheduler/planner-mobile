import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../theme/theme_provider.dart';
import 'calendar/my_schedule_page.dart';
import 'email_entry_screen.dart';
import 'dart:math' as math;

class LoginScreen extends StatefulWidget {
  final String? prefilledEmail;

  const LoginScreen({super.key, this.prefilledEmail});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _pinController = TextEditingController();
  String _enteredPin = '';
  String _username = '';
  String _userEmail = '';
  List<Map<String, dynamic>> _users = [];
  int _selectedUserIndex = 0;
  bool _isLoggingIn = false;
  bool _showError = false;

  // Animation controllers
  late AnimationController _pageController;
  late AnimationController _pinEntryController;
  late AnimationController _loginController;
  late AnimationController _errorController;
  late AnimationController _switchUserController;
  late AnimationController _backgroundAnimController;

  // Animations
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _pinBoxAnimation;
  late Animation<double> _keypadScaleAnimation;
  late Animation<double> _keypadOpacityAnimation;
  late Animation<double> _buttonPressAnimation;
  late Animation<Offset> _errorShakeAnimation;
  late Animation<double> _successIconAnimation;
  late Animation<Offset> _switchUserSlideAnimation;
  late Animation<double> _switchUserOpacityAnimation;

  // Individual PIN dot animations
  late List<AnimationController> _dotAnimControllers;
  late List<Animation<double>> _dotAnimations;
  late List<Animation<double>> _dotColorAnimations;

  // Wave animation
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Background animation with continuous subtle movement
    _backgroundAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_backgroundAnimController);

    _backgroundAnimController.repeat();

    // Initial page entrance animation
    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 40,
      ),
    ]).animate(CurvedAnimation(
      parent: _pageController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    ));

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    _pinBoxAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageController,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOutBack),
    ));

    _keypadScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack),
    ));

    _keypadOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    ));

    // Animation for PIN entry
    _pinEntryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _buttonPressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _pinEntryController,
      curve: Curves.easeInOut,
    ));

    // User switching animation
    _switchUserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _switchUserSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.7),
    ).animate(CurvedAnimation(
      parent: _switchUserController,
      curve: Curves.easeInOut,
    ));

    _switchUserOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _switchUserController,
      curve: Curves.easeInOut,
    ));

    // Individual dot animations
    _dotAnimControllers = List.generate(
        6,
        (index) => AnimationController(
              vsync: this,
              duration: const Duration(milliseconds: 250),
            ));

    _dotAnimations = _dotAnimControllers.map((controller) {
      return Tween<double>(
        begin: 1.0,
        end: 1.4,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      ));
    }).toList();

    _dotColorAnimations = _dotAnimControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ));
    }).toList();

    // Login animation
    _loginController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _successIconAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 20,
      ),
    ]).animate(CurvedAnimation(
      parent: _loginController,
      curve: Curves.easeInOutQuart,
    ));

    // Error animation
    _errorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _errorShakeAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset.zero, end: const Offset(-0.05, 0)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
            begin: const Offset(-0.05, 0), end: const Offset(0.05, 0)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
            begin: const Offset(0.05, 0), end: const Offset(-0.05, 0)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
            begin: const Offset(-0.05, 0), end: const Offset(0.05, 0)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero),
        weight: 20,
      ),
    ]).animate(CurvedAnimation(
      parent: _errorController,
      curve: Curves.easeOut,
    ));

    // Start the initial page animation
    _pageController.forward();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pageController.dispose();
    _pinEntryController.dispose();
    _loginController.dispose();
    _errorController.dispose();
    _switchUserController.dispose();
    _backgroundAnimController.dispose();
    for (final controller in _dotAnimControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      final users = await authService.getUsers();
      setState(() {
        _users = users;
        if (users.isNotEmpty) {
          // If there's a prefilled email, try to find and select that user
          if (widget.prefilledEmail != null &&
              widget.prefilledEmail!.isNotEmpty) {
            final userIndex = users
                .indexWhere((user) => user['email'] == widget.prefilledEmail);
            if (userIndex != -1) {
              _selectedUserIndex = userIndex;
            }
          }
          _username = users[_selectedUserIndex]['name'] ?? 'User';
          _userEmail = users[_selectedUserIndex]['email'] ?? '';
        } else {
          // No users found, but allow PIN entry for the entered email
          if (widget.prefilledEmail != null &&
              widget.prefilledEmail!.isNotEmpty) {
            _users = [
              {
                'id': 'temp',
                'name': 'User',
                'email': widget.prefilledEmail,
              }
            ];
            _selectedUserIndex = 0;
            _username = 'User';
            _userEmail = widget.prefilledEmail!;
          } else {
            // No email, redirect to email entry
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const EmailEntryScreen(),
                ),
              );
            }
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      // Network error or backend unavailable, fallback to PIN entry for prefilled email
      setState(() {
        if (widget.prefilledEmail != null &&
            widget.prefilledEmail!.isNotEmpty) {
          _users = [
            {
              'id': 'temp',
              'name': 'User',
              'email': widget.prefilledEmail,
            }
          ];
          _selectedUserIndex = 0;
          _username = 'User';
          _userEmail = widget.prefilledEmail!;
        } else {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const EmailEntryScreen(),
              ),
            );
          }
        }
      });
    }
  }

  void _addDigit(String digit) {
    if (_enteredPin.length < 6 && !_isLoggingIn) {
      _pinEntryController.forward().then((_) => _pinEntryController.reverse());

      setState(() {
        _enteredPin += digit;
      });

      // Animate the newly filled dot
      final dotIndex = _enteredPin.length - 1;
      _dotAnimControllers[dotIndex].forward(from: 0.0);

      // Auto-login when all 6 digits are entered
      if (_enteredPin.length == 6) {
        _login();
      }
    }
  }

  void _removeLastDigit() {
    if (_enteredPin.isNotEmpty && !_isLoggingIn) {
      _pinEntryController.forward().then((_) => _pinEntryController.reverse());
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _login() async {
    if (_enteredPin.length == 6 && !_isLoggingIn) {
      setState(() {
        _isLoggingIn = true;
      });

      final authService = Provider.of<AuthService>(context, listen: false);

      if (_users.isEmpty) {
        setState(() {
          _isLoggingIn = false;
        });
        return;
      }

      final selectedUser = _users[_selectedUserIndex];
      final userEmail = selectedUser['email'];

      final success = await authService.login(
        userEmail,
        _enteredPin,
      );

      if (success && mounted) {
        // Play success animation and navigate
        _loginController.forward().then((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const MySchedulePage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          }
        });
      } else {
        // Reset PIN and show error animation
        setState(() {
          _enteredPin = '';
          _isLoggingIn = false;
          _showError = true;
        });

        _errorController.forward().then((_) {
          _errorController.reset();

          // Hide error message after delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _showError = false;
              });
            }
          });
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authService.error ?? 'Invalid PIN'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(10),
            ),
          );
        }
      }
    }
  }

  void _showUserSelectionDialog() {
    if (_users.isEmpty || _isLoggingIn) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 350, maxHeight: 400),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E88E5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_circle,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Select Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // User list
                Flexible(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final isSelected = index == _selectedUserIndex;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1E88E5).withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(
                                  color: const Color(0xFF1E88E5), width: 2)
                              : null,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E88E5).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                (user['name'] ?? 'U').isNotEmpty
                                    ? user['name'][0].toUpperCase()
                                    : "U",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E88E5),
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            user['name'] ?? 'User',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF1E88E5)
                                  : Colors.black87,
                            ),
                          ),
                          subtitle:
                              user['email'] != null && user['email'].isNotEmpty
                                  ? Text(
                                      user['email'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isSelected
                                            ? const Color(0xFF1E88E5)
                                                .withOpacity(0.7)
                                            : Colors.grey[600],
                                      ),
                                    )
                                  : null,
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF1E88E5),
                                  size: 24,
                                )
                              : null,
                          onTap: () {
                            if (index != _selectedUserIndex) {
                              setState(() {
                                _selectedUserIndex = index;
                                _username = _users[_selectedUserIndex]
                                        ['name'] ??
                                    'User';
                                _userEmail =
                                    _users[_selectedUserIndex]['email'] ?? '';
                                _enteredPin = '';
                              });
                            }
                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    },
                  ),
                ),
                // Footer with user count
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _users.length > 1
                        ? '${_users.length} accounts available'
                        : 'Only one account available',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pageController,
        _pinEntryController,
        _loginController,
        _errorController,
        _switchUserController,
        _backgroundAnimController,
      ]),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: isDarkMode ? ThemeProvider.notionBlack : const Color(0xFFFAFAFA),
          body: Stack(
            children: [
              // Subtle background pattern
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? ThemeProvider.notionBlack : const Color(0xFFFAFAFA),
                ),
                child: AnimatedBuilder(
                  animation: _waveAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: SubtlePatternPainter(
                        isDarkMode: isDarkMode,
                        animationValue: _waveAnimation.value,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
              ),

              // Success overlay animation
              if (_loginController.isAnimating)
                Positioned.fill(
                  child: Container(
                    color: (isDarkMode ? ThemeProvider.notionBlack : Colors.white)
                        .withOpacity(_loginController.value * 0.95),
                    child: Center(
                      child: ScaleTransition(
                        scale: _successIconAnimation,
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _loginController,
                              curve: const Interval(0.0, 0.3),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: ThemeProvider.notionBlue.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ThemeProvider.notionBlue.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.check_circle_outline,
                              color: ThemeProvider.notionBlue,
                              size: 60,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Main content with error shake animation
              SlideTransition(
                position: _errorShakeAnimation,
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [                      // Logo section with Notion-style card
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: ScaleTransition(
                          scale: _logoScaleAnimation,
                          child: FadeTransition(
                            opacity: _logoOpacityAnimation,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 40),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFE5E5E5),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/logo/Kempenhaeghe_logo.png',
                                width: 180,
                                height: 60,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Welcome text section
                      FadeTransition(
                        opacity: _backgroundAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.5),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _pageController,
                            curve:
                                const Interval(0.3, 0.7, curve: Curves.easeOut),
                          )),
                          child: SlideTransition(
                            position: _switchUserSlideAnimation,
                            child: FadeTransition(
                              opacity: _switchUserOpacityAnimation,
                              child: Column(
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _showUserSelectionDialog,
                                      borderRadius: BorderRadius.circular(30),                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 16),
                                          decoration: BoxDecoration(
                                            color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFE5E5E5),
                                              width: 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.08),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              CircleAvatar(
                                                radius: 20,
                                                backgroundColor: ThemeProvider.notionBlue.withOpacity(0.1),
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
                                              const SizedBox(width: 12),
                                              Flexible(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Welcome back',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                                      ),
                                                    ),
                                                    Text(
                                                      _username,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                        color: isDarkMode ? Colors.white : ThemeProvider.notionBlack,
                                                      ),
                                                    ),
                                                    if (_userEmail.isNotEmpty) ...[
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        _userEmail,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.expand_more,
                                                color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                    ),
                                  ),                                  const SizedBox(height: 20),
                                  Text(
                                    'Enter your PIN to continue',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // PIN section
                      ScaleTransition(
                        scale: _pinBoxAnimation,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 50),
                          child: Column(
                            children: [
                              // PIN display boxes
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: List.generate(
                                  6,
                                  (index) => ScaleTransition(
                                    scale: index < _enteredPin.length
                                        ? _dotAnimations[index]
                                        : const AlwaysStoppedAnimation(1.0),                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: index < _enteredPin.length
                                            ? ThemeProvider.notionBlue
                                            : (isDarkMode ? const Color(0xFF1A1A1A) : Colors.white),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: index < _enteredPin.length
                                              ? ThemeProvider.notionBlue
                                              : (isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFE5E5E5)),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          if (index < _enteredPin.length)
                                            BoxShadow(
                                              color: ThemeProvider.notionBlue.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                        ],
                                      ),
                                      child: _isLoggingIn && index < _enteredPin.length
                                          ? Center(
                                              child: SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                                  backgroundColor: Colors.white.withOpacity(0.2),
                                                ),
                                              ),
                                            )
                                          : index < _enteredPin.length
                                              ? const Center(
                                                  child: Icon(
                                                    Icons.circle,
                                                    color: Colors.white,
                                                    size: 12,
                                                  ),
                                                )
                                              : null,
                                                )
                                              : null,
                                    ),
                                  ),
                                ),
                              ),

                              // Error message
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: _showError
                                    ? const Padding(
                                        padding: EdgeInsets.only(top: 16),
                                        child: Text(
                                          'Incorrect PIN. Please try again.',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      )
                                    : const SizedBox(height: 16),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Keypad section
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: ScaleTransition(
                          scale: _keypadScaleAnimation,
                          child: FadeTransition(
                            opacity: _keypadOpacityAnimation,
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 24, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.2),
                                    Colors.white.withOpacity(0.05),
                                  ],
                                ),
                              ),
                              child: Column(
                                children: [
                                  for (int row = 0; row < 3; row++)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: List.generate(
                                          3,
                                          (col) => _buildKeypadButton(
                                              '${row * 3 + col + 1}'),
                                        ),
                                      ),
                                    ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      const SizedBox(width: 70, height: 70),
                                      _buildKeypadButton('0'),
                                      SizedBox(
                                        width: 70,
                                        height: 70,
                                        child: ScaleTransition(
                                          scale: _buttonPressAnimation,
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: _isLoggingIn
                                                  ? null
                                                  : _removeLastDigit,
                                              borderRadius:
                                                  BorderRadius.circular(35),
                                              splashColor:
                                                  Colors.white.withOpacity(0.1),
                                              highlightColor:
                                                  Colors.white.withOpacity(0.1),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.backspace_outlined,
                                                    color: Colors.white,
                                                    size: 24,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKeypadButton(String digit) {
    return SizedBox(
        width: 70,
        height: 70,
        child: ScaleTransition(
          scale: _buttonPressAnimation,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoggingIn ? null : () => _addDigit(digit),
              borderRadius: BorderRadius.circular(35),
              splashColor: Colors.white.withOpacity(0.1),
              highlightColor: Colors.white.withOpacity(0.1),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    digit,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),        ));
  }
}

class SubtlePatternPainter extends CustomPainter {
  final bool isDarkMode;
  final double animationValue;

  SubtlePatternPainter({
    required this.isDarkMode,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDarkMode 
          ? ThemeProvider.notionGray.withOpacity(0.03) 
          : const Color(0xFFE5E5E5).withOpacity(0.3))
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final spacing = 40.0;
    final offset = animationValue * spacing;

    // Draw subtle grid pattern
    for (double x = -spacing + (offset % spacing); x < size.width + spacing; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = -spacing + (offset % spacing); y < size.height + spacing; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(SubtlePatternPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || 
           oldDelegate.isDarkMode != isDarkMode;
  }
}
