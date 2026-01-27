import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/gradient_layout.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 86,
                          height: 86,
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/icons/home-edit.svg',
                              width: 86,
                              height: 86,
                              color: grey02,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No listings yet.',
                          style: TextStyle(
                            fontSize: 13,
                            color: grey02,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'List your shared house to get started.',
                          style: TextStyle(
                            fontSize: 13,
                            color: grey02,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
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
