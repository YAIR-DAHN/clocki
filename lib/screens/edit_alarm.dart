import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:file_picker/file_picker.dart';

class EditAlarmScreen extends StatefulWidget {
  final AlarmSettings? alarmSettings;

  const EditAlarmScreen({Key? key, this.alarmSettings}) : super(key: key);

  @override
  _EditAlarmScreenState createState() => _EditAlarmScreenState();
}

class _EditAlarmScreenState extends State<EditAlarmScreen> {
  late DateTime _alarmTime;
  late bool _isRepeating;
  late String _alarmSound;
  late String _alarmOffMethod;
  late String _customText;
  late String _selectedGame;
  late int _requiredScore;
  late double _volume;
  late bool _useSystemVolume;

  final List<String> _daysOfWeek = ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'];
  final List<bool> _selectedDays = List.filled(7, false);

  final List<Map<String, String>> _availableSounds = [
    {"name": "נוקיה", "file": "nokia.mp3"},
    {"name": "אייפון", "file": "marimba.mp3"},
    {"name": "מוצרט", "file": "mozart.mp3"},
    {"name": "מצחיק", "file": "one_piece.mp3"},
    {"name": "תקיעה", "file": "star_wars.mp3"},
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
      _customText = '';
      _selectedGame = 'snake';
      _requiredScore = 5;
      _volume = widget.alarmSettings?.volume ?? 1.0;
      _useSystemVolume = widget.alarmSettings?.volume == null;
    } else {
      _alarmTime = DateTime.now().add(const Duration(minutes: 1));
      _isRepeating = false;
      _alarmSound = 'assets/nokia.mp3';
      _alarmOffMethod = 'standard';
      _customText = '';
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
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          if (widget.alarmSettings != null)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deleteAlarm,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle(),
            _buildTimePicker(),
            // SizedBox(height: 24),
            // _buildRepeatOption(),
            // SizedBox(height: 24),
            _buildSoundAndVolumeSelection(),
            // _buildSoundSelection(),
            // SizedBox(: 24),
            // _buildVolumeSelection(), // הוספנו את זה
            // SizedBox(height: 24),
            _buildAlarmOffMethod(),
            SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  void _deleteAlarm() async {
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('שם ההתראה', style: Theme.of(context).textTheme.titleLarge),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'הזן שם להתראה',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                initialValue: _customText,
                onChanged: (value) {
                  setState(() {
                    _customText = value;
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('זמן התראה', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_alarmTime),
                );
                if (picked != null) {
                  setState(() {
                    _alarmTime = DateTime(
                      _alarmTime.year,
                      _alarmTime.month,
                      _alarmTime.day,
                      picked.hour,
                      picked.minute,
                    );
                  });
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: Theme.of(context).colorScheme.primary),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      TimeOfDay.fromDateTime(_alarmTime).format(context),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Icon(Icons.access_time,
                        color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
            ),
            SwitchListTile(
              title: Text('חזור על ההתראה'),
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

  // Widget _buildRepeatOption() {
  //   return Card(
  //     elevation: 4,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //     child: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text('חזרה', style: Theme.of(context).textTheme.titleLarge),

  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildSoundAndVolumeSelection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('צליל התראה', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8), // הגדרת גודל התיבה
              ),
              value: _alarmSound,
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
                ..._availableSounds
                    .map<DropdownMenuItem<String>>((Map<String, String> sound) {
                  return DropdownMenuItem<String>(
                    value: 'assets/${sound['file']}',
                    child: Text(
                      sound['name']!,
                      style: TextStyle(
                          fontSize: 14), // הגדרת גודל הטקסט של הפריטים
                      overflow:
                          TextOverflow.ellipsis, // הוספת אליפסיס לטקסט ארוך
                    ),
                  );
                }).toList(),
                DropdownMenuItem<String>(
                  value: 'custom',
                  child: Text(
                    'בחר קובץ מותאם אישית',
                    style:
                        TextStyle(fontSize: 14), // הגדרת גודל הטקסט של הפריטים
                    overflow: TextOverflow.ellipsis, // הוספת אליפסיס לטקסט ארוך
                  ),
                ),
              ],
              isExpanded: true, // הגדרת התיבה שתתפוס את כל הרוחב הזמין
            ),
            if (_alarmSound.startsWith('/'))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      'קובץ נבחר: ${_alarmSound.split('/').last}',
                      style: TextStyle(
                          fontSize: 12), // גודל טקסט קטן יותר לשם הקובץ
                    ),
                  ),
                ),
              ),
            SizedBox(height: 16),
            // Text('עוצמת קול', style: Theme.of(context).textTheme.titleLarge),
            SwitchListTile(
              title: Text('השתמש בעוצמת הקול של המערכת'),
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
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: (_volume * 100).round().toString() + '%',
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

  Widget _buildAlarmOffMethod() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text('שם ההתראה', style: Theme.of(context).textTheme.titleLarge),
            // Padding(
            //   padding: const EdgeInsets.symmetric(vertical: 8.0),
            //   child: TextFormField(
            //     decoration: InputDecoration(
            //       labelText: 'הזן שם להתראה',
            //       border: OutlineInputBorder(
            //           borderRadius: BorderRadius.circular(8)),
            //     ),
            //     initialValue: _customText,
            //     onChanged: (value) {
            //       setState(() {
            //         _customText = value;
            //       });
            //     },
            //   ),
            // ),
            SizedBox(height: 16),
            Text('שיטת כיבוי התראה',
                style: Theme.of(context).textTheme.titleLarge),
            RadioListTile<String>(
              title: Text('סטנדרטי'),
              value: 'standard',
              groupValue: _alarmOffMethod,
              onChanged: (String? value) {
                setState(() {
                  _alarmOffMethod = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: Text('כתיבת טקסט'),
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'הזן טקסט',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _customText = value;
                    });
                  },
                ),
              ),
            RadioListTile<String>(
              title: Text('משחק'),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'בחר משחק',
              labelStyle: TextStyle(fontSize: 14), // הגדרת גודל הטקסט של התווית
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.symmetric(
                  vertical: 10, horizontal: 10), // הגדרת גודל התיבה
            ),
            value: _selectedGame,
            isExpanded: true, // הגדרת התיבה שתתפוס את כל הרוחב הזמין
            items: const [
              DropdownMenuItem(
                value: 'snake',
                child: Text('נחש',
                    style:
                        TextStyle(fontSize: 14)), // הגדרת גודל הטקסט של הפריטים
              ),
              DropdownMenuItem(
                value: 'starwars',
                child: Text('מלחמת הכוכבים',
                    style:
                        TextStyle(fontSize: 14)), // הגדרת גודל הטקסט של הפריטים
              ),
            ],
            onChanged: (String? value) {
              setState(() {
                _selectedGame = value!;
              });
            },
          ),
          SizedBox(height: 20),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'ניקוד נדרש',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.symmetric(
                  vertical: 10, horizontal: 10), // הגדרת גודל התיבה
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
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        onPressed: _saveAlarm,
        child: Text(
          'שמור התראה',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _saveAlarm() async {
    final id = widget.alarmSettings?.id ??
        DateTime.now().millisecondsSinceEpoch % 100000;

    final selectedDaysIndices = _selectedDays
        .asMap()
        .entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    String alarmOffDetails = '';
    if (_alarmOffMethod == 'text') {
      alarmOffDetails = _customText;
    } else if (_alarmOffMethod == 'game') {
      alarmOffDetails = '$_selectedGame|$_requiredScore';
    }

    final notificationBody =
        'זמן להתעורר! $_alarmOffMethod|$_customText|$_selectedGame|$_requiredScore|${selectedDaysIndices.join(',')}';
    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: _alarmTime,
      assetAudioPath: _alarmSound,
      loopAudio: true,
      vibrate: true,
      volume: _useSystemVolume ? null : _volume,
      fadeDuration: 0.0,
      notificationTitle: _customText.isNotEmpty ? _customText : 'התראה',
      notificationBody: notificationBody,
      enableNotificationOnKill: true,
    );

    if (_isRepeating) {
      for (int i = 0; i < 7; i++) {
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

    Navigator.of(context).pop(true);
  }

  DateTime _getNextWeekday(int weekday) {
    DateTime now = DateTime.now();
    int daysUntilNextWeekday = weekday - now.weekday;
    if (daysUntilNextWeekday <= 0) {
      daysUntilNextWeekday += 7;
    }
    return now.add(Duration(days: daysUntilNextWeekday));
  }

  Future<void> _pickCustomSound() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      setState(() {
        _alarmSound = result.files.single.path!;
      });
    } else {
      setState(() {
        _alarmSound = 'assets/nokia.mp3';
      });
    }
  }
}
