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
import 'setting.dart';
import 'airoutine.dart';

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
  String weight = '0';
  String muscleMass = '0';
  String bodyFat = '0';
  List<String> filteredCollectionNames = [];
  List<String> modifiedCollectionNames = [];

  @override
  void initState() {
    super.initState();
    uid = Provider.of<UserProvider>(context, listen: false).uid;
    loadMe();
    loadStarRow();
  }

  void loadStarRow() async {
    try {
      DocumentReference bookmarkDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection("Routine")
          .doc('Bookmark');

      DocumentSnapshot bookmarkDocSnapshot = await bookmarkDocRef.get();

      if (bookmarkDocSnapshot.exists) {
        List<dynamic> names = bookmarkDocSnapshot.get('names');
        setState(() {
          filteredCollectionNames = List<String>.from(names);
          modifiedCollectionNames = List<String>.from(names); // 초기화 시 현재 순서 저장
        });
      }
    } catch (e) {
      print('Error fetching names from Firestore: $e');
    }
  }

  Future<void> updateFirestoreOrder(List<String> updatedCollectionNames) async {
    try {
      DocumentReference bookmarkDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection("Routine")
          .doc('Bookmark');

      DocumentSnapshot bookmarkDocSnapshot = await bookmarkDocRef.get();

      if (bookmarkDocSnapshot.exists) {
        await bookmarkDocRef.update({'names': updatedCollectionNames});
      } else {
        await bookmarkDocRef.set({'names': updatedCollectionNames});
      }
      loadStarRow();
    } catch (e) {
      print('Error updating Firestore order: $e');
    }
  }

  Future<void> loadMe() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      weight = prefs.getString('weight') ?? '0';
      muscleMass = prefs.getString('muscleMass') ?? '0';
      bodyFat = prefs.getString('bodyFat') ?? '0';
    });
  }

  Future<void> saveMe(String weight, String muscleMass, String bodyFat) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weight', weight);
    await prefs.setString('muscleMass', muscleMass);
    await prefs.setString('bodyFat', bodyFat);
    loadMe();

    // Firestore에 데이터 저장
    var db = FirebaseFirestore.instance;
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await db
        .collection('users')
        .doc(uid)
        .collection('Calender')
        .doc('body')
        .collection('weight')
        .doc(todayDate) // 오늘 날짜를 문서 ID로 사용
        .set({
      'date': todayDate,
      'weight': weight,
      'muscleMass': muscleMass,
      'bodyFat': bodyFat,
    });
  }

  void showMeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController weightController =
            TextEditingController(text: weight);
        TextEditingController muscleMassController =
            TextEditingController(text: muscleMass);
        TextEditingController bodyFatController =
            TextEditingController(text: bodyFat);
        return AlertDialog(
          backgroundColor: Colors.blueGrey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20.0)),
          ),
          title: Text(
            'Edit Data',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Oswald',
              fontSize: 24,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: weightController,
                  decoration: InputDecoration(
                    labelText: '몸무게',
                    labelStyle: TextStyle(color: Colors.white),
                    hintText: '몸무게를 입력하세요',
                    hintStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.cyan),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                  cursorColor: Colors.cyan,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: muscleMassController,
                  decoration: InputDecoration(
                    labelText: '골격근량',
                    labelStyle: TextStyle(color: Colors.white),
                    hintText: '골격근량을 입력하세요',
                    hintStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.cyan),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                  cursorColor: Colors.cyan,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: bodyFatController,
                  decoration: InputDecoration(
                    labelText: '체지방률',
                    labelStyle: TextStyle(color: Colors.white),
                    hintText: '체지방률을 입력하세요',
                    hintStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.cyan),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                  cursorColor: Colors.cyan,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                'Save',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                saveMe(weightController.text, muscleMassController.text,
                    bodyFatController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
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
       
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.settings,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingPage()),
                    );
                  },
                ),
               
              ],
            ),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(3.0),
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
              flex: 3,
              child: Padding(
                // 추가된 Padding 위젯
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                // 상단 영역
                child: Container(
                  child: Row(children: [
                    Image.asset(
                      'assets/dumbbell.png',
                      width: 140,
                    ),
                    SizedBox(width: 20), // 이미지와 텍스트 사이의 간격
                    Expanded(
                      // 추가된 부분: 컨테이너를 가로로 확장
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16.0), // 가로 여백을 조정
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
                                  decoration: BoxDecoration(
                                    color: Color.fromARGB(255, 60, 72, 77),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Today date: ${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontFamily: 'Oswald',
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.edit,
                                                color: Colors.white),
                                            onPressed: () {
                                              showMeDialog();
                                            },
                                          ),
                                        ],
                                      ),
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: '몸무게(Kg): ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white),
                                            ),
                                            TextSpan(
                                              text: '$weight',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      ),
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: '골격근량(Kg): ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white),
                                            ),
                                            TextSpan(
                                              text: '$muscleMass',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      ),
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: '체지방률(%): ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white),
                                            ),
                                            TextSpan(
                                              text: '$bodyFat',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ]), // 상단 영역 배경 색상 설정
                ),
              ),
            ),
            Flexible(
              flex: 7,
              child: Stack(
                children: [
                  Container(
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
                    child: filteredCollectionNames.isEmpty
                        ? Center(
                            child: Text(
                              '루틴 즐겨찾기',
                              style: TextStyle(
                                fontSize: 18.0,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Oswald',
                              ),
                            ),
                          )
                        : ReorderableListView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            onReorder: (int oldIndex, int newIndex) async {
                              setState(() {
                                if (oldIndex < newIndex) {
                                  newIndex -= 1;
                                }
                                final String item =
                                    modifiedCollectionNames.removeAt(oldIndex);
                                modifiedCollectionNames.insert(newIndex, item);
                              });
                              await updateFirestoreOrder(
                                  modifiedCollectionNames);
                            },
                            proxyDecorator: (Widget child, int index,
                                Animation<double> animation) {
                              return Material(
                                color: Colors
                                    .transparent, // Material 위젯의 color 속성을 직접 조정
                                child: child,
                                elevation: 0.0,
                              );
                            },
                            children: <Widget>[
                              for (int index = 0;
                                  index < filteredCollectionNames.length;
                                  index++)
                                Padding(
                                  key: Key('$index'),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey.shade800,
                                      borderRadius: BorderRadius.circular(15.0),
                                      border: Border.all(
                                          color: Colors.blueGrey.shade700,
                                          width: 2),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 5.0, horizontal: 20.0),
                                      title: Text(
                                        filteredCollectionNames[index],
                                        style: const TextStyle(
                                          fontSize: 18.0,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Oswald',
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ReorderableDragStartListener(
                                            index: index,
                                            child: const Icon(
                                              Icons.drag_handle,
                                              size: 30.0,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                StartRoutinePage(
                                              clickroutinename:
                                                  filteredCollectionNames[
                                                      index],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                            ],
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
                          Icons.restaurant,
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
                  ).then((value) {
                    if (value == true) {
                      loadStarRow();
                    }
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fitness_center, color: Colors.white),
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
