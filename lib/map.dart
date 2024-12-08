import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapPage extends StatefulWidget {
  final String friendUid;

  const MapPage({super.key, required this.friendUid});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  NLatLng? friendLocation; // 친구의 위치
  String? exerciseStartTime; // 운동 시작 시간

  @override
  void initState() {
    super.initState();
    _fetchFriendLocationAndTime();
  }

  // Firestore에서 친구 위치 및 시간 정보 가져오기
  Future<void> _fetchFriendLocationAndTime() async {
    try {
      final friendDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.friendUid)
          .get();

      if (friendDoc.exists) {
        final data = friendDoc.data();
        if (data != null && data['location'] != null) {
          final location = data['location'];
          final timestamp = location['timestamp'] as Timestamp;

          setState(() {
            friendLocation = NLatLng(
              location['latitude'],
              location['longitude'],
            );
            exerciseStartTime =
            "${timestamp.toDate().hour > 12 ? '오후' : '오전'} "
                "${timestamp.toDate().hour % 12}:${timestamp.toDate().minute.toString().padLeft(2, '0')}";
          });
        }
      }
    } catch (e) {
      print("Error fetching friend's location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "친구의 위치",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: friendLocation == null
          ? const Center(
        child: CircularProgressIndicator(), // 로딩 인디케이터
      )
          : Column(
        children: [
          // 운동 시작 시간 표시
          Container(
            padding: const EdgeInsets.all(20.0),
            width: double.infinity,
            color: Colors.blueGrey.shade900,
            child: Text(
              "운동 시작 시간: $exerciseStartTime",
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // 네이버 맵 표시
          Expanded(
            child:
            NaverMap(

              options: NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(
                  target: friendLocation!, // 친구 위치를 중심으로 설정
                  zoom: 14, // 적절한 줌 레벨 설정
                ),
              ),
              onMapReady: (controller) async {
                final marker = NMarker(
                  id: 'friend_marker',
                  position: friendLocation!,
                );



                controller.addOverlayAll({marker});
                controller.setLocationTrackingMode(NLocationTrackingMode.follow);

                final onMarkerInfoWindow =
                NInfoWindow.onMarker(id: marker.info.id, text: '친구의 위치',);
                marker.openInfoWindow(onMarkerInfoWindow);
              },
            ),

          ),
        ],
      ),
    );
  }
}
