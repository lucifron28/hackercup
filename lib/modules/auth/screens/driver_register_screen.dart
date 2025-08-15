import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _licenseController = TextEditingController();
  final _plateController = TextEditingController();
  final _jeepneyModelController = TextEditingController();
  final _bodyNumberController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  String? _selectedRoute;

  final List<Map<String, String>> _routes = [
    {'id': 'route_divisoria_fairview', 'name': 'Divisoria - Fairview'},
    {'id': 'route_cubao_antipolo', 'name': 'Cubao - Antipolo'},
    {'id': 'route_quiapo_sta_mesa', 'name': 'Quiapo - Sta. Mesa'},
    {'id': 'route_alabang_ayala', 'name': 'Alabang - Ayala'},
    {'id': 'route_sm_north_trinoma', 'name': 'SM North - Trinoma'},
    {'id': 'route_eastwood_ortigas', 'name': 'Eastwood - Ortigas'},
    {'id': 'route_marikina_quezon_ave', 'name': 'Marikina - Quezon Ave'},
    {'id': 'route_commonwealth_philcoa', 'name': 'Commonwealth - Philcoa'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _licenseController.dispose();
    _plateController.dispose();
    _jeepneyModelController.dispose();
    _bodyNumberController.dispose();
    super.dispose();
  }

  Future<void> _registerDriver() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRoute == null) {
      setState(() {
        _errorMessage = 'Please select your jeepney route';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AuthService.registerDriver(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        licenseNumber: _licenseController.text.trim(),
        jeepneyPlateNumber: _plateController.text.trim(),
        routeId: _selectedRoute!,
      );

      if (result.isSuccess && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Welcome to JeepGo, ${_nameController.text}!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to driver dashboard
        context.go('/driver-dashboard');
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Registration failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Registration error: $e';
      });
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange.shade600,
              Colors.deepOrange.shade700,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Header with Jeepney Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.directions_bus,
                          size: 64,
                          color: Colors.orange.shade600,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Jeepney Driver',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Join the JeepGo Community',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Start earning with real-time passenger tracking',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Error Message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Personal Information Section
                  _buildSectionHeader('Personal Information'),
                  const SizedBox(height: 12),

                  _buildInputCard(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Please enter your full name';
                      if (value!.length < 2) return 'Name must be at least 2 characters';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  _buildInputCard(
                    controller: _emailController,
                    label: 'Email Address',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Please enter your email address';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  _buildInputCard(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Please enter your phone number';
                      if (value!.length < 10) return 'Please enter a valid phone number';
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Driver License Section
                  _buildSectionHeader('Driver License & Credentials'),
                  const SizedBox(height: 12),

                  _buildInputCard(
                    controller: _licenseController,
                    label: 'Professional Driver\'s License Number',
                    icon: Icons.card_membership,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Please enter your license number';
                      if (value!.length < 8) return 'Please enter a valid license number';
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Jeepney Information Section
                  _buildSectionHeader('Jeepney Information'),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildInputCard(
                          controller: _plateController,
                          label: 'Plate Number',
                          icon: Icons.directions_bus,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Required';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInputCard(
                          controller: _bodyNumberController,
                          label: 'Body Number',
                          icon: Icons.numbers,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Required';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildInputCard(
                    controller: _jeepneyModelController,
                    label: 'Jeepney Model/Year',
                    icon: Icons.build,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Route Selection
                  _buildRouteSelector(),

                  const SizedBox(height: 24),

                  // Security Section
                  _buildSectionHeader('Account Security'),
                  const SizedBox(height: 12),

                  _buildInputCard(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Please enter a password';
                      if (value!.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  _buildInputCard(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    icon: Icons.lock_outline,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Please confirm password';
                      if (value != _passwordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // Terms and Conditions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.white, size: 24),
                        const SizedBox(height: 8),
                        const Text(
                          'By registering, you agree to:',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• Provide real-time location during trips\n'
                          '• Follow traffic rules and safety protocols\n'
                          '• Maintain professional conduct with passengers\n'
                          '• Keep your jeepney information updated',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registerDriver,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.orange.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Start Driving with JeepGo',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already a driver? ',
                        style: TextStyle(color: Colors.white.withOpacity(0.8)),
                      ),
                      TextButton(
                        onPressed: () => context.go('/driver-login'),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: Colors.orange.shade600),
            suffixIcon: suffixIcon,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteSelector() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Select Your Route',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedRoute,
              isExpanded: true,
              decoration: const InputDecoration(
                hintText: 'Choose your regular jeepney route',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              items: _routes.map((route) {
                return DropdownMenuItem(
                  value: route['id'],
                  child: Text(
                    route['name']!,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedRoute = value),
              validator: (value) => value == null ? 'Please select your route' : null,
            ),
            const SizedBox(height: 8),
            Text(
              'This will be your primary route. You can add more routes later.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
