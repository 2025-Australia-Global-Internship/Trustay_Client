import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/gradient_layout.dart';

class ListingPage extends StatefulWidget {
  const ListingPage({super.key});

  @override
  State<ListingPage> createState() => _ListingPage();
}

class _ListingPage extends State<ListingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientLayout(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomHeader(
                  center: Text(
                    'Listings',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: dark,
                    ),
                  ),
                  showBack: true,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 여기에 Listing 아이템들을 넣으면 됨
                      Container(
                        height: 200,
                        color: Colors.grey[300],
                        margin: const EdgeInsets.only(bottom: 10),
                      ),
                      Container(
                        height: 200,
                        color: Colors.grey[400],
                        margin: const EdgeInsets.only(bottom: 10),
                      ),
                      // ... 더 많은 아이템
                    ],
                  ),
                ),
              ],
            ),

            // 오른쪽 아래 버튼
            Positioned(
              bottom: 20,
              right: 20,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/sharehouse_create');
                },
                icon: const Icon(Icons.add, size: 20, color: Colors.white),
                label: const Text(
                  'Create Listing',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
