import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

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
    'דיווח על תקלה',
  ];

  @override
  void initState() {
    super.initState();
    _getDeviceInfo();
  }

  Future<void> _getDeviceInfo() async {
    setState(() => _isLoading = true);

    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      if (Theme.of(context).platform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceInfo = 'דגם: ${androidInfo.model}, גרסת אנדרואיד: ${androidInfo.version.release}';
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceInfo = 'דגם: ${iosInfo.model}, גרסת iOS: ${iosInfo.systemVersion}';
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
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    final emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'yairdahn@gmail.com',
      query: _encodeQueryParameters(<String, String>{
        'subject': 'אפליקציית קלוקי - יצירת קשר: $_selectedTopic',
        'body': 'תוכן הפנייה: $_content\n\nשם: $_name\nטלפון: $_phone\n\nמידע על המכשיר: $_deviceInfo',
      }),
    );

    _launchUrl(emailLaunchUri);
  }

  Future<void> _sendWhatsApp() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    const phoneNumber = '972583730000';
    final message = Uri.encodeComponent(
        '*אפליקציית קלוקי - יצירת קשר: $_selectedTopic*\n\nתוכן הפנייה: $_content\n\nשם: $_name\nטלפון: $_phone\n\nמידע על המכשיר: $_deviceInfo',);

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
        SnackBar(content: Text('לא הצלחנו לפתוח את האפליקציה')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('צור קשר'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'נשמח שתכתוב לנו!',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.blue[800]),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'נושא הפנייה',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                        value: _selectedTopic.isNotEmpty ? _selectedTopic : null,
                        validator: (value) => value == null ? 'אנא בחר נושא' : null,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedTopic = newValue!;
                          });
                        },
                        items: _topics.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        isExpanded: true,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'תוכן הפנייה',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                        maxLines: 5,
                        validator: (value) => value!.isEmpty ? 'אנא הכנס את תוכן הפנייה' : null,
                        onSaved: (value) => _content = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'שם (אופציונלי)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                        onSaved: (value) => _name = value ?? '',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'טלפון (אופציונלי)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                        keyboardType: TextInputType.phone,
                        onSaved: (value) => _phone = value ?? '',
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'מידע על המכשיר: $_deviceInfo',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.email, size: 18),
                              label: const Text('שלח במייל', style: TextStyle(fontSize: 14)),
                              onPressed: _sendEmail,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(FontAwesomeIcons.whatsapp, size: 18),
                              label: const Text('שלח בוואטסאפ', style: TextStyle(fontSize: 14)),
                              onPressed: _sendWhatsApp,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}