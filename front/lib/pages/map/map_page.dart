import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front/constants/colors.dart';
import 'package:front/widgets/custom_header.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController mapController = MapController();
  final LatLng targetLocation = LatLng(-37.74159952548629, 144.99780308175087);
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _selectedFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    // 검색 로직
    print('Searching for: $query');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // 지도 (전체 화면)
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: targetLocation,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.front',
              ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: targetLocation,
                    width: 40,
                    height: 40,
                    child: SvgPicture.asset(
                      'assets/icons/pin.svg',
                      width: 24,
                      height: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 상단 검색바와 필터
          Column(
            children: [
              // CustomHeader with Search Bar
              CustomHeader(
                showBack: true,
                toolbarHeight: 72,
                center: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.14),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        autofocus: true,
                        cursorColor: grey03,
                        onSubmitted: _performSearch,
                        decoration: InputDecoration(
                          border: InputBorder.none,

                          prefixIcon: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 2, 12, 0),
                            child: SvgPicture.asset(
                              'assets/icons/pin.svg',
                              width: 20,
                              height: 20,
                              color: green,
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),

                          hintText: 'Where do you want to go?',
                          hintStyle: TextStyle(
                            color: grey03,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),

                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),

                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: grey03,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: SvgPicture.asset(
                                    'assets/icons/search.svg',
                                    width: 20,
                                    height: 20,
                                    color: grey03,
                                  ),
                                ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                ),
              ),

              // Filter Chips
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),

                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    children: [
                      _filterChip(
                        'Bus stop',
                        selected: _selectedFilter == 'bus',
                        type: 'bus',
                      ),
                      _filterChip(
                        'Tram stop',
                        selected: _selectedFilter == 'tram',
                        type: 'tram',
                      ),
                      _filterChip(
                        'Train station',
                        selected: _selectedFilter == 'train',
                        type: 'train',
                      ),
                      _filterChip(
                        'Restaurant',
                        selected: _selectedFilter == 'restaurant',
                        type: 'restaurant',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String text, {bool selected = false, String? type}) {
    return GestureDetector(
      onTap: type != null
          ? () {
              setState(() => _selectedFilter = type);
              print('Filter selected: $type');
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(right: 5),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        decoration: BoxDecoration(
          color: selected ? green : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : dark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
