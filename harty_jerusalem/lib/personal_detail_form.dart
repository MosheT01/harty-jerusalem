import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:geolocator/geolocator.dart';

class PersonalDetailsForm extends StatefulWidget {
  const PersonalDetailsForm({Key? key}) : super(key: key);

  @override
  State<PersonalDetailsForm> createState() => _PersonalDetailsFormState();
}

class _PersonalDetailsFormState extends State<PersonalDetailsForm> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController idNumberController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final dropDownKey = GlobalKey<DropdownSearchState>();
  String? selectedOccupation;

  final List<String> occupationList = [
    '🔌 كهربائي',
    '🚑 مسعف',
    '⚙️ مهندس',
    '🩺 طبيب',
    '📚 معلم',
    '🌾 مزارع',
    '👨‍🍳 طاهٍ',
    '👷 عامل بناء',
    '👨‍💻 مبرمج',
    '👨‍🎨 فنان',
    '👨‍🚒 رجل إطفاء',
    '👮‍♂️ شرطي',
    '🚚 سائق شاحنة',
    '✈️ طيار',
    '🧑‍🔧 ميكانيكي',
    '🧑‍🏫 أستاذ جامعي',
    '🧑‍⚖️ محامي',
    '🧑‍🔬 عالم',
    '🧑‍🎤 مغني',
    '🧑‍🍳 خباز',
    'أخرى',
  ];

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    idNumberController.dispose();
    phoneNumberController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفض إذن الوصول إلى الموقع.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم رفض إذن الموقع دائمًا.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      await _checkLocationPermission();

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        addressController.text =
            'Latitude: ${position.latitude}, Longitude: ${position.longitude}';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في الحصول على الموقع: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitDetails() async {
    if (_formKey.currentState!.validate()) {
      if (addressController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى تحديد العنوان.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        String userId = FirebaseAuth.instance.currentUser!.uid;

        // Update user details in the database
        DatabaseReference userRef =
            FirebaseDatabase.instance.ref('users/$userId');
        await userRef.update({
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'idNumber': idNumberController.text.trim(),
          'phoneNumber': phoneNumberController.text.trim(),
          'address': addressController.text.trim(),
          'occupation': selectedOccupation ?? 'غير محدد',
          'firstLogin': false,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث البيانات بنجاح!')),
        );

        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحديث البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إكمال البيانات الشخصية')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Preview card
            Card(
              color: Colors.teal[50],
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.person, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${firstNameController.text} ${lastNameController.text}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedOccupation != null
                                ? 'الوظيفة: $selectedOccupation'
                                : 'الوظيفة: ---',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Form
            Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  children: [
                    TextFormField(
                      controller: firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم الأول',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال الاسم الأول';
                        }
                        return null;
                      },
                      autofillHints: const [AutofillHints.givenName],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم الأخير',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال الاسم الأخير';
                        }
                        return null;
                      },
                      autofillHints: const [AutofillHints.familyName],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: idNumberController,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهوية',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال رقم الهوية';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneNumberController,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال رقم الهاتف';
                        }
                        if (!RegExp(r'^\+?\d{7,15}$').hasMatch(value)) {
                          return 'يرجى إدخال رقم هاتف صالح';
                        }
                        return null;
                      },
                      autofillHints: const [AutofillHints.telephoneNumber],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'العنوان',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      readOnly: true,
                      onTap: _getCurrentLocation,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى تحديد العنوان';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Occupation DropdownSearch
                    DropdownSearch<String>(
                      key: dropDownKey,
                      selectedItem: 'اختر الوظيفة',
                      items: (f, cs) => occupationList,
                      popupProps: PopupProps.menu(
                        disabledItemFn: (item) => item == '👨‍🍳 طاهٍ',
                        fit: FlexFit.loose,
                        showSearchBox: true,
                        searchDelay: const Duration(milliseconds: 0),
                      ),
                      decoratorProps: const DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: 'الوظيفة',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          selectedOccupation = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى اختيار الوظيفة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitDetails,
                      child: const Text('حفظ البيانات'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
