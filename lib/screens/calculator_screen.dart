import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/app_drawer.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _output = "0";
  String _operand = "";
  double _num1 = 0;
  bool _newInputExpected = false;

  void _calculateResult() {
    double num2 = double.tryParse(_output) ?? 0;
    double result = 0;
    if (_operand == "+") result = _num1 + num2;
    if (_operand == "-") result = _num1 - num2;
    if (_operand == "×") result = _num1 * num2;
    if (_operand == "÷") result = num2 == 0 ? 0 : _num1 / num2;

    _output = result.toString();
    if (_output.endsWith(".0")) {
      _output = _output.substring(0, _output.length - 2);
    }
    _num1 = result;
  }

  void _buttonPressed(String num) {
    setState(() {
      if (num == "C") {
        _output = "0";
        _operand = "";
        _num1 = 0;
        _newInputExpected = false;
      } else if (num == "⌫") {
        if (_newInputExpected) {
          _newInputExpected = false;
        }
        if (_output.length > 1) {
          _output = _output.substring(0, _output.length - 1);
          if (_output == "-" || _output.isEmpty) {
            _output = "0";
          }
        } else {
          _output = "0";
        }
      } else if (num == "+" || num == "-" || num == "×" || num == "÷") {
        if (_operand.isNotEmpty && !_newInputExpected) {
          _calculateResult();
        } else {
          _num1 = double.tryParse(_output) ?? 0;
        }
        _operand = num;
        _newInputExpected = true;
      } else if (num == "=") {
        if (_operand.isNotEmpty) {
           _calculateResult();
           _operand = "";
           _newInputExpected = true;
        }
      } else {
        if (_newInputExpected) {
          if (num == ".") {
             _output = "0.";
          } else {
             _output = num;
          }
          _newInputExpected = false;
        } else {
          if (num == ".") {
            if (!_output.contains(".")) {
               _output = _output + ".";
            }
          } else if (_output == "0") {
            _output = num;
          } else {
            _output = _output + num;
          }
        }
      }
    });
  }

  Widget _buildButton(String title, {int flex = 1, Color? color, Color? textColor}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: textColor ?? (color != null && color == Theme.of(context).colorScheme.primary ? Theme.of(context).colorScheme.onPrimary : null),
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () => _buttonPressed(title),
          child: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String value, {int flex = 1, Color? color}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () => _buttonPressed(value),
          child: Icon(icon, size: 28),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Calculator')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.all(24),
              child: Text(
                _output,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const Divider(),
          Column(
            children: [
              Row(
                children: [
                  _buildButton("C"),
                  _buildIconButton(Icons.backspace_outlined, "⌫"),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                           await Clipboard.setData(ClipboardData(text: _output));
                           if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!')));
                           }
                        },
                        child: const Icon(Icons.copy, size: 28),
                      ),
                    ),
                  ),
                  _buildButton("÷", color: Theme.of(context).colorScheme.secondaryContainer),
                ],
              ),
              Row(
                children: [
                  _buildButton("7"), _buildButton("8"), _buildButton("9"), 
                  _buildButton("×", color: Theme.of(context).colorScheme.secondaryContainer),
                ],
              ),
              Row(
                children: [
                  _buildButton("4"), _buildButton("5"), _buildButton("6"), 
                  _buildButton("-", color: Theme.of(context).colorScheme.secondaryContainer),
                ],
              ),
              Row(
                children: [
                  _buildButton("1"), _buildButton("2"), _buildButton("3"), 
                  _buildButton("+", color: Theme.of(context).colorScheme.secondaryContainer),
                ],
              ),
              Row(
                children: [
                  _buildButton("0", flex: 2), 
                  _buildButton("."), 
                  _buildButton("=", color: Theme.of(context).colorScheme.primary, textColor: Theme.of(context).colorScheme.onPrimary),
                ],
              ),
              const SizedBox(height: 16),
            ],
          )
        ],
      ),
    );
  }
}
