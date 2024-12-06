import 'package:flutter/material.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample static events data
    final events = [
      {
        'title': 'مهرجان الحي الصيفي',
        'date': '2024-12-15',
        'time': '5:00 مساءً',
        'location': 'حديقة الحي',
        'description': 'انضم إلينا لقضاء وقت ممتع مع العائلة والجيران.'
      },
      {
        'title': 'تنظيف الحي',
        'date': '2024-12-20',
        'time': '9:00 صباحًا',
        'location': 'الساحة العامة',
        'description': 'فعالية تنظيف الحي بمشاركة الجميع لبيئة أجمل.'
      },
      {
        'title': 'بازار الحي الشتوي',
        'date': '2024-12-25',
        'time': '3:00 مساءً',
        'location': 'مركز الحي الثقافي',
        'description': 'عرض منتجات الحي المحلي في بازار الشتاء السنوي.'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('الأحداث', style: TextStyle(fontSize: 20)),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title']!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        event['date']!,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        event['time']!,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        event['location']!,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: Colors.grey),
                  Text(
                    event['description']!,
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
