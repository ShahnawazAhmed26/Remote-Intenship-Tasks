import 'package:flutter/material.dart';
import 'package:expressions/expressions.dart';
import 'dart:math';

class Calculator extends StatefulWidget {
  const Calculator({super.key});

  @override
  State<Calculator> createState() => _HyperOSCalculatorState();
}

class _HyperOSCalculatorState extends State<Calculator> {
  static const Color backgroundColor = Color(0xFF000000); // Black
  static const Color buttonColor = Color(0xFF1E1E1E); // Dark Gray
  static const Color operatorColor = Color(0xFFFFC107); // Yellow
  static const Color actionColor = Color(0xFF424242); // Light Gray
  static const Color textColor = Colors.white; // White

  bool isScientificMode = false;
  String display = '0';
  String preview = '';
  String lastValidResult = '0';
  final TextEditingController _displayController = TextEditingController();
  final List<String> operators = ['+', '-', '×', '÷'];
  final List<String> history = [];

  @override
  void initState() {
    super.initState();
    _displayController.text = display;
  }

  @override
  void dispose() {
    _displayController.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: backgroundColor,
    body: Container(
      height: MediaQuery.of(context).size.height, // Ensures full screen usage
      width: MediaQuery.of(context).size.width,   // Ensures full width
      child: Column(
        children: <Widget>[
          _buildDisplay(MediaQuery.of(context).size.width),
          _buildPreviewDisplay(),
          const SizedBox(height: 5),
          Expanded(
            child: _buildButtonGrid(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height - MediaQuery.of(context).viewPadding.top - MediaQuery.of(context).viewPadding.bottom,
            ),
          
              
            ),
        ],
        ),
        ),
      );
    
  }

  Widget _buildDisplay(double screenWidth) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: TextField(
        controller: _displayController,
        style: TextStyle(
          color: textColor,
          fontSize: _getDisplayFontSize(screenWidth),
        ),
        textAlign: TextAlign.right,
        maxLines: 1,
        readOnly: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildPreviewDisplay() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Text(
        preview,
        style: TextStyle(
          color: Colors.grey,
          fontSize: 24,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  double _getDisplayFontSize(double screenWidth) {
    if (screenWidth < 320) {
      return 35; // Small screen
    } else if (screenWidth < 480) {
      return 45; // Medium screen
    } else {
      return 55; // Larger screens
    }
  }

  Widget _buildButtonGrid(double screenWidth, double screenHeight) {
  final List<String> buttonLabels = [
    'AC', '+/-', '%', '⌫',
    '7', '8', '9', '÷',
    '4', '5', '6', '×',
    '1', '2', '3', '-',
    '0', '.', '=', '+'
  ];

  if (isScientificMode) {
    buttonLabels.addAll(['sin', 'cos', 'tan', 'log', '√', '^', '!', 'π']);
  }

  return Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom + 10), // Adjust bottom padding dynamically
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: screenWidth / screenHeight > 0.6 ? 1.1 : 1.3, // Adjust for landscape mode
      ),
      itemCount: buttonLabels.length,
      itemBuilder: (context, index) {
        final button = buttonLabels[index];
        final isOperator = operators.contains(button);
        final isAction = ['AC', '⌫', '+/-', '%'].contains(button);
        final isScientific = ['sin', 'cos', 'tan', 'log', '√', '^', '!', 'π'].contains(button);

        return GestureDetector(
          onTap: () => _handleInput(button),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: isScientific
                  ? actionColor
                  : isOperator
                      ? operatorColor
                      : isAction
                          ? actionColor
                          : buttonColor,
              borderRadius: BorderRadius.circular(35),
            ),
            child: Center(
              child: Text(
                button,
                style: TextStyle(
                  fontSize: screenWidth < 320 ? 22 : 28, // Adjust font size for small screens
                  color: textColor,
                  fontWeight: isOperator ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}


  void _handleInput(String buttonText) {
    setState(() {
      if (buttonText == 'AC') {
        display = '0';
        preview = '';
        lastValidResult = '0';
      } else if (buttonText == '⌫') {
        display = display.length > 1 ? display.substring(0, display.length - 1) : '0';
      } else if (buttonText == '+/-') {
        display = display.startsWith('-') ? display.substring(1) : '-$display';
      } else if (buttonText == '=') {
        String result = _evaluateExpression(display);
        preview = '';
        lastValidResult = result;
        history.add('$display = $result');
        display = result;
      } else if (isScientificMode && ['sin', 'cos', 'tan', 'log', '√', '^', '!', 'π'].contains(buttonText)) {
        display = _handleScientificInput(buttonText, display);
      } else {
        if (display == '0' && !operators.contains(buttonText)) {
          display = buttonText;
        } else if (operators.contains(display[display.length - 1]) && operators.contains(buttonText)) {
          return;
        } else {
          display += buttonText;
        }

        if (!_isInvalidPreview(display)) {
          preview = _evaluatePreview(display);
        }
      }
      _displayController.text = display;
    });
  }

  String _handleScientificInput(String buttonText, String display) {
    double value = double.tryParse(display) ?? 0;
    switch (buttonText) {
      case 'sin':
        return (sin(value * (pi / 180))).toStringAsFixed(4); // Convert degrees to radians
      case 'cos':
        return (cos(value * (pi / 180))).toStringAsFixed(4); // Convert degrees to radians
      case 'tan':
        return (tan(value * (pi / 180))).toStringAsFixed(4); // Convert degrees to radians
      case 'log':
        return (log(value) / ln10).toStringAsFixed(4); // Logarithm base 10
      case '√':
        return (sqrt(value)).toStringAsFixed(4); // Square root
      case '^':
        return '^'; // Exponentiation (handled in expression evaluation)
      case '!':
        return _factorial(value.toInt()).toString(); // Factorial
      case 'π':
        return pi.toStringAsFixed(4); // Pi constant
      default:
        return display;
    }
  }

  int _factorial(int n) {
    if (n == 0 || n == 1) return 1;
    return n * _factorial(n - 1);
  }

  bool _isInvalidPreview(String exp) {
    return exp.endsWith('.') || exp.endsWith('%') || operators.contains(exp[exp.length - 1]);
  }

  String _evaluatePreview(String exp) {
    exp = _normalizeExpression(exp);
    try {
      final expression = Expression.parse(exp);
      final evaluator = const ExpressionEvaluator();
      final result = evaluator.eval(expression, {});
      return result % 1 == 0 ? result.toStringAsFixed(0) : result.toString();
    } catch (e) {
      return '';
    }
  }

  String _evaluateExpression(String exp) {
    exp = _normalizeExpression(exp);
    try {
      final expression = Expression.parse(exp);
      final evaluator = const ExpressionEvaluator();
      final result = evaluator.eval(expression, {});
      return result % 1 == 0 ? result.toStringAsFixed(0) : result.toString();
    } catch (e) {
      return 'ERROR';
    }
  }

  String _normalizeExpression(String expression) {
    expression = expression.replaceAllMapped(RegExp(r'(\d+\.?\d*)%'), (match) {
      double value = double.parse(match.group(1)!);
      return (value / 100).toString();
    });

    expression = expression.replaceAllMapped(RegExp(r'(\d+\.?\d*)%'), (match) {
      int index = match.start;
      String before = expression.substring(0, index).trim();

      if (before.isNotEmpty && RegExp(r'[\d.]+$').hasMatch(before)) {
        final prevNumberMatch = RegExp(r'([\d.]+)$').firstMatch(before);
        if (prevNumberMatch != null) {
          double prevValue = double.parse(prevNumberMatch.group(1)!);
          double percentage = prevValue * (double.parse(match.group(1)!) / 100);
          return percentage.toString();
        }
      }
      return match.group(0)!;
    });

    return expression.replaceAll('×', '*').replaceAll('÷', '/');
  }

  

 void _showHistory() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            ListTile(
              title: Text(
                'History',
                style: TextStyle(color: textColor, fontSize: 18),
              ),
              trailing: IconButton(
                icon: Icon(Icons.clear, color: textColor),
                onPressed: () {
                  setState(() => history.clear());
                  Navigator.pop(context);
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        display = history[index].split(' = ')[0];
                        preview = history[index].split(' = ')[1];
                      });
                      Navigator.pop(context);
                    },
                    child: ListTile(
                      title: Text(
                        history[index],
                        style: TextStyle(color: textColor),
                      ),
                      leading: Icon(Icons.history, color: textColor),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                setState(() => history.clear());
                Navigator.pop(context);
              },
              child: Text('Clear History'),
            ),
            SizedBox(height: 10),
          ],
        ),
      );
    },
  );
}
}
