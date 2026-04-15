import 'package:flutter/material.dart';
import '../services/app_lock_service.dart';
import '../widgets/pattern_lock.dart';
import 'security_recovery_screen.dart';
import 'main_nav.dart';

class SecurityLoginScreen extends StatefulWidget {
  final bool isChangingSettings;
  const SecurityLoginScreen({super.key, this.isChangingSettings = false});

  @override
  State<SecurityLoginScreen> createState() => _SecurityLoginScreenState();
}

class _SecurityLoginScreenState extends State<SecurityLoginScreen> {
  final _appLockService = AppLockService();
  LoginType? _loginType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadType();
  }

  Future<void> _loadType() async {
    final type = await _appLockService.getLoginType();
    if (mounted) {
      setState(() {
        _loginType = type;
        _isLoading = false;
      });
    }
  }

  Future<void> _verify(String credential) async {
    final isValid = await _appLockService.verifyCredential(credential);
    if (!mounted) return;

    if (isValid) {
      if (widget.isChangingSettings) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNav()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect login. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: widget.isChangingSettings ? AppBar(title: const Text('Verify Identity')) : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Enter your ${_loginType!.name.toUpperCase()}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              
              if (_loginType == LoginType.pattern)
                 PatternLock(onPatternComplete: (p) => _verify(p.join('-'))),
                 
              if (_loginType == LoginType.pin)
                 _PinInput(onPinComplete: _verify),
                 
              if (_loginType == LoginType.password)
                 _PasswordInput(onPasswordSubmit: _verify),

              const SizedBox(height: 32),
              
              if (!widget.isChangingSettings)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SecurityRecoveryScreen()),
                    );
                  },
                  child: const Text('Forgot login?'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets copied/adapted from Setup Screen to keep logic decoupled.
// (In a real scenario, these could be extracted to separate widget files)
// ─────────────────────────────────────────────────────────────────────────────

class _PinInput extends StatefulWidget {
  final ValueChanged<String> onPinComplete;
  const _PinInput({required this.onPinComplete});

  @override
  State<_PinInput> createState() => _PinInputState();
}

class _PinInputState extends State<_PinInput> {
  String _pin = '';

  void _onKey(String val) {
    if (_pin.length < 4) {
      setState(() => _pin += val);
      if (_pin.length == 4) {
        widget.onPinComplete(_pin);
        // Delay clearing visual slightly
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) setState(() => _pin = '');
        });
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
  const _PasswordInput({required this.onPasswordSubmit});

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
             child: const Text('Unlock'),
          ),
        )
      ],
    );
  }
}
