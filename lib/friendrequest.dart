import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequestsPage extends StatelessWidget {
  final String userId; // 현재 사용자 ID
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FriendRequestsPage({super.key, required this.userId});

  // 친구 요청 수락
  Future<void> acceptFriendRequest(Map<String, String> friend) async {
    try {
      final friendUid = friend['uid']!;
      final friendName = friend['name']!;

      // Firestore에서 현재 사용자의 이름 가져오기
      final currentUserDoc =
      await _firestore.collection('users').doc(userId).get();
      final currentUserName = currentUserDoc['name'];

      // 현재 사용자 문서 업데이트 (친구 목록 추가 및 요청 제거)
      await _firestore.collection('users').doc(userId).update({
        'friends': FieldValue.arrayUnion([
          {'uid': friendUid, 'name': friendName} // Map으로 친구 추가
        ]),
        'friendRequests': FieldValue.arrayRemove([friend]), // 요청 목록에서 제거
      });

      // 상대방 문서 업데이트 (현재 사용자를 친구 목록에 추가)
      await _firestore.collection('users').doc(friendUid).update({
        'friends': FieldValue.arrayUnion([
          {'uid': userId, 'name': currentUserName} // Map으로 현재 사용자 추가
        ]),
      });

      print('친구 요청 수락 완료: $friendName');
    } catch (e) {
      print('오류 발생: $e');
    }
  }

  // 친구 요청 거절
  Future<void> rejectFriendRequest(Map<String, String> friend) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'friendRequests': FieldValue.arrayRemove([friend]), // 요청 목록에서 제거
      });
      print('친구 요청 거절 완료');
    } catch (e) {
      print('오류 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '친구 요청 목록',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.blueGrey.shade700,
        elevation: 5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade900,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: Colors.blueGrey.shade700,
            width: 2,
          ),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('users').doc(userId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              );
            }

            // Firestore에서 요청 목록 가져오기
            List<Map<String, String>> friendRequests =
            (snapshot.data!['friendRequests'] ?? [])
                .map<Map<String, String>>((dynamic item) {
              return Map<String, String>.from(item);
            }).toList();

            return ListView.builder(
              itemCount: friendRequests.length,
              itemBuilder: (context, index) {
                final friend = friendRequests[index];
                final friendName = friend['name']!; // 이름만 표시

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        friendName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          shadows: [
                            Shadow(
                              blurRadius: 3,
                              color: Colors.black38,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              backgroundColor: Colors.greenAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 5,
                            ),
                            onPressed: () async {
                              await acceptFriendRequest(friend); // 요청 수락
                            },
                            child: const Text(
                              '수락',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 5,
                            ),
                            onPressed: () async {
                              await rejectFriendRequest(friend); // 요청 거절
                            },
                            child: const Text(
                              '거절',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
