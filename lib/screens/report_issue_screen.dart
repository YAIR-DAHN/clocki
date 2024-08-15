import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ContactUsScreen extends StatefulWidget {
  @override
  _ContactUsScreenState createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedTopic = '';
  String _content = '';
  String _name = '';
  String _phone = '';
  String _deviceInfo = '';
  bool _isLoading = false;

  final List<String> _topics = [
    'סתם רציתי להגיד משהו',
    'יש לי רעיון לשיפור',
    'הערות בנוגע לאפליקציה',
  ];

  @override
  void initState() {
    super.initState();
    _getDeviceInfo();
  }

  Future<void> _getDeviceInfo() async {
    setState(() => _isLoading = true);

    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      PackageInfo packageInfo = await PackageInfo.fromPlatform();

      if (Theme.of(context).platform == TargetPlatform.android) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        _deviceInfo =
            'דגם: ${androidInfo.model}, גרסת אנדרואיד: ${androidInfo.version.release}';
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        _deviceInfo =
            'דגם: ${iosInfo.model}, גרסת iOS: ${iosInfo.systemVersion}';
      }

      _deviceInfo += ', גרסת אפליקציה: ${packageInfo.version}';
    } catch (e) {
      _deviceInfo = 'לא ניתן לקבל מידע על המכשיר: $e';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'yairdahn@gmail.com',
      query: _encodeQueryParameters(<String, String>{
        'subject': 'אפליקציית קלוקי - יצירת קשר: $_selectedTopic',
        'body':
            'תוכן הפנייה: $_content\n\nשם: $_name\nטלפון: $_phone\n\nמידע על המכשיר: $_deviceInfo',
      }),
    );

    _launchUrl(emailLaunchUri);
  }

  Future<void> _sendWhatsApp() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    final phoneNumber = '972583730000';
    final message = Uri.encodeComponent(
        '*אפליקציית קלוקי - יצירת קשר: $_selectedTopic*\n\nתוכן הפנייה: $_content\n\nשם: $_name\nטלפון: $_phone\n\nמידע על המכשיר: $_deviceInfo');

    final whatsappUrl = 'https://wa.me/$phoneNumber?text=$message';

    _launchUrl(Uri.parse(whatsappUrl));
  }

  Future<void> _launchUrl(Uri url) async {
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('לא ניתן לפתוח את האפליקציה: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('צור קשר'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'רוצה להגיד משהו? יש לך הערות / הארות? רעיונות נוספים לשיפור? נשמח שתכתוב לנו!',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'נושא הפנייה',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedTopic.isNotEmpty ? _selectedTopic : null,
                      validator: (value) =>
                          value == null ? 'אנא בחר נושא' : null,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedTopic = newValue!;
                        });
                      },
                      items:
                          _topics.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'תוכן הפנייה',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      validator: (value) =>
                          value!.isEmpty ? 'אנא הכנס את תוכן הפנייה' : null,
                      onSaved: (value) => _content = value!,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'שם (אופציונלי)',
                        border: OutlineInputBorder(),
                      ),
                      onSaved: (value) => _name = value ?? '',
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'טלפון (אופציונלי)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      onSaved: (value) => _phone = value ?? '',
                    ),
                    SizedBox(height: 24),
                    Text(
                      'מידע על המכשיר: $_deviceInfo',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                            icon: Icon(Icons.email),
                            label: Text('שלח במייל'),
                            onPressed: _sendEmail,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            )),
                        ElevatedButton.icon(
                            icon: Icon(FontAwesomeIcons.whatsapp),
                            label: Text('שלח בוואטסאפ'),
                            onPressed: _sendWhatsApp,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
