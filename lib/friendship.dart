import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class FriendshipPage extends StatefulWidget {
 
  const FriendshipPage({Key? key}) : super(key: key);

  @override
  State<FriendshipPage> createState() => _FriendshipPageState();
}

class _FriendshipPageState extends State<FriendshipPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  List<Map<String, String>> friends = [];
  List<String> collectionNames = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }
  Future<void> _deleteFriend(String friendUid) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> storedFriends = prefs.getStringList('friends') ?? [];
  storedFriends.removeWhere((friend) => friend.split('|')[1] == friendUid);
  await prefs.setStringList('friends', storedFriends);

  setState(() {
    friends.removeWhere((friend) => friend['uid'] == friendUid);
  });
}


 Future<void> friendroutineName(String friendUid) async {
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

      setState(() {
        collectionNames = names;
      });

      _showRoutineNamesDialog(names, friendUid);
    }
  } catch (e) {
    print('Error fetching collection names: $e');
  }
}

Future<void> friendRoutinedetail(String friendUid, String title) async {
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

        _showRoutineDetailsDialog(names, friendUid, title);
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

  Future<void> _loadFriends() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? storedFriends = prefs.getStringList('friends');
    if (storedFriends != null) {
      setState(() {
        friends = storedFriends.map((friend) {
          var parts = friend.split('|');
          return {'name': parts[0], 'uid': parts[1]};
        }).toList();
      });
    }
  }

  Future<void> _showAddFriendDialog() async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.blueGrey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
        ),
        title: Text(
          '친구 추가',
          style: TextStyle(color: Colors.white, fontFamily: 'Oswald', fontSize: 24),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(
                '이름을 입력하세요:',
                style: TextStyle(color: Colors.white, fontFamily: 'Oswald'),
              ),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: "이름",
                  hintStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                '이메일을 입력하세요:',
                style: TextStyle(color: Colors.white, fontFamily: 'Oswald'),
              ),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "이메일",
                  hintStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                '비밀번호를 입력하세요:',
                style: TextStyle(color: Colors.white, fontFamily: 'Oswald'),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: "비밀번호",
                  hintStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                obscureText: true,
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('취소', style: TextStyle(color: Colors.white, fontFamily: 'Oswald')),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('확인', style: TextStyle(color: Colors.white, fontFamily: 'Oswald')),
            onPressed: () {
              _addFriendByEmail(
                _nameController.text,
                _emailController.text,
                _passwordController.text,
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

  Future<void> _addFriendByEmail(String name, String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String friendUid = userCredential.user?.uid ?? '';

      if (friendUid.isNotEmpty) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        List<String> storedFriends = prefs.getStringList('friends') ?? [];
        storedFriends.add('$name|$friendUid');
        await prefs.setStringList('friends', storedFriends);

        setState(() {
          friends.add({'name': name, 'uid': friendUid});
        });

        print('Friend Name: $name, Friend UID: $friendUid');
    
      } else {
        print('사용자를 찾을 수 없습니다.');
      }
    } catch (e) {
      print('오류 발생: $e');
    }
  }

  void _showRoutineNamesDialog(List<String> routineNames, String friendUid) {
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
                    friendRoutinedetail(friendUid, name);
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
 void _showRoutineDetailsDialog(List<String> routineDetails, String friendUid, String routineName) {
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
        ],
      );
    },
  );
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





 void _showFriendOptions(String friendUid) {
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
              friendroutineName(friendUid);
            },
          ),
           ListTile(
            leading: Icon(Icons.delete, color: Colors.white),
            title: Text('친구 삭제', style: TextStyle(color: Colors.white, fontFamily: 'Oswald')),
            onTap: () {
              Navigator.pop(context);
              _deleteFriend(friendUid);
        
            },
          ),
          
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friends', style: TextStyle(fontFamily: 'Pacifico', fontSize: 24.0,color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade700,
        leading: 
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        
        actions: [
          IconButton(
            icon: Icon(Icons.person_add, color: Colors.white),
            onPressed: _showAddFriendDialog,
          ),
        ],
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '친구 목록',
                style: TextStyle(fontSize: 24.0, color: Colors.white, fontFamily: 'Oswald', fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      color: Colors.blueGrey.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16.0),
                        title: Text(
                          friends[index]['name']!,
                          style: TextStyle(fontSize: 20.0, color: Colors.white, fontFamily: 'Oswald'),
                        ),
                       trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.more_vert, color: Colors.white),
                            onPressed: () {
                              String friendUid = friends[index]['uid']!;
                              _showFriendOptions(friendUid);
                            },
                          ),
                         
                        ],
                      ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
