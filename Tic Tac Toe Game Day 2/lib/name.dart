import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game.dart';

class NameInputScreen extends StatefulWidget {
  const NameInputScreen({super.key});

  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  final TextEditingController _name1Controller = TextEditingController();
  final TextEditingController _name2Controller = TextEditingController();
  bool isSinglePlayer = true;
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  String difficulty = "Normal";
  final List<String> difficulties = ["Passive", "Easy", "Normal", "Hard", "Unfair"];
  bool isName1Valid = true;
  bool isName2Valid = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name1Controller.text = prefs.getString("player1") ?? "";
      _name2Controller.text = prefs.getString("player2") ?? "";
      isSinglePlayer = prefs.getBool("isSinglePlayer") ?? true;
      soundEnabled = prefs.getBool("soundEnabled") ?? true;
      vibrationEnabled = prefs.getBool("vibrationEnabled") ?? true;
      difficulty = prefs.getString("difficulty") ?? "Normal";
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("player1", _name1Controller.text.trim());
    await prefs.setString("player2", _name2Controller.text.trim());
    await prefs.setBool("isSinglePlayer", isSinglePlayer);
    await prefs.setBool("soundEnabled", soundEnabled);
    await prefs.setBool("vibrationEnabled", vibrationEnabled);
    await prefs.setString("difficulty", difficulty);
  }

  void _validateAndStartGame() {
    setState(() {
      isName1Valid = _name1Controller.text.trim().isNotEmpty;
      isName2Valid = isSinglePlayer || _name2Controller.text.trim().isNotEmpty;
    });

    if (isName1Valid && isName2Valid) {
      _savePreferences();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TicTacToe(
            name1: _name1Controller.text.trim(),
            name2: isSinglePlayer ? "AI" : _name2Controller.text.trim(),
            isSinglePlayer: isSinglePlayer,
            soundEnabled: soundEnabled,
            vibrationEnabled: vibrationEnabled,
            difficulty: difficulty,
          ),
        ),
      );
    }
  }

  Widget _buildNameInput(TextEditingController controller, String label, bool isValid, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        errorText: isValid ? null : "Required",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Enter Player Names" , style: TextStyle(color: Colors.white),),
          backgroundColor: Colors.deepPurple,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back , color: Colors.white,),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNameInput(_name1Controller, "Player 1 Name", isName1Valid, Icons.person),
              if (!isSinglePlayer) ...[
                const SizedBox(height: 16),
                _buildNameInput(_name2Controller, "Player 2 Name", isName2Valid, Icons.person_outline),
              ],
              const SizedBox(height: 20),
              
              // Mode Selection
              ToggleButtons(
                borderRadius: BorderRadius.circular(12),
                selectedColor: Colors.white,
                fillColor: Colors.deepPurple,
                color: Colors.grey.shade600,
                isSelected: [isSinglePlayer, !isSinglePlayer],
                onPressed: (index) => setState(() => isSinglePlayer = index == 0),
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Single Player")),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Multiplayer")),
                ],
              ),

              if (isSinglePlayer) ...[
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: difficulty,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (value) => setState(() => difficulty = value!),
                  items: difficulties.map((level) => DropdownMenuItem(
                    value: level,
                    child: Text(level),
                  )).toList(),
                  isExpanded: true,
                ),
              ],
              const SizedBox(height: 20),

              // Sound & Vibration Toggles
              SwitchListTile(
                title: const Text("Enable Sound"),
                value: soundEnabled,
                onChanged: (value) => setState(() => soundEnabled = value),
                activeColor: Colors.deepPurple,
              ),
              SwitchListTile(
                title: const Text("Enable Vibration"),
                value: vibrationEnabled,
                onChanged: (value) => setState(() => vibrationEnabled = value),
                activeColor: Colors.deepPurple,
              ),
              const SizedBox(height: 20),

              // Start Game Button
              ElevatedButton(
                onPressed: (isName1Valid && isName2Valid) ? _validateAndStartGame : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Start Game", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
