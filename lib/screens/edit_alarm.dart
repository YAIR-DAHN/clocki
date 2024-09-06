import 'package:alarm/alarm.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:time_picker_spinner_pop_up/time_picker_spinner_pop_up.dart';

class EditAlarmScreen extends StatefulWidget {

  const EditAlarmScreen({super.key, this.alarmSettings});
  final AlarmSettings? alarmSettings;

  @override
  EditAlarmScreenState createState() => EditAlarmScreenState();
}

class EditAlarmScreenState extends State<EditAlarmScreen> {
  late DateTime _alarmTime;
  late bool _isRepeating;
  late String _alarmSound;
  late String _alarmOffMethod;
  late String _alarmName;
  late String _textToType;
  late String _selectedGame;
  late int _requiredScore;
  late double _volume;
  late bool _useSystemVolume;

  final List<String> _daysOfWeek = ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'];
  final List<bool> _selectedDays = List.filled(7, false);

  final List<Map<String, String>> _availableSounds = [
    {'name': 'נוקיה', 'file': 'nokia.mp3'},
    {'name': 'אייפון', 'file': 'marimba.mp3'},
    {'name': 'מוצרט', 'file': 'mozart.mp3'},
    {'name': 'מצחיק', 'file': 'one_piece.mp3'},
    {'name': 'תקיעה', 'file': 'star_wars.mp3'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAlarmSettings();
  }

  void _initializeAlarmSettings() {
    if (widget.alarmSettings != null) {
      _alarmTime = widget.alarmSettings!.dateTime;
      _isRepeating = false;
      _alarmSound = widget.alarmSettings!.assetAudioPath;
      _alarmOffMethod = 'standard';
      _alarmName = widget.alarmSettings!.notificationTitle;
      _textToType = '';
      _selectedGame = 'snake';
      _requiredScore = 5;
      _volume = widget.alarmSettings?.volume ?? 1.0;
      _useSystemVolume = widget.alarmSettings?.volume == null;
    } else {
      _alarmTime = DateTime.now().add(const Duration(minutes: 1));
      _isRepeating = false;
      _alarmSound = 'assets/nokia.mp3';
      _alarmOffMethod = 'standard';
      _alarmName = '';
      _textToType = '';
      _selectedGame = 'snake';
      _requiredScore = 5;
      _volume = widget.alarmSettings?.volume ?? 1.0;
      _useSystemVolume = widget.alarmSettings?.volume == null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.alarmSettings == null ? 'הוספת התראה' : 'עריכת התראה',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          if (widget.alarmSettings != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteAlarm,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle(),
            _buildTimePicker(),
            _buildSoundAndVolumeSelection(),
            _buildAlarmOffMethod(),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAlarm() async {
    if (widget.alarmSettings != null) {
      await Alarm.stop(widget.alarmSettings!.id);
      Navigator.of(context).pop(true);
    }
  }

  Widget _buildTitle() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('שם ההתראה', style: Theme.of(context).textTheme.titleLarge),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'הזן שם להתראה',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),),
                ),
                initialValue: _alarmName,
                onChanged: (value) {
                  setState(() {
                    _alarmName = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('זמן התראה', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              width: 400,
              height: 70,
              child: TimePickerSpinnerPopUp(
                mode: CupertinoDatePickerMode.time,
                initTime: _alarmTime,
                barrierColor: Colors.black12,
                minuteInterval: 1,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                cancelText: 'ביטול',
                confirmText: 'אישור',
                radius: 15,
                pressType: PressType.singlePress,
                timeFormat: 'HH:mm',
                locale: const Locale('he', 'IL'),
                textStyle: const TextStyle(fontSize: 18),
                onChange: (dateTime) {
                  setState(() {
                    _alarmTime = DateTime(
                      _alarmTime.year,
                      _alarmTime.month,
                      _alarmTime.day,
                      dateTime.hour,
                      dateTime.minute,
                    );
                  });
                },
              ),
            ),
            SwitchListTile(
              title: const Text('חזור על ההתראה'),
              value: _isRepeating,
              onChanged: (bool value) {
                setState(() {
                  _isRepeating = value;
                });
              },
            ),
            if (_isRepeating)
              Wrap(
                spacing: 4,
                runSpacing: 5,
                children: List.generate(7, (index) {
                  return FilterChip(
                    label: Text(_daysOfWeek[index]),
                    selected: _selectedDays[index],
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedDays[index] = selected;
                      });
                    },
                    selectedColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundAndVolumeSelection() {
  final isCustomSound = !_alarmSound.startsWith('assets/');
  final displayValue = isCustomSound ? 'custom' : _alarmSound;

  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('צליל התראה', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            value: displayValue,
            onChanged: (String? newValue) {
              setState(() {
                if (newValue == 'custom') {
                  _pickCustomSound();
                } else {
                  _alarmSound = newValue!;
                }
              });
            },
            items: [
              ..._availableSounds.map<DropdownMenuItem<String>>((Map<String, String> sound) {
                return DropdownMenuItem<String>(
                  value: 'assets/${sound['file']}',
                  child: Text(
                    sound['name']!,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
              DropdownMenuItem<String>(
                value: 'custom',
                child: Text(
                  isCustomSound ? 'קובץ מותאם אישית' : 'בחר קובץ מותאם אישית',
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            isExpanded: true,
          ),
          if (isCustomSound)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'קובץ נבחר: ${_alarmSound.split('/').last}',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: _pickCustomSound,
                    child: const Text('שנה קובץ'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('השתמש בעוצמת הקול של המערכת'),
            value: _useSystemVolume,
            onChanged: (bool value) {
              setState(() {
                _useSystemVolume = value;
              });
            },
          ),
          if (!_useSystemVolume)
            Slider(
              value: _volume,
              divisions: 10,
              label: '${(_volume * 100).round()}%',
              onChanged: (double value) {
                setState(() {
                  _volume = value;
                });
              },
            ),
        ],
      ),
    ),
  );
}

Future<void> _pickCustomSound() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.audio,
  );

  if (result != null) {
    setState(() {
      _alarmSound = result.files.single.path!;
    });
  }
}

  Widget _buildAlarmOffMethod() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('שיטת כיבוי התראה',
                style: Theme.of(context).textTheme.titleLarge,),
            RadioListTile<String>(
              title: const Text('סטנדרטי'),
              value: 'standard',
              groupValue: _alarmOffMethod,
              onChanged: (String? value) {
                setState(() {
                  _alarmOffMethod = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('כתיבת טקסט'),
              value: 'text',
              groupValue: _alarmOffMethod,
              onChanged: (String? value) {
                setState(() {
                  _alarmOffMethod = value!;
                });
              },
            ),
            if (_alarmOffMethod == 'text')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'טקסט לכיבוי ההתראה',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _textToType = value;
                    });
                  },
                ),
              ),
            RadioListTile<String>(
              title: const Text('משחק'),
              value: 'game',
              groupValue: _alarmOffMethod,
              onChanged: (String? value) {
                setState(() {
                  _alarmOffMethod = value!;
                });
              },
            ),
            if (_alarmOffMethod == 'game') _buildGameSelection(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGameSelection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'בחר משחק',
              labelStyle: const TextStyle(fontSize: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            ),
            value: _selectedGame,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'snake', child: Text('סנייק', style: TextStyle(fontSize: 14))),
            ],
            onChanged: (String? value) {
              setState(() {
                _selectedGame = value!;
              });
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'ניקוד נדרש',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            ),
            keyboardType: TextInputType.number,
            initialValue: _requiredScore.toString(),
            onChanged: (value) {
              setState(() {
                _requiredScore = int.tryParse(value) ?? 100;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        onPressed: _saveAlarm,
        child: const Text(
          'שמור התראה',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _saveAlarm() async {
    final id = widget.alarmSettings?.id ??
        DateTime.now().millisecondsSinceEpoch % 100000;

    final selectedDaysIndices = _selectedDays
        .asMap()
        .entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    final notificationBody =
        'זמן להתעורר! $_alarmOffMethod|$_textToType|$_selectedGame|$_requiredScore|${selectedDaysIndices.join(',')}';

    DateTime scheduledDateTime = _alarmTime;
    if (!_isRepeating && scheduledDateTime.isBefore(DateTime.now())) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
    }

    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: scheduledDateTime,
      assetAudioPath: _alarmSound,
      volume: _useSystemVolume ? null : _volume,
      notificationTitle: _alarmName.isNotEmpty ? _alarmName : 'התראה',
      notificationBody: notificationBody,
    );

    if (_isRepeating) {
      for (var i = 0; i < 7; i++) {
        if (_selectedDays[i]) {
          final nextAlarmDay = _getNextWeekday(i);
          final nextAlarmTime = DateTime(
            nextAlarmDay.year,
            nextAlarmDay.month,
            nextAlarmDay.day,
            _alarmTime.hour,
            _alarmTime.minute,
          );

          final repeatingAlarmSettings = alarmSettings.copyWith(
            id: id + i + 1,
            dateTime: nextAlarmTime,
          );

          await Alarm.set(alarmSettings: repeatingAlarmSettings);
        }
      }
    } else {
      await Alarm.set(alarmSettings: alarmSettings);
    }

    final now = DateTime.now();
    final difference = scheduledDateTime.difference(now);
    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'ההתראה הוגדרה לעוד ${hours > 0 ? '$hours שעות ו-' : ''}$minutes דקות',
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 16),
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    Navigator.of(context).pop(true);
  }

  DateTime _getNextWeekday(int weekday) {
    final now = DateTime.now();
    var daysUntilNextWeekday = weekday - now.weekday;
    if (daysUntilNextWeekday <= 0) {
      daysUntilNextWeekday += 7;
    }
    return now.add(Duration(days: daysUntilNextWeekday));
  }

  
}
