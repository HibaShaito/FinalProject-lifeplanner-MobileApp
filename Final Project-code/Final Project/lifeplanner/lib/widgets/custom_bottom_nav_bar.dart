import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.calendar_month,
      Icons.attach_money,
      Icons.home,
      Icons.favorite,
      Icons.chat,
    ];

    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: const Color(0xFFFFCD7D),
        border: Border.all(
          color: Colors.black.withAlpha(25),
        ), // approx. 10% opacity
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(icons.length, (index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onTap(index),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isSelected
                        ? Colors.white.withAlpha(77)
                        : Colors.transparent, // 30% opacity
              ),
              child: Icon(
                icons[index],
                size: 30,
                color:
                    isSelected
                        ? Colors.black
                        : Colors.black.withAlpha(153), // 60% opacity
              ),
            ),
          );
        }),
      ),
    );
  }
}
