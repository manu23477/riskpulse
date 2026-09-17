import 'package:flutter/material.dart';
import 'package:riskpulse/domain/subscription/subscription.dart';

/// Dialog supporting Student, PhD Scholar, and Library Card eligibility verification.
class StudentVerificationDialog extends StatefulWidget {
  final UserProfileEntity currentUser;
  final Function(UserProfileEntity verifiedUser) onVerified;

  const StudentVerificationDialog({
    super.key,
    required this.currentUser,
    required this.onVerified,
  });

  @override
  State<StudentVerificationDialog> createState() => _StudentVerificationDialogState();
}

class _StudentVerificationDialogState extends State<StudentVerificationDialog> {
  VerificationMethod _selectedMethod = VerificationMethod.studentIdCard;
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _documentIdController = TextEditingController();

  @override
  void dispose() {
    _institutionController.dispose();
    _documentIdController.dispose();
    super.dispose();
  }

  void _submit() {
    final inst = _institutionController.text.trim();
    if (inst.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your university/institution name.')),
      );
      return;
    }

    final verifiedUser = UserProfileEntity(
      userId: widget.currentUser.userId,
      displayName: widget.currentUser.displayName,
      email: widget.currentUser.email,
      role: UserRole.student,
      accountType: AccountType.student,
      subscriptionTier: SubscriptionTier.studentAnnual,
      isVerified: true,
      verificationMethod: _selectedMethod,
      institutionName: inst,
      createdAt: widget.currentUser.createdAt,
    );

    widget.onVerified(verifiedUser);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Student & Scholar Verification',
                  style: TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Select one valid eligibility proof to access the Student / PhD Scholar ₹399/year tier.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.0),
            ),
            const SizedBox(height: 16.0),

            // Verification Method Selection
            DropdownButtonFormField<VerificationMethod>(
              initialValue: _selectedMethod,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Verification Proof Type',
                labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              items: const [
                DropdownMenuItem(
                  value: VerificationMethod.studentIdCard,
                  child: Text('Student ID Card'),
                ),
                DropdownMenuItem(
                  value: VerificationMethod.phdScholarId,
                  child: Text('PhD / Research Scholar ID'),
                ),
                DropdownMenuItem(
                  value: VerificationMethod.libraryCard,
                  child: Text('University Library Card'),
                ),
                DropdownMenuItem(
                  value: VerificationMethod.academicEmail,
                  child: Text('Institutional Academic Email'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedMethod = val);
              },
            ),
            const SizedBox(height: 12.0),

            TextField(
              controller: _institutionController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'University / Institution Name',
                labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
            ),
            const SizedBox(height: 12.0),

            TextField(
              controller: _documentIdController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'ID / Library Card Number',
                labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
            ),
            const SizedBox(height: 20.0),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
                child: const Text('SUBMIT FOR VERIFICATION'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
