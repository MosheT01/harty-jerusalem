import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class NidaaPage extends StatefulWidget {
  const NidaaPage({super.key});

  @override
  _NidaaPageState createState() => _NidaaPageState();
}

class _NidaaPageState extends State<NidaaPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final List<Map<String, dynamic>> calls = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCalls();
  }

  Future<void> _fetchCalls() async {
    try {
      DatabaseReference callsRef = _database.child('calls');
      DataSnapshot snapshot = await callsRef.get();
      setState(() {
        if (snapshot.exists) {
          calls.clear();
          Map<dynamic, dynamic> callData = snapshot.value as Map;
          callData.forEach((key, value) {
            calls.add({'key': key, ...Map<String, dynamic>.from(value)});
          });
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحميل البيانات: $e')),
      );
    }
  }

  Future<void> _addCall() async {
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
              title: const Text('إضافة نداء جديد'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'الاسم'),
                    onChanged: (value) {
                      name = value;
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                    onChanged: (value) {
                      phone = value;
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'وصف النداء'),
                    onChanged: (value) {
                      description = value;
                    },
                  ),
                  DropdownButton<String>(
                    value: urgency,
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        urgency = newValue!;
                      });
                    },
                    items: <String>['غير مستعجل', 'متوسط', 'مستعجل']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      String userId = _auth.currentUser!.uid;

                      DatabaseReference newCallRef = _database.child('calls').push();
                      await newCallRef.set({
                        'name': name,
                        'phone': phone,
                        'description': description,
                        'urgency': urgency,
                        'userId': userId,
                        'status': 'open',
                        'responses': {},
                      });
                      Navigator.of(context).pop();
                      _fetchCalls();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('فشل في إضافة النداء: $e')),
                      );
                    }
                  },
                  child: const Text('إضافة'),
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

  Future<void> _markCallAsDone(Map<String, dynamic> call) async {
    try {
      DatabaseReference callRef = _database.child('calls/${call['key']}');
      await callRef.update({'status': 'done'});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تعليم النداء كمكتمل!')),
      );
      _fetchCalls();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تعليم النداء كمكتمل: $e')),
      );
    }
  }

  Future<void> _deleteCall(Map<String, dynamic> call) async {
    try {
      DatabaseReference callRef = _database.child('calls/${call['key']}');
      await callRef.remove();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف النداء بنجاح!')),
      );
      _fetchCalls();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في حذف النداء: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: calls.length,
              itemBuilder: (context, index) {
                final call = calls[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    onTap: () => _viewCall(call),
                    title: Text(call['name']!),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('رقم الهاتف: ${call['phone']}'),
                        Text('وصف: ${call['description']}'),
                        Text('درجة الاستعجال: ${call['urgency']}'),
                      ],
                    ),
                    trailing: _auth.currentUser!.uid == call['userId']
                        ? PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'mark_done') {
                                _markCallAsDone(call);
                              } else if (value == 'delete') {
                                _deleteCall(call);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'mark_done',
                                child: Text('تعليم كمكتمل'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('حذف النداء'),
                              ),
                            ],
                          )
                        : null,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCall,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CallDetailPage extends StatefulWidget {
  final Map<String, dynamic> call;

  const CallDetailPage({required this.call, super.key});

  @override
  _CallDetailPageState createState() => _CallDetailPageState();
}

class _CallDetailPageState extends State<CallDetailPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final TextEditingController _commentController = TextEditingController();

  Future<void> _addComment(String callKey, String text) async {
    if (text.trim().isEmpty) return;

    try {
      String userId = _auth.currentUser!.uid;
      DatabaseReference commentsRef = _database.child('calls/$callKey/comments').push();
      await commentsRef.set({
        'userId': userId,
        'text': text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في إضافة التعليق: $e')),
      );
    }
  }

  Future<String> _getUserName(String userId) async {
    try {
      DatabaseReference userRef = _database.child('users/$userId');
      DataSnapshot snapshot = await userRef.get();
      if (snapshot.exists) {
        Map<String, dynamic> userData = Map<String, dynamic>.from(snapshot.value as Map);
        return userData['name'] ?? 'مستخدم مجهول';
      }
      return 'مستخدم مجهول';
    } catch (e) {
      return 'مستخدم مجهول';
    }
  }

  @override
  Widget build(BuildContext context) {
    final call = widget.call;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل النداء'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الاسم: ${call['name']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('رقم الهاتف: ${call['phone']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('وصف: ${call['description']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('درجة الاستعجال: ${call['urgency']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: _database.child('calls/${call['key']}/comments').onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return const Text('لا توجد تعليقات حالياً');
                  }

                  Map<dynamic, dynamic> comments = snapshot.data!.snapshot.value as Map;
                  List<Map<String, dynamic>> commentsList = comments.entries.map((entry) {
                    return {'key': entry.key, ...Map<String, dynamic>.from(entry.value)};
                  }).toList();

                  return ListView.builder(
                    itemCount: commentsList.length,
                    itemBuilder: (context, index) {
                      final comment = commentsList[index];
                      return FutureBuilder<String>(
                        future: _getUserName(comment['userId']),
                        builder: (context, userNameSnapshot) {
                          String userName = userNameSnapshot.data ?? 'مستخدم مجهول';
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(comment['text']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('بواسطة: $userName'),
                                  Text('تاريخ: ${comment['timestamp']}'),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'إضافة تعليق',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _addComment(call['key'], _commentController.text),
              child: const Text('إرسال التعليق'),
            ),
          ],
        ),
      ),
    );
  }
}
