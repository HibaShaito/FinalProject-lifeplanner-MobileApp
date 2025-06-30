import 'package:flutter/material.dart';

class QuoteCard extends StatelessWidget {
  final String quote;
  final String author;
  final String imageAsset;

  const QuoteCard({
    required this.quote,
    required this.author,
    this.imageAsset = 'assets/images/motivation.png',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // height = 0.5 * width for a 2:1 aspect ratio; tweak as you like
    final imageHeight = screenWidth * 0.5;
    const borderColor = Color(0xFFFFCD7D);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: borderColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            //── Better image fill ───────────────────────────────────
            Image.asset(
              imageAsset,
              width: double.infinity,
              height: imageHeight,
              fit: BoxFit.cover,
            ),
            //──────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"$quote"',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '- $author',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
