import 'package:flutter/material.dart';
import 'package:lifeplanner/pages/home/notes_page.dart';

class NoteCTAWidget extends StatelessWidget {
  const NoteCTAWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotesPage()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.pink.shade50,
            border: Border.all(
              color: const Color(0xFFD4AF37), // gold
              width: 2,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.shade100.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.pin_end_sharp, color: Color(0xFFD4AF37)),
              SizedBox(width: 10),
              Text(
                'Add Your Notes',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD4AF37),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
