import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class NewsfeedPage extends StatefulWidget {
  const NewsfeedPage({super.key});

  @override
  _NewsfeedPageState createState() => _NewsfeedPageState();
}

class _NewsfeedPageState extends State<NewsfeedPage> {
  final DatabaseReference postsRef = FirebaseDatabase.instance.ref('posts');
  final DatabaseReference usersRef = FirebaseDatabase.instance.ref('users');
  final FirebaseStorage storage = FirebaseStorage.instance;
  final List<Map<String, dynamic>> posts = [];
  String postContent = '';
  File? selectedImage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    postsRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          posts.clear();
          data.forEach((key, value) {
            final post = Map<String, dynamic>.from(value as Map);
            final comments = (post['comments'] as Map?)?.entries.map((e) {
                  return {
                    'id': e.key,
                    ...Map<String, dynamic>.from(e.value as Map),
                  };
                }).toList() ??
                [];
            posts.add({
              'id': key,
              ...post,
              'comments': comments,
            });
          });
          isLoading = false;
        });
      } else {
        setState(() {
          posts.clear();
          isLoading = false;
        });
      }
    });
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(String postId) async {
    if (selectedImage == null) return null;

    try {
      final ref = storage.ref().child('post_images/$postId.jpg');
      await ref.putFile(selectedImage!);
      final downloadUrl = await ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل تحميل الصورة: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  Future<void> _addPost() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لم يتم تسجيل الدخول'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userSnapshot = await usersRef.child(currentUser.uid).get();
    if (!userSnapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر الحصول على معلومات المستخدم'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
    final userAddress = userData['address'] ?? 'عنوان غير متوفر';

    bool isUploading = false; // New state variable

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              title: const Text(
                'إضافة منشور جديد',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              content: isUploading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 10),
                          Text('جاري رفع المنشور...')
                        ],
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            labelText: 'محتوى المنشور',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          maxLines: 3,
                          keyboardType: TextInputType.multiline,
                          textDirection: TextDirection.rtl,
                          onChanged: (value) {
                            postContent = value;
                          },
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('اختر صورة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black,
                          ),
                        ),
                        if (selectedImage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Image.file(
                              selectedImage!,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                      ],
                    ),
              actions: isUploading
                  ? []
                  : [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          setState(() {
                            selectedImage = null;
                          });
                        },
                        child: const Text('إلغاء', textAlign: TextAlign.center),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            if (postContent.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('يرجى كتابة محتوى المنشور'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            setState(() {
                              isUploading = true; // Start uploading
                            });

                            final postKey = postsRef.push().key;
                            if (postKey == null) {
                              throw 'تعذر إنشاء مفتاح المنشور';
                            }

                            String? imageUrl;
                            if (selectedImage != null) {
                              imageUrl = await _uploadImage(postKey);
                            }

                            await postsRef.child(postKey).set({
                              'content': postContent,
                              'authorId': currentUser.uid,
                              'authorName':
                                  '${userData['firstName']} ${userData['lastName']}',
                              'authorAddress': userAddress,
                              'likes': [],
                              'dislikes': [],
                              'comments': [],
                              'imageUrl': imageUrl,
                              'timestamp': DateTime.now().toIso8601String(),
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم إضافة المنشور بنجاح!'),
                                backgroundColor: Colors.green,
                              ),
                            );

                            setState(() {
                              postContent = '';
                              selectedImage = null;
                            });
                            Navigator.of(context).pop();
                          } catch (e) {
                            setState(() {
                              isUploading = false; // Stop uploading
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('حدث خطأ أثناء الإضافة: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
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

  void _likePost(String postId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final postRef = postsRef.child(postId);
    final snapshot = await postRef.get();

    if (snapshot.exists) {
      final postData = Map<String, dynamic>.from(snapshot.value as Map);
      final likes = List<String>.from(postData['likes'] ?? []);
      final dislikes = List<String>.from(postData['dislikes'] ?? []);

      if (likes.contains(currentUser.uid)) {
        likes.remove(currentUser.uid);
      } else {
        likes.add(currentUser.uid);
        dislikes.remove(currentUser.uid); // Ensure dislike is removed
      }

      await postRef.update({'likes': likes, 'dislikes': dislikes});
    }
  }

  void _dislikePost(String postId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final postRef = postsRef.child(postId);
    final snapshot = await postRef.get();

    if (snapshot.exists) {
      final postData = Map<String, dynamic>.from(snapshot.value as Map);
      final likes = List<String>.from(postData['likes'] ?? []);
      final dislikes = List<String>.from(postData['dislikes'] ?? []);

      if (dislikes.contains(currentUser.uid)) {
        dislikes.remove(currentUser.uid);
      } else {
        dislikes.add(currentUser.uid);
        likes.remove(currentUser.uid); // Ensure like is removed
      }

      await postRef.update({'likes': likes, 'dislikes': dislikes});
    }
  }

  void _addReply(String postId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String commentContent = '';
        return AlertDialog(
          title: const Text('إضافة تعليق', textAlign: TextAlign.right),
          content: TextField(
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              labelText: 'اكتب تعليقك هنا',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            maxLines: 3,
            onChanged: (value) {
              commentContent = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('إلغاء', textAlign: TextAlign.center),
            ),
            ElevatedButton(
              onPressed: () async {
                if (commentContent.trim().isEmpty) {
                  return;
                }
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) return;

                final userSnapshot =
                    await usersRef.child(currentUser.uid).get();
                if (!userSnapshot.exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تعذر الحصول على معلومات المستخدم'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final userData =
                    Map<String, dynamic>.from(userSnapshot.value as Map);
                final postRef = postsRef.child(postId).child('comments');
                await postRef.push().set({
                  'content': commentContent,
                  'authorId': currentUser.uid,
                  'authorName':
                      '${userData['firstName']} ${userData['lastName']}',
                  'timestamp': DateTime.now().toIso8601String(),
                });
                Navigator.of(context).pop();
              },
              child: const Text('إضافة', textAlign: TextAlign.center),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أخبار حارتي', textAlign: TextAlign.center),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : posts.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد منشورات حالياً',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final imageUrl = post['imageUrl'] as String?;
                    final likes = List<String>.from(post['likes'] ?? []);
                    final dislikes = List<String>.from(post['dislikes'] ?? []);
                    final comments =
                        List<Map<String, dynamic>>.from(post['comments'] ?? []);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      elevation: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: Colors.white,
                                      child: Icon(Icons.person,
                                          color: Colors.black),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          post['authorName'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          DateTime.parse(post['timestamp'])
                                              .toLocal()
                                              .toString()
                                              .substring(0, 16)
                                              .replaceFirst('T', ' '),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (imageUrl != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          15.0), // Rounded corners
                                      child: GestureDetector(
                                        onTap: () {
                                          // Open full-screen image view
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return Dialog(
                                                child: InteractiveViewer(
                                                  child: Image.network(
                                                    imageUrl,
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                        child: Image.network(
                                          imageUrl,
                                          height: 200, // Adjusted height
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        (loadingProgress
                                                                .expectedTotalBytes ??
                                                            1)
                                                    : null,
                                              ),
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Center(
                                              child: Text(
                                                'فشل تحميل الصورة',
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                Text(
                                  post['content'] ?? '',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.thumb_up),
                                          color: likes.contains(FirebaseAuth
                                                  .instance.currentUser?.uid)
                                              ? Colors.blue
                                              : Colors.grey,
                                          onPressed: () =>
                                              _likePost(post['id']),
                                        ),
                                        Text(
                                          '${likes.length}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.thumb_down),
                                          color: dislikes.contains(FirebaseAuth
                                                  .instance.currentUser?.uid)
                                              ? Colors.red
                                              : Colors.grey,
                                          onPressed: () =>
                                              _dislikePost(post['id']),
                                        ),
                                        Text(
                                          '${dislikes.length}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.comment),
                                      onPressed: () => _addReply(post['id']),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (comments.isNotEmpty)
                            ExpansionTile(
                              title: Text(
                                'التعليقات (${comments.length})',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              children: comments.map((comment) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4.0, horizontal: 16.0),
                                  child: Row(
                                    children: [
                                      const CircleAvatar(
                                        backgroundColor: Colors.white,
                                        child: Icon(Icons.person,
                                            color: Colors.black),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              comment['authorName'] ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              comment['content'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPost,
        child: const Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }
}
