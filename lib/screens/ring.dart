import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../games/snake_game.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

class RingScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;

  const RingScreen({Key? key, required this.alarmSettings}) : super(key: key);

  @override
  _RingScreenState createState() => _RingScreenState();
}

class _RingScreenState extends State<RingScreen> {
  late String _alarmOffMethod;
  late String _customText;
  late String _selectedGame;
  late int _requiredScore;
  late AudioPlayer _audioPlayer;

  String _enteredText = '';
  int _gameScore = 0;

  @override
  void initState() {
    super.initState();
    _parseAlarmSettings();
    _playAlarmSound();
  }

  void _parseAlarmSettings() {
    final parts = widget.alarmSettings.notificationBody.split('|');
    if (parts.length >= 4) {
      _alarmOffMethod = parts[0].split(' ').last;
      _customText = parts[1];
      _selectedGame = parts[2];
      _requiredScore = int.tryParse(parts[3]) ?? 5;
    } else {
      _alarmOffMethod = 'standard';
      _customText = '';
      _selectedGame = 'snake';
      _requiredScore = 5;
    }
  }

  Future<void> _playAlarmSound() async {
    _audioPlayer = AudioPlayer();
    try {
      await _audioPlayer.play(AssetSource(widget.alarmSettings.assetAudioPath));
    } catch (e) {
      print("Error playing alarm sound: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                'ההתראה פועלת!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              // const Text('🔔', style: TextStyle(fontSize: 50)),
              Lottie.asset('assets/bell.json', width: 200),
              _buildAlarmOffMethod(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmOffMethod() {
    switch (_alarmOffMethod) {
      case 'text':
        return _buildTextChallenge();
      case 'game':
        return _buildGameChallenge();
      default:
        return _buildStandardOffButtons();
    }
  }

  Widget _buildTextChallenge() {
    return Column(
      children: [
        Text('הקלד את הטקסט הבא: $_customText'),
        TextField(
          onChanged: (value) {
            setState(() {
              _enteredText = value;
            });
          },
        ),
        ElevatedButton(
          child: const Text('כבה התראה'),
          onPressed: _enteredText == _customText ? _stopAlarm : null,
        ),
      ],
    );
  }

  Widget _buildGameChallenge() {
    if (_selectedGame == 'snake') {
      return SnakeGame(
        requiredScore: _requiredScore,
        onGameOver: (int score) {
          if (score >= _requiredScore) {
            _stopAlarm();
          } else {
            _showFailureDialog(score);
          }
        },
      );
    } else {
      return Text('משחק מלחמת הכוכבים עדיין לא מיושם');
    }
  }

  Widget _buildStandardOffButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ElevatedButton(
          onPressed: _snoozeAlarm,
          child: Text('נודניק'),
        ),
        ElevatedButton(
          onPressed: _stopAlarm,
          child: Text('כבה'),
        ),
      ],
    );
  }

  Future<void> _stopAlarm() async {
    print("Attempting to stop alarm with id: ${widget.alarmSettings.id}");
    try {
      await _audioPlayer.stop();
      bool stopped = await Alarm.stop(widget.alarmSettings.id);
      print("Alarm stop result: $stopped");
      if (stopped) {
        print("Alarm stopped successfully");
        
        // Stop vibration
        await SystemChannels.platform.invokeMethod<void>('HapticFeedback.vibrate');
        await Future.delayed(Duration(milliseconds: 500));
        await SystemChannels.platform.invokeMethod<void>('HapticFeedback.cancel');
        
        print("Vibration stopped, popping screen");
        if (mounted) {
          Navigator.of(context).pop(true);
        } else {
          print("Widget is not mounted, cannot pop screen");
        }
      } else {
        print("Failed to stop alarm");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בכיבוי ההתראה')),
        );
      }
    } catch (e) {
      print("Error stopping alarm: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה בכיבוי ההתראה: $e')),
      );
    }
  }

  Future<void> _snoozeAlarm() async {
    print("Attempting to snooze alarm with id: ${widget.alarmSettings.id}");
    final now = DateTime.now();
    try {
      await _audioPlayer.stop();
      bool set = await Alarm.set(
        alarmSettings: widget.alarmSettings.copyWith(
          dateTime: DateTime(
            now.year,
            now.month,
            now.day,
            now.hour,
            now.minute,
          ).add(const Duration(minutes: 5)),
        ),
      );
      print("Alarm snooze result: $set");
      if (set) {
        print("Alarm snoozed successfully, popping screen");
        if (mounted) {
          Navigator.of(context).pop(true);
        } else {
          print("Widget is not mounted, cannot pop screen");
        }
      } else {
        print("Failed to snooze alarm");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בדחיית ההתראה')),
        );
      }
    } catch (e) {
      print("Error snoozing alarm: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה בדחיית ההתראה: $e')),
      );
    }
  }

  void _showFailureDialog(int score) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('כמעט הצלחת!'),
          content: Text('השגת $score נקודות מתוך $_requiredScore הנדרשות. נסה שוב!'),
          actions: <Widget>[
            TextButton(
              child: Text('נסה שוב'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }
}