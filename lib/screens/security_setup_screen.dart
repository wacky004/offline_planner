import 'package:flutter/material.dart';
import '../services/app_lock_service.dart';
import '../widgets/pattern_lock.dart';
import 'main_nav.dart';

class SecuritySetupScreen extends StatefulWidget {
  const SecuritySetupScreen({super.key});

  @override
  State<SecuritySetupScreen> createState() => _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends State<SecuritySetupScreen> {
  final _pageController = PageController();
  final _appLockService = AppLockService();
  
  // Step 1
  String? _selectedQuestion;
  final _answerController = TextEditingController();
  
  // Step 2
  LoginType? _selectedType;
  
  // Step 3
  String _credential = '';
  String _confirmCredential = '';
  bool _isConfirming = false;

  final List<String> _questions = [
    'What is your favorite food?',
    'What is your childhood nickname?',
    'What city were you born in?',
    'What is your favorite color?',
    'What was your first pet\'s name?',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _prevPage() {
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() {
      _isConfirming = false;
      _credential = '';
      _confirmCredential = '';
    });
  }

  Future<void> _saveSetup() async {
    await _appLockService.saveSetup(
      question: _selectedQuestion!,
      answer: _answerController.text,
      loginType: _selectedType!,
      credential: _credential,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNav()),
    );
  }

  void _handleCredentialInput(String value) {
    setState(() {
      if (!_isConfirming) {
        _credential = value;
        if ((_selectedType == LoginType.pin && _credential.length == 4) ||
            _selectedType == LoginType.pattern) {
          _isConfirming = true;
        }
      } else {
        _confirmCredential = value;
        if (_credential == _confirmCredential) {
          _saveSetup();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Credentials do not match. Try again.')),
          );
          _isConfirming = false;
          _credential = '';
          _confirmCredential = '';
          if (_selectedType == LoginType.password) {
            _confirmCredential = '';
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Setup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_pageController.page == 0) {
              // Can't go back, must setup
            } else {
              _prevPage();
            }
          },
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStep1(),
          _buildStep2(),
          _buildStep3(),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Step 1: Recovery Question',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('This will be used if you ever forget your App Lock.'),
          const SizedBox(height: 32),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Security Question',
              border: OutlineInputBorder(),
            ),
            value: _selectedQuestion,
            items: _questions.map((q) => DropdownMenuItem(value: q, child: Text(q))).toList(),
            onChanged: (v) => setState(() => _selectedQuestion = v),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _answerController,
            decoration: const InputDecoration(
              labelText: 'Answer',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const Spacer(),
          FilledButton(
            onPressed: (_selectedQuestion != null && _answerController.text.trim().isNotEmpty) ? _nextPage : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Step 2: Security Type',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Choose how you want to unlock your app.'),
          const SizedBox(height: 32),
          _methodCard('Pattern', Icons.gesture, LoginType.pattern),
          const SizedBox(height: 12),
          _methodCard('4-Digit PIN', Icons.pin, LoginType.pin),
          const SizedBox(height: 12),
          _methodCard('Password', Icons.password, LoginType.password),
          const Spacer(),
          FilledButton(
            onPressed: _selectedType != null ? _nextPage : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _methodCard(String title, IconData icon, LoginType type) {
    final isSelected = _selectedType == type;
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? colorScheme.primary : colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.2) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? colorScheme.primary : null),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _isConfirming ? 'Confirm your $_selectedType' : 'Create your $_selectedType',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          if (_selectedType == LoginType.pattern)
             PatternLock(onPatternComplete: (pattern) {
               if (pattern.length < 4) {
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pattern must be at least 4 dots.')),
                 );
                 return;
               }
               _handleCredentialInput(pattern.join('-'));
             }),
          if (_selectedType == LoginType.pin)
             _PinInput(
               onPinComplete: _handleCredentialInput, 
               isConfirming: _isConfirming
             ),
          if (_selectedType == LoginType.password)
             _PasswordInput(
               onPasswordSubmit: _handleCredentialInput,
               buttonText: _isConfirming ? 'Confirm' : 'Next',
             ),
        ],
      ),
    );
  }
}

class _PinInput extends StatefulWidget {
  final ValueChanged<String> onPinComplete;
  final bool isConfirming;
  const _PinInput({required this.onPinComplete, required this.isConfirming});

  @override
  State<_PinInput> createState() => _PinInputState();
}

class _PinInputState extends State<_PinInput> {
  String _pin = '';

  @override
  void didUpdateWidget(covariant _PinInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConfirming != oldWidget.isConfirming) {
      _pin = '';
    }
  }

  void _onKey(String val) {
    if (_pin.length < 4) {
      setState(() => _pin += val);
      if (_pin.length == 4) {
        widget.onPinComplete(_pin);
        if (!widget.isConfirming) {
            setState(() => _pin = '');
        }
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < _pin.length ? Theme.of(context).colorScheme.primary : Colors.grey.withValues(alpha: 0.3),
              ),
            );
          }),
        ),
        const SizedBox(height: 50),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 1; i <= 9; i++) _numButton(i.toString()),
            const SizedBox(width: 80, height: 80),
            _numButton('0'),
            InkWell(
              onTap: _onDelete,
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: 80,
                height: 80,
                alignment: Alignment.center,
                child: const Icon(Icons.backspace, size: 30),
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _numButton(String num) {
    return InkWell(
      onTap: () => _onKey(num),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.withValues(alpha: 0.1)),
        alignment: Alignment.center,
        child: Text(num, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _PasswordInput extends StatefulWidget {
  final ValueChanged<String> onPasswordSubmit;
  final String buttonText;
  const _PasswordInput({required this.onPasswordSubmit, required this.buttonText});

  @override
  State<_PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<_PasswordInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState((){}),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
             onPressed: _controller.text.length >= 4 ? () {
               widget.onPasswordSubmit(_controller.text);
               _controller.clear();
             } : null,
             child: Text(widget.buttonText),
          ),
        )
      ],
    );
  }
}
