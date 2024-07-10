import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FriendshipPage extends StatefulWidget {
  final VoidCallback onFriendAdded;

  const FriendshipPage({Key? key, required this.onFriendAdded}) : super(key: key);

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

  Future<void> friendroutineName(String friendUid) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendUid)
          .collection("Routine")
          .doc('Routinename')
          .collection('Names')
          .orderBy('order')
          .get();

      List<String> names = querySnapshot.docs.map((doc) => doc['name'] as String).toList();

      setState(() {
        collectionNames = names;
      });

      _showRoutineNamesDialog(names, friendUid);
    } catch (e) {
      print('Error fetching collection names: $e');
    }
  }

  Future<void> friendRoutinedetail(String friendUid, String title) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendUid)
          .collection('Routine')
          .doc('Myroutine')
          .collection(title)
          .get();

      List<String> names = querySnapshot.docs.map((doc) => doc.id).toList();

      setState(() {
        collectionNames = names;
      });

      _showRoutineDetailsDialog(names, friendUid, title);
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
          .collection(routineName)
          .doc(detail)
          .get();

      if (documentSnapshot.exists) {
        var data = documentSnapshot.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> exercisesData = [];
        if (data.containsKey('exercises')) {
          exercisesData = List<Map<String, dynamic>>.from(data['exercises'].map((exercise) => {
                'reps': exercise['reps'],
                'weight': exercise['weight'],
              }).toList());
        }
        setState(() {
          _showExerciseDetailsDialog(exercisesData);
        });
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
          title: Text('친구 추가'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('이름을 입력하세요:'),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(hintText: "이름"),
                ),
                SizedBox(height: 20),
                Text('이메일을 입력하세요:'),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(hintText: "이메일"),
                ),
                SizedBox(height: 20),
                Text('비밀번호를 입력하세요:'),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(hintText: "비밀번호"),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('확인'),
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
        widget.onFriendAdded();
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
            leading: Icon(Icons.restaurant, color: Colors.white),
            title: Text('친구 식단', style: TextStyle(color: Colors.white, fontFamily: 'Oswald')),
            onTap: () {
              Navigator.pop(context);
              // Perform action for 친구 식단
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
                        trailing: IconButton(
                          icon: Icon(Icons.more_vert, color: Colors.white),
                          onPressed: () {
                            String friendUid = friends[index]['uid']!;
                            _showFriendOptions(friendUid);
                          },
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
