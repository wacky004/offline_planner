import 'package:flutter/material.dart';
import '../services/pin_service.dart';
import 'main_nav.dart';

class PinScreen extends StatefulWidget {
  final bool isSettingUp;
  const PinScreen({super.key, required this.isSettingUp});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  final _pinService = PinService();

  void _onKey(String val) async {
    if (_pin.length < 4) {
      setState(() => _pin += val);
    }
    
    if (_pin.length == 4) {
      if (widget.isSettingUp) {
        await _pinService.setPin(_pin);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNav())
          );
        }
      } else {
        bool isValid = await _pinService.verifyPin(_pin);
        if (isValid && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNav())
          );
        } else {
          setState(() => _pin = '');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid PIN')),
            );
          }
        }
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  void _skip() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNav())
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isSettingUp ? AppBar(
        title: const Text('Setup PIN'),
        actions: [
          TextButton(
            onPressed: _skip, 
            child: const Text('SKIP', style: TextStyle(color: Colors.grey))
          )
        ],
      ) : null,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.isSettingUp ? 'Create a 4-digit PIN' : 'Enter your PIN',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _pin.length ? Theme.of(context).colorScheme.primary : Colors.grey.withOpacity(0.3),
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
        ),
      ),
    );
  }

  Widget _numButton(String num) {
    return InkWell(
      onTap: () => _onKey(num),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.withOpacity(0.1)),
        alignment: Alignment.center,
        child: Text(num, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
