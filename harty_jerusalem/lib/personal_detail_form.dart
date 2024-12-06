import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class PersonalDetailsForm extends StatefulWidget {
  const PersonalDetailsForm({Key? key}) : super(key: key);

  @override
  State<PersonalDetailsForm> createState() => _PersonalDetailsFormState();
}

class _PersonalDetailsFormState extends State<PersonalDetailsForm> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController idNumberController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _submitDetails() async {
    if (_formKey.currentState!.validate()) {
      try {
        String userId = FirebaseAuth.instance.currentUser!.uid;

        // Update user details in the database
        DatabaseReference userRef =
            FirebaseDatabase.instance.ref('users/$userId');
        await userRef.update({
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'idNumber': idNumberController.text.trim(),
          'address': addressController.text.trim(),
          'firstLogin': false, // Mark first login as complete
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث البيانات بنجاح!')),
        );

        // Navigate to the home page
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('فشل تحديث البيانات: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إكمال البيانات الشخصية')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: 'الاسم الأول'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال الاسم الأول';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: 'الاسم الأخير'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال الاسم الأخير';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: idNumberController,
                decoration: const InputDecoration(labelText: 'رقم الهوية'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال رقم الهوية';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'العنوان'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال العنوان';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitDetails,
                child: const Text('حفظ البيانات'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
