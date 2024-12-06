import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class NidaaPage extends StatefulWidget {
  const NidaaPage({super.key});

  @override
  _NidaaPageState createState() => _NidaaPageState();
}

class _NidaaPageState extends State<NidaaPage> {
  final List<Map<String, dynamic>> calls = [];
  File? _selectedImage;

  void _addCall() {
    String name = '';
    String phone = '';
    String description = '';
    String urgency = 'غير مستعجل';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              title: const Text(
                'إضافة نداء جديد',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        labelText: 'الاسم',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      onChanged: (value) {
                        name = value;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        labelText: 'رقم الهاتف',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (value) {
                        phone = value;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        labelText: 'وصف النداء',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        description = value;
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: urgency,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          urgency = newValue!;
                        });
                      },
                      items: <String>['غير مستعجل', 'متوسط', 'مستعجل']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, textAlign: TextAlign.right),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setDialogState(() {
                            _selectedImage = File(pickedFile.path);
                          });
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('إضافة صورة من المعرض'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    if (_selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.file(
                            _selectedImage!,
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('إلغاء', textAlign: TextAlign.center),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      calls.add({
                        'name': name,
                        'phone': phone,
                        'description': description,
                        'urgency': urgency,
                        'image': _selectedImage,
                      });
                      _selectedImage = null;
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text('إضافة', textAlign: TextAlign.center),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _viewCall(Map<String, dynamic> call) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallDetailPage(call: call),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('النداءات', textAlign: TextAlign.right),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: calls.isEmpty
          ? const Center(
              child: Text(
                'لا توجد نداءات حالياً',
                style: TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: calls.length,
              itemBuilder: (context, index) {
                final call = calls[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  elevation: 5,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    onTap: () => _viewCall(call),
                    title: Text(
                      call['name']!,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(height: 5),
                        Text('رقم الهاتف: ${call['phone']}', textAlign: TextAlign.right),
                        const SizedBox(height: 5),
                        Text('وصف: ${call['description']}', textAlign: TextAlign.right),
                        const SizedBox(height: 5),
                        Text('درجة الاستعجال: ${call['urgency']}', textAlign: TextAlign.right),
                      ],
                    ),
                    trailing: call['image'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.file(
                              call['image'],
                              height: 50,
                              width: 50,
                              fit: BoxFit.cover,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCall,
        child: const Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initImagePicker();
  }

  void _initImagePicker() async {
    await ImagePicker.platform;
  }
}

class CallDetailPage extends StatelessWidget {
  final Map<String, dynamic> call;

  const CallDetailPage({required this.call, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(call['name']!, textAlign: TextAlign.right),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'رقم الهاتف: ${call['phone']}',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 10),
            Text(
              'وصف: ${call['description']}',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 10),
            Text(
              'درجة الاستعجال: ${call['urgency']}',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 20),
            if (call['image'] != null)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: Image.file(
                    call['image'],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
