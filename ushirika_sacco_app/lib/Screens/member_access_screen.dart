import 'package:flutter/material.dart';
import '../store/sacco_store.dart';

class MemberAccessScreen extends StatefulWidget {
  final SaccoStore store;
  const MemberAccessScreen({super.key, required this.store});

  @override
  State<MemberAccessScreen> createState() => _MemberAccessScreenState();
}

class _MemberAccessScreenState extends State<MemberAccessScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _memberNumberController;
  late TextEditingController _phoneController;
  final TextEditingController _appIdController = TextEditingController();
  final TextEditingController _jsKeyController = TextEditingController();
  final TextEditingController _serverUrlController = TextEditingController();

  String _message = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.store.memberName);
    _memberNumberController =
        TextEditingController(text: widget.store.memberNumber);
    _phoneController = TextEditingController(text: widget.store.phone);
    _serverUrlController.text = 'https://parseapi.back4app.com/';
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 800));

    widget.store.memberName = _fullNameController.text.trim();
    widget.store.memberNumber = _memberNumberController.text.trim();
    widget.store.phone = _phoneController.text.trim();

    setState(() {
      _message = 'Profile saved successfully!';
      _isLoading = false;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Profile Saved!')),
        );
        widget.store.setTab(2);
      }
    });
  }

  void _saveBack4AppConfig() {
    setState(() {
      _message = '✅ Cloud configuration saved.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ushirika SACCO'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Screen 2',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Member Access',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Set your member profile once, then move through savings and loan workflows.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              _buildTextField(
                  'Full Name', _fullNameController, 'e.g. Amina Wanjiku'),
              const SizedBox(height: 20),
              _buildTextField(
                  'Member Number', _memberNumberController, 'e.g. SAC-1023'),
              const SizedBox(height: 20),
              _buildTextField('Phone Number', _phoneController, 'e.g. +2547...',
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save & Continue',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              if (_message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _message,
                    style: TextStyle(
                        color: _message.contains('success')
                            ? Colors.green
                            : Colors.blue),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 40),
              ExpansionTile(
                title: const Text(
                  'Optional: Back4App SDK Config',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green),
                ),
                children: [
                  const SizedBox(height: 8),
                  _buildTextField(
                      'App ID', _appIdController, 'Back4App App ID'),
                  const SizedBox(height: 12),
                  _buildTextField('JavaScript Key', _jsKeyController,
                      'Back4App JavaScript Key'),
                  const SizedBox(height: 12),
                  _buildTextField('Server URL', _serverUrlController, ''),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _saveBack4AppConfig,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Save Cloud Config'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, String placeholder,
      {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: placeholder,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) =>
              value!.trim().isEmpty ? '$label is required' : null,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _memberNumberController.dispose();
    _phoneController.dispose();
    _appIdController.dispose();
    _jsKeyController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }
}
