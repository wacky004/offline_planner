import 'package:flutter/material.dart';
import '../services/app_lock_service.dart';
import 'security_setup_screen.dart'; // We could reuse setup screen logic but it's simpler to do reset here
import 'main_nav.dart';

class SecurityRecoveryScreen extends StatefulWidget {
  const SecurityRecoveryScreen({super.key});

  @override
  State<SecurityRecoveryScreen> createState() => _SecurityRecoveryScreenState();
}

class _SecurityRecoveryScreenState extends State<SecurityRecoveryScreen> {
  final _appLockService = AppLockService();
  String? _question;
  final _answerController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    final q = await _appLockService.getSecurityQuestion();
    if (mounted) {
      setState(() {
        _question = q;
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyAnswer() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) return;

    final isValid = await _appLockService.verifySecurityAnswer(answer);
    if (!mounted) return;

    if (isValid) {
      // Disables lock temporarily, takes them to Setup Screen to configure new pin/pattern
      // Alternatively, just open MainNav, but we should make them reset it.
      await _appLockService.removeLock();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App Lock disabled. Please setup a new one in Settings.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNav()),
        (route) => false,
      );

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect answer. Please try again.')),
      );
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Account Recovery')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Answer your security question to reset your lock.',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            if (_question == null)
               const Text('No security question was set for this account.')
            else ...[
              Text(
                _question!,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _answerController,
                decoration: const InputDecoration(
                  labelText: 'Answer',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState((){}),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _answerController.text.isNotEmpty ? _verifyAnswer : null,
                child: const Text('Submit'),
              )
            ]
          ],
        ),
      ),
    );
  }
}
