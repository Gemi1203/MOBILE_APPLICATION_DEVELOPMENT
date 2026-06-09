import 'package:flutter/material.dart';

class AddSavingsContributionScreen extends StatefulWidget {
  const AddSavingsContributionScreen({super.key});

  @override
  State<AddSavingsContributionScreen> createState() =>
      _AddSavingsContributionScreenState();
}

class _AddSavingsContributionScreenState
    extends State<AddSavingsContributionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController referenceController = TextEditingController();

  String selectedChannel = 'M-Pesa';
  final List<String> channels = ['M-Pesa', 'Bank Transfer', 'Cash', 'Cheque'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21), // dark background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Ushirika SACCO'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF102A43),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.greenAccent, width: 1),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Add Savings Contribution',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Amount field
                  _buildInputField(
                    label: 'Amount (KES)',
                    controller: amountController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Channel dropdown
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.greenAccent),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonFormField<String>(
                      value: selectedChannel,
                      dropdownColor: const Color(0xFF102A43),
                      decoration: const InputDecoration(
                        labelText: 'Channel',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(color: Colors.white),
                      items: channels
                          .map((channel) => DropdownMenuItem(
                                value: channel,
                                child: Text(channel),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedChannel = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reference field
                  _buildInputField(
                    label: 'Reference (optional)',
                    controller: referenceController,
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Contribution of KES ${amountController.text} via $selectedChannel saved successfully!',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Save Contribution'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.greenAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
