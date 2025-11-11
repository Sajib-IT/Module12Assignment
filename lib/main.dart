import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkTheme') ?? false;
  runApp(CalculatorApp(isDarkTheme: isDark));
}

class CalculatorApp extends StatefulWidget {
  final bool isDarkTheme;
  const CalculatorApp({super.key, required this.isDarkTheme});

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _isDark = widget.isDarkTheme;
  }

  void _toggleTheme() async {
    setState(() => _isDark = !_isDark);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', _isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: CalculatorHome(
        isDark: _isDark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class CalculatorHome extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  const CalculatorHome({super.key, required this.isDark, required this.onToggleTheme});

  @override
  State<CalculatorHome> createState() => _CalculatorHomeState();
}

class _CalculatorHomeState extends State<CalculatorHome> {
  String _expression = '';
  String _result = '';

  static const Set<String> operators = {'+', '-', '×', '÷', '*', '/'};

  String _toEvalExpression(String input) {
    return input.replaceAll('×', '*').replaceAll('÷', '/');
  }

  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'AC') {
        _expression = '';
        _result = '';
        return;
      }

      if (value == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
        if (_result.isNotEmpty) _result = '';
        return;
      }

      if (value == '=') {
        _evaluateExpression();
        return;
      }

      // Operator validation
      if (operators.contains(value)) {
        if (_expression.isEmpty) {
          if (value == '-') {
            _expression = '-';
            return;
          }
          return;
        }
        final last = _expression.characters.last;
        if (operators.contains(last)) {
          _expression = _expression.substring(0, _expression.length - 1) + value;
          return;
        } else {
          _expression += value;
          return;
        }
      }

      // Decimal validation
      if (value == '.') {
        int lastOpIndex = -1;
        for (int i = _expression.length - 1; i >= 0; i--) {
          if (operators.contains(_expression[i])) {
            lastOpIndex = i;
            break;
          }
        }
        final currentNumber = _expression.substring(lastOpIndex + 1);
        if (currentNumber.contains('.')) return;
        if (currentNumber.isEmpty) {
          _expression += '0.';
        } else {
          _expression += '.';
        }
        return;
      }

      // Digits
      _expression += value;
    });
  }

  void _evaluateExpression() {
    if (_expression.isEmpty) return;
    final last = _expression.characters.last;
    if (operators.contains(last)) {
      _expression = _expression.substring(0, _expression.length - 1);
    }

    try {
      final expStr = _toEvalExpression(_expression);
      Parser p = Parser();
      Expression exp = p.parse(expStr);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      String formatted;
      if (eval == eval.roundToDouble()) {
        formatted = eval.toInt().toString();
      } else {
        formatted = eval.toStringAsFixed(10);
        formatted = formatted.replaceFirst(RegExp(r'0+$'), '');
        formatted = formatted.replaceFirst(RegExp(r'\.$'), '');
      }

      setState(() {
        _result = formatted;
      });
    } catch (e) {
      setState(() {
        _result = 'Error';
      });
    }
  }

  Widget _buildButton(String label, {double flex = 1, Color? textColor, Color? bg}) {
    return Expanded(
      flex: flex.toInt(),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            backgroundColor: bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          onPressed: () => _onButtonPressed(label),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: textColor ?? Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'),
        actions: [
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Display
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(
                        _expression.isEmpty ? '0' : _expression,
                        style: TextStyle(
                          fontSize: 28,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _result,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Keypad (same color scheme)
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildButton('AC', bg: Colors.redAccent, textColor: Colors.white),
                        _buildButton('⌫', bg: Colors.grey, textColor: Colors.white),
                        _buildButton('÷', textColor: isDark ? Colors.white : Colors.black),
                        _buildButton('×', textColor: isDark ? Colors.white : Colors.black),
                      ],
                    ),
                    Row(
                      children: [
                        _buildButton('7',textColor: isDark ? Colors.white : Colors.black),
                        _buildButton('8', textColor: isDark ? Colors.white : Colors.black),
                        _buildButton('9', textColor: isDark ? Colors.white : Colors.black),
                        _buildButton('-', textColor: isDark ? Colors.white : Colors.black),
                      ],
                    ),
                    Row(
                      children: [
                        _buildButton('4', textColor: isDark ? Colors.white : Colors.black),
                        _buildButton('5', textColor: isDark ? Colors.white : Colors.black),
                        _buildButton('6', textColor: isDark ? Colors.white : Colors.black),
                        _buildButton('+', textColor: isDark ? Colors.white : Colors.black),
                      ],
                    ),
                    Row(
                      children: [
                        _buildButton('1', textColor: isDark ? Colors.white : Colors.black),
                        _buildButton('2', textColor: isDark ? Colors.white : Colors.black),
                        _buildButton('3', textColor: isDark ? Colors.white : Colors.black),
                        _buildButton('=', bg: Colors.blueAccent, textColor: Colors.white),
                      ],
                    ),
                    Row(
                      children: [
                        _buildButton('0', flex: 2, textColor: isDark ? Colors.white : Colors.black),
                        _buildButton('.', textColor: isDark ? Colors.white : Colors.black),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
