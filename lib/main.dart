import 'package:health/food.dart';
import 'saveroutine.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'routine.dart';
import 'create_routine.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'calender.dart';
import 'package:intl/intl.dart';
import 'bookmark.dart';
import 'start_routine.dart';
import 'chart.dart';
import 'foodsave.dart';
import 'foodroutinestart.dart';
import 'loginpage.dart';
import 'user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_auth_service.dart';
import 'friendship.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uid = prefs.getString('uid');

    if (uid != null) {
      Provider.of<UserProvider>(context, listen: false).setUid(uid);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Homepage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  DateTime selectedDate = DateTime.now();
  List<String> collectionNames = [];
  String? uid;
  List<Map<String, String>> friends = [];

  @override
  void initState() {
    super.initState();
    uid = Provider.of<UserProvider>(context, listen: false).uid;
    _fetchSevenDayAgoData();
    _loadFriends();
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

  Future<void> _fetchSevenDayAgoData() async {
    List<String> names = [];
    for (int i = 7; i >= 1; i--) {
      List<String> dayNames = await _fetchDayAgoData(i);
      if (dayNames.isNotEmpty) {
        for (var name in dayNames) {
          names.add('$name - $i일 전');
        }
      }
    }
    setState(() {
      collectionNames = names;
    });
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('uid');
    await AuthService().logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Future<List<String>> _fetchDayAgoData(int daysAgo) async {
    var db = FirebaseFirestore.instance;
    String targetDate = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(Duration(days: daysAgo)));

    try {
      QuerySnapshot snapshot = await db
          .collection('users')
          .doc(uid)
          .collection('Calender')
          .doc('health')
          .collection('routines')
          .where('날짜', isEqualTo: targetDate)
          .get();

      List<String> routineNames =
          snapshot.docs.map((doc) => doc['오늘 한 루틴이름'] as String).toList();

      return routineNames;
    } catch (e) {
      print('오류 발생: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRoutineData() async {
    var db = FirebaseFirestore.instance;
    String todayDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    try {
      QuerySnapshot snapshot = await db
          .collection('users')
          .doc(uid)
          .collection('Calender')
          .doc('health')
          .collection('routines')
          .get();

      List<Map<String, dynamic>> matchedDocuments = [];

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['날짜'] == todayDate) {
          matchedDocuments.add(data);
        }
      }

      return matchedDocuments;
    } catch (e) {
      print('Error fetching documents: $e');
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Life is Gorip',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Pacifico',
            fontSize: 24.0, // 글자 색상을 흰색으로 설정
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade700,
        leading: IconButton(
          icon: Icon(
            Icons.query_stats,
            color: Colors.white,
          ), // Icons.list 대신 Icons.menu를 사용
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RoutineChart()),
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.star,
                    color: Colors.yellow,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BookMarkPage()),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.person,
                    color: Colors.blue,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              FriendshipPage(onFriendAdded: _loadFriends)),
                    );
                  },
                ),
              ],
            ),
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
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
          border: Border.all(
            color: Colors.blueGrey.shade700,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Flexible(
              flex: 3, // 상단 영역
              child: Container(
                child: Row(children: [
                  Image.asset(
                    'assets/dumbbell.png',
                    width: 140,
                  ),
                  Expanded(
                    // 추가된 부분: 컨테이너를 가로로 확장
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0), // 가로 여백을 조정
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 오늘 날짜를 항상 표시하는 Container
                          Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: Align(
                              alignment: Alignment(-0.2, 0.0),
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                color: Colors.grey[800],
                                child: Text(
                                  'Today date: ${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontFamily: 'Oswald',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),

                          Expanded(
                            child: ListView.builder(
                              itemCount: friends.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // 버튼 클릭 시 수행할 작업을 여기에 작성
                                    },
                                    child: Text(friends[index]['name']!, style: TextStyle(color: Color.fromARGB(255, 188, 181, 181)),),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 10.0), // 패딩 사이즈 줄임
                                      textStyle:
                                          TextStyle(fontSize: 18), // 텍스트 사이즈 줄임
                                      backgroundColor:
                                          Color.fromARGB(255, 81, 103, 113), // 배경색상 지정
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            8.0), // 버튼 모서리 둥글게
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
                  ),
                ]), // 상단 영역 배경 색상 설정
              ),
            ),
            Flexible(
              flex: 7,
              child: Stack(
                children: [
                  Container(
                    child: ListView.builder(
                      itemCount: collectionNames.length,
                      itemBuilder: (context, index) {
                        String collectionName = collectionNames[index];
                        List<String> parts = collectionName.split(' - ');
                        String routineName = parts[0];
                        String dayInfo = parts[1];

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          child: Card(
                            color: Colors.blueGrey.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16.0),
                              title: Text(
                                routineName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20.0,
                                  color: Colors.white,
                                  fontFamily: 'Oswald',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                dayInfo,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.white70,
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StartRoutinePage(
                                      clickroutinename: routineName,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      margin: EdgeInsets.only(right: 40.0, bottom: 20.0),
                      width: 140,
                      height: 60,
                      child: FloatingActionButton.extended(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const RoutinePage()),
                          );
                        },
                        icon: Icon(
                          Icons.add,
                          color: Colors.blueGrey.shade700,
                        ),
                        label: Text(
                          "루틴추가",
                          style: TextStyle(
                            color: Colors.blueGrey.shade700,
                            fontFamily: 'Oswald',
                          ),
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      margin: EdgeInsets.only(left: 40.0, bottom: 20.0),
                      width: 140,
                      height: 60,
                      child: FloatingActionButton.extended(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const FoodRoutineCreatePage()),
                          );
                        },
                        icon: Icon(
                          Icons.food_bank,
                          color: Colors.white,
                        ),
                        label: Text(
                          "식단추가",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Oswald',
                          ),
                        ),
                        backgroundColor: Colors.cyan.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
          color: Colors.blueGrey.shade800,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SaveRoutinePage()),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.work, color: Colors.white),
                    SizedBox(width: 4), // 아이콘과 텍스트 사이의 간격
                    Text(
                      '루틴',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CalenderPage()),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_available, color: Colors.white),
                    SizedBox(width: 4), // 아이콘과 텍스트 사이의 간격
                    Text(
                      '일지',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FoodroutinestartPage()),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_run, color: Colors.white),
                    SizedBox(width: 4), // 아이콘과 텍스트 사이의 간격
                    Text(
                      '진행중',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FoodSavePage()),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lunch_dining, color: Colors.white),
                    SizedBox(width: 4), // 아이콘과 텍스트 사이의 간격
                    Text(
                      '식단',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ],
          )),
    );
  }
}
