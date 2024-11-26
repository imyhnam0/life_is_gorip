import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'friendrequest.dart';
import 'user_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class InvitePage extends StatefulWidget {
  const InvitePage({super.key});

  @override
  _InvitePageState createState() => _InvitePageState();
}

class _InvitePageState extends State<InvitePage> {
  final TextEditingController _friendEmailController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> collectionNames = [];
  String? Myuid;

  @override
  void initState() {
    super.initState();
    Myuid = Provider.of<UserProvider>(context, listen: false).uid;
  }


  //친구 루틴 이름
  Future<void> friendroutineName(String friendUid,friendName) async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendUid)
          .collection('Routine')
          .doc('Myroutine')
          .get();

      if (documentSnapshot.exists) {
        var data = documentSnapshot.data() as Map<String, dynamic>;
        List<String> names = data.keys.toList();

          collectionNames = names;

        _showRoutineNamesDialog(names, friendUid ,friendName);
      }
    } catch (e) {
      print('Error fetching collection names: $e');
    }
  }


  Future<void> friendRoutinedetail(String friendUid, String title, String friendName) async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendUid)
          .collection('Routine')
          .doc('Myroutine')
          .get();

      if (documentSnapshot.exists) {
        var data = documentSnapshot.data() as Map<String, dynamic>;

        if (data.containsKey(title)) {
          List<dynamic> routineList = data[title];
          List<String> names = routineList.map((routine) {
            return routine.keys.first.toString();
          }).toList();

          setState(() {
            collectionNames = names;
          });

          _showRoutineDetailsDialog(names, friendUid, title, friendName);
        }
      }
    } catch (e) {
      print('Error fetching collection names: $e');
    }
  }

  void moremoreroutine(String friendUid, String routineName, String detail) async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendUid)
          .collection('Routine')
          .doc('Myroutine')
          .get();

      if (documentSnapshot.exists) {
        var data = documentSnapshot.data() as Map<String, dynamic>;

        if (data.containsKey(routineName)) {
          List<dynamic> routineList = data[routineName];
          Map<String, dynamic>? routineDetail;

          for (var routine in routineList) {
            if (routine.containsKey(detail)) {
              routineDetail = routine[detail];
              break;
            }
          }

          if (routineDetail != null && routineDetail.containsKey('exercises')) {
            List<Map<String, dynamic>> exercisesData = List<Map<String, dynamic>>.from(
              routineDetail['exercises'].map((exercise) => {
                'reps': exercise['reps'],
                'weight': exercise['weight'],
              }).toList(),
            );

            setState(() {
              _showExerciseDetailsDialog(exercisesData);
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching document data: $e');
    }
  }

  void _showRoutineNamesDialog(List<String> routineNames, String friendUid, String friendName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),

              Expanded(
                child: Text(
                  'Routine Names',
                  style: TextStyle(color: Colors.white, fontFamily: 'Oswald'),
                  textAlign: TextAlign.center, // Text를 Expanded 내에서 중앙 정렬
                ),
              ),

            ],
          ),
          backgroundColor: Colors.blueGrey.shade900,
          content: SingleChildScrollView(
            child: ListBody(
              children: routineNames.map((name) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      friendRoutinedetail(friendUid, name,friendName);
                    },
                    child: Text(name),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade700,
                      foregroundColor: Colors.white,
                      textStyle: TextStyle(fontFamily: 'Oswald'),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: Text('닫기', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  void _showRoutineDetailsDialog(List<String> routineDetails, String friendUid, String routineName,String friendName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              Expanded(
                child: Text(
                  'Routine details',
                  style: TextStyle(color: Colors.white, fontFamily: 'Oswald'),
                  textAlign: TextAlign.center, // Text를 Expanded 내에서 중앙 정렬
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blueGrey.shade900,
          content: SingleChildScrollView(
            child: ListBody(
              children: routineDetails.map((detail) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      moremoreroutine(friendUid, routineName, detail);
                    },
                    child: Text(detail),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade700,
                      foregroundColor: Colors.white,
                      textStyle: TextStyle(fontFamily: 'Oswald'),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: Text('닫기', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('가져오기', style: TextStyle(color: Colors.white)),
              onPressed: () {
                _fetchAndSaveFriendRoutine(friendUid,friendName, routineName);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  Future<void> _fetchAndSaveFriendRoutine(String friendUid, String friendName, String routineName) async {
    var db = FirebaseFirestore.instance;


    try {
      // 친구의 루틴 데이터 가져오기
      DocumentSnapshot documentSnapshot = await db
          .collection('users')
          .doc(friendUid)
          .collection('Routine')
          .doc('Myroutine')
          .get();

      if (documentSnapshot.exists) {
        var friendRoutineData = documentSnapshot.data() as Map<String, dynamic>;

        // 해당 루틴이 존재하는지 확인
        if (friendRoutineData.containsKey(routineName)) {
          var routineDetails = friendRoutineData[routineName];
          print('친구 루틴 $routineName 데이터:');
          print(routineDetails);

          // 친구 이름을 추가한 새로운 루틴 이름 생성
          String newRoutineName = "$routineName:$friendName";

          // 자신의 Firestore에 저장 (병합)
          await db.collection('users')
              .doc(Myuid)
              .collection('Routine')
              .doc('Myroutine')
              .set({
            newRoutineName: routineDetails  // 가져온 루틴 데이터를 저장
          }, SetOptions(merge: true));  // 기존 데이터에 병합

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('루틴이 성공적으로 가져와졌습니다!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('루틴을 찾을 수 없습니다.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('친구의 루틴을 찾을 수 없습니다.')),
        );
      }
    } catch (e) {
      print('Error fetching and saving friend routine: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('루틴 가져오기 중 오류가 발생했습니다.')),
      );
    }
  }


  void _showExerciseDetailsDialog(List<Map<String, dynamic>> exercisesData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              Expanded(
                child: Text(
                  'Exercise details',
                  style: TextStyle(color: Colors.white, fontFamily: 'Oswald'),
                  textAlign: TextAlign.center, // Text를 Expanded 내에서 중앙 정렬
                ),),
            ],
          ),
          backgroundColor: Colors.blueGrey.shade900,
          content: SingleChildScrollView(
            child: ListBody(
              children: exercisesData.map((exercise) {
                return ListTile(
                  title: Text('Weight: ${exercise['weight']}', style: TextStyle(color: Colors.white)),
                  subtitle: Text('Reps: ${exercise['reps']}', style: TextStyle(color: Colors.white70)),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: Text('닫기', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  void _showFriendCalendar(String friendUid) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.blueGrey.shade700,
              onPrimary: Colors.white,
              surface: Colors.grey,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.black,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      _fetchFriendRoutineData(friendUid, pickedDate);
    }
  }

  Future<void> _fetchFriendRoutineData(String friendUid, DateTime date) async {
    var db = FirebaseFirestore.instance;
    String selectedDate = DateFormat('yyyy-MM-dd').format(date);

    try {
      QuerySnapshot snapshot = await db
          .collection('users')
          .doc(friendUid)
          .collection('Calender')
          .doc('health')
          .collection('routines')
          .where('날짜', isEqualTo: selectedDate)
          .get();

      List<Map<String, dynamic>> friendRoutineData = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // You can show the data in a new dialog or navigate to a new page to display it
      _showFriendRoutineDataDialog(friendRoutineData);
    } catch (e) {
      print('Error fetching friend routine data: $e');
    }
  }

  void _showFriendRoutineDataDialog(List<Map<String, dynamic>> routineData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Friend Routine Data', style: TextStyle(color: Colors.white, fontFamily: 'Oswald')),
          backgroundColor: Colors.blueGrey.shade900,
          content: SingleChildScrollView(
            child: ListBody(
              children: routineData.map((routine) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '루틴 이름: ${routine['오늘 한 루틴이름']}',
                        style: TextStyle(color: Colors.white, fontFamily: 'Oswald'),
                      ),
                      Text(
                        '총 세트수: ${routine['오늘 총 세트수']}',
                        style: TextStyle(color: Colors.white, fontFamily: 'Oswald'),
                      ),
                      Text(
                        '총 볼륨: ${routine['오늘 총 볼륨']}',
                        style: TextStyle(color: Colors.white, fontFamily: 'Oswald'),
                      ),
                      Text(
                        '총 시간: ${routine['오늘 총 시간']}',
                        style: TextStyle(color: Colors.white, fontFamily: 'Oswald'),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: Text('닫기', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }





  void _showFriendOptions(String friendUid,friendName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.blueGrey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.schedule, color: Colors.white),
              title: Text('친구 일정', style: TextStyle(color: Colors.white, fontFamily: 'Oswald')),
              onTap: () {
                Navigator.pop(context);
                _showFriendCalendar(friendUid);
                // Perform action for 친구 일정
              },
            ),
            ListTile(
              leading: Icon(Icons.fitness_center, color: Colors.white),
              title: Text('친구 루틴', style: TextStyle(color: Colors.white, fontFamily: 'Oswald')),
              onTap: () {
                Navigator.pop(context);
                friendroutineName(friendUid,friendName);
              },
            ),


          ],
        );
      },
    );
  }


  // 친구 삭제 함수
  Future<void> removeFriend(Map<String, String> friend) async {
    try {
      final friendUid = friend['uid']!;
      final friendName = friend['name']!;

      // 현재 사용자 이름 가져오기
      final myDoc = await _firestore.collection('users').doc(Myuid).get();
      final myName = myDoc['name'] as String;

      // 현재 사용자 문서에서 친구 제거
      await _firestore.collection('users').doc(Myuid).update({
        'friends': FieldValue.arrayRemove([friend]), // 내 친구 목록에서 친구 삭제
      });

      // 상대방 문서에서 현재 사용자 삭제
      await _firestore.collection('users').doc(friendUid).update({
        'friends': FieldValue.arrayRemove([
          {'uid': Myuid, 'name': myName}, // 상대방의 친구 목록에서 내 정보 삭제
        ]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$friendName님을 친구 목록에서 삭제했습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }




  // 친구 추가 요청 함수
  Future<void> sendFriendRequest(String friendEmail) async {
    try {
      // Firestore에서 이메일로 사용자 검색
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: friendEmail)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // 친구 UID 가져오기
        final friendDoc = querySnapshot.docs.first;
        final friendUid = friendDoc['uid'];

        // Firestore에서 내 이름 가져오기
        final myDoc = await _firestore.collection('users').doc(Myuid).get();
        final myName = myDoc['name']; // 내 이름 가져오기

        // 친구 요청 및 친구 목록 확인
        final friendRequests = friendDoc['friendRequests'] != null &&
            friendDoc['friendRequests'] is List
            ? (friendDoc['friendRequests'] as List)
            .map((request) =>
        Map<String, String>.from(request as Map<String, dynamic>))
            .toList()
            : [];

        final friendList = friendDoc['friends'] != null &&
            friendDoc['friends'] is List
            ? (friendDoc['friends'] as List)
            .map((friend) =>
        Map<String, String>.from(friend as Map<String, dynamic>))
            .toList()
            : [];

        // 중복 확인: 친구 요청 목록에 존재하는지
        final alreadyRequested =
        friendRequests.any((request) => request['uid'] == Myuid);

        // 중복 확인: 친구 목록에 존재하는지
        final alreadyFriend = friendList.contains(Myuid);

        if (alreadyRequested || alreadyFriend) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미 친구 요청을 보냈거나 친구로 등록되어 있습니다.')),
          );
          return;
        }

        // 친구 요청 추가
        await _firestore.collection('users').doc(friendUid).update({
          'friendRequests': FieldValue.arrayUnion([
            {'uid': Myuid, 'name': myName} // Map<String, String> 형태로 추가
          ]),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('친구 요청을 보냈습니다!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('해당 이메일을 가진 사용자가 없습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '친구 목록',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24,color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 10,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FriendRequestsPage(userId: Myuid!),
                  ),
                );
              },
              child: const Text(
                '요청 목록',
                style: TextStyle(color: Colors.white),
              ),
            ),
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.indigoAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('users').doc(Myuid).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            // friends 필드를 가져오기
            // 친구 목록 처리
            List<Map<String, String>> friends = [];
            if (snapshot.data!['friends'] != null &&
                snapshot.data!['friends'] is List) {
              friends = (snapshot.data!['friends'] as List)
                  .map((friend) =>
              Map<String, String>.from(friend as Map<String, dynamic>))
                  .toList();
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      final friend = friends[index];
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
                              friend['name']!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black, // 텍스트 색상 조정
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
                                IconButton(
                                  icon: Icon(Icons.more_vert, color: Colors.white),
                                  onPressed: () {
                                    _showFriendOptions(friend['uid']!, friend['name']!); // friendUid와 friendName 전달
                                  },

                                ),
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
                                    await removeFriend(friend);
                                  },
                                  child: const Text(
                                    '삭제',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],

                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 10,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            backgroundColor: Colors.deepPurpleAccent.withOpacity(0.9),
                            title: const Text(
                              '친구 추가',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 5.0,
                                    color: Colors.black45,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                            content: TextField(
                              controller: _friendEmailController,
                              decoration: InputDecoration(
                                hintText: '친구의 이메일을 입력하세요',
                                hintStyle: const TextStyle(
                                  color: Colors.white70,
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.2),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Colors.white70),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Colors.white),
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: const Text('취소'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final friendEmail = _friendEmailController.text.trim();
                                  if (friendEmail.isNotEmpty) {
                                    await sendFriendRequest(friendEmail);
                                    Navigator.pop(context);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigoAccent,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 5,
                                ),
                                child: const Text(
                                  '요청 보내기',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          );

                        },
                      );
                    },
                    child: const Text(
                      '친구 추가',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
