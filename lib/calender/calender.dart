import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'user_provider.dart';
import 'package:provider/provider.dart';

class CalenderPage extends StatefulWidget {
  const CalenderPage({super.key});

  @override
  _CalenderPageState createState() => _CalenderPageState();
}

class _CalenderPageState extends State<CalenderPage> {
  String? uid;

  void initState() {
    super.initState();
    uid = Provider.of<UserProvider>(context, listen: false).uid;
  }

  DateTime selectedDate = DateTime.now();

  Future<void> _deleteRoutine(String documentId) async {
    var db = FirebaseFirestore.instance;
    try {
      await db
          .collection('users')
          .doc(uid)
          .collection('Calender')
          .doc('health')
          .collection('routines')
          .doc(documentId)
          .delete();
    } catch (e) {
      print('Error deleting document: $e');
    }
    setState(() {
      // 상태 변경 후 UI를 다시 빌드하도록 설정
    });
    _fetchRoutineData();
  }

  // Future<void> _deleteFood(String documentId) async {
  //   var db = FirebaseFirestore.instance;
  //   try {
  //     await db
  //         .collection('users')
  //         .doc(uid)
  //         .collection('Calender')
  //         .doc('food')
  //         .collection('todayfood')
  //         .doc(documentId)
  //         .delete();
  //   } catch (e) {
  //     print('Error deleting document: $e');
  //   }
  //   setState(() {
  //     // 상태 변경 후 UI를 다시 빌드하도록 설정
  //   });
  //   _fetchFoodData();
  // }
  //
  Future<Map<String, Map<String, int>>> _fetchRoutineChartData(
      String routineName) async {
    var db = FirebaseFirestore.instance;
    Map<String, Map<String, int>> routineData = {};

    try {
      QuerySnapshot snapshot = await db
          .collection('users')
          .doc(uid)
          .collection('Calender')
          .doc('health')
          .collection('routines')
          .get();

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['오늘 한 루틴이름'] == routineName) {
          String formattedDate = data['날짜'];
          int volume = data['오늘 총 볼륨'] ?? 0;

          if (routineData.containsKey(routineName)) {
            routineData[routineName]![formattedDate] = volume;
          } else {
            routineData[routineName] = {formattedDate: volume};
          }
        }
      }

      return routineData;
    } catch (e) {
      print('Error fetching documents: $e');
      return {};
    }
  }

  // Future<List<Map<String, dynamic>>> _fetchFoodData() async {
  //   var db = FirebaseFirestore.instance;
  //   String todayDate = DateFormat('yyyy-MM-dd').format(selectedDate);
  //
  //   try {
  //     QuerySnapshot snapshot = await db
  //         .collection('users')
  //         .doc(uid)
  //         .collection('Calender')
  //         .doc('food')
  //         .collection('todayfood')
  //         .where('date', isEqualTo: todayDate)
  //         .get();
  //
  //     return snapshot.docs.map((doc) {
  //       var data = doc.data() as Map<String, dynamic>;
  //       data['documentId'] = doc.id; // 문서 ID를 포함시킴
  //       return data;
  //     }).toList();
  //   } catch (e) {
  //     print('Error fetching documents: $e');
  //     return [];
  //   }
  // }

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
        data['documentId'] = doc.id; // 문서 ID를 포함시킴
        if (data['날짜'] == todayDate) {
          // 운동 종목과 횟수 데이터를 포함시키기
          if (data.containsKey('운동 목록')) {
            data['운동 목록'] = List<Map<String, dynamic>>.from(data['운동 목록']);
          } else {
            data['운동 목록'] = [];
          }
          matchedDocuments.add(data);
        }
      }

      return matchedDocuments;


    } catch (e) {
      print('Error fetching documents: $e');
    }
    return [];
  }
  Future<Map<String, List<Map<String, int>>>> fetchRoutineDetails(
      String routineName) async {
    var db = FirebaseFirestore.instance;

    try {
      DocumentSnapshot snapshot = await db
          .collection('users')
          .doc(uid)
          .collection('Routine')
          .doc('Myroutine')
          .get();

      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        print('Firestore data: ${snapshot.data()}');

        // 루틴 이름 (예: "등")에 해당하는 데이터 찾기
        if (data.containsKey(routineName)) {
          List<dynamic> routineList = data[routineName];

          Map<String, List<Map<String, int>>> groupedExercises = {};

          for (var routine in routineList) {
            // 운동 이름 (예: "렛풀다운", "티바") 추출
            String exerciseName = routine.keys.first;
            var exerciseData = routine[exerciseName] as Map<String, dynamic>;
            List<dynamic> exercises = exerciseData['exercises'];

            // 운동 데이터 (reps, weight) 처리
            for (var exercise in exercises) {
              int reps = exercise['reps'] is int
                  ? exercise['reps']
                  : int.tryParse(exercise['reps'].toString()) ?? 0;
              int weight = exercise['weight'] is int
                  ? exercise['weight']
                  : int.tryParse(exercise['weight'].toString()) ?? 0;

              if (!groupedExercises.containsKey(exerciseName)) {
                groupedExercises[exerciseName] = [];
              }
              groupedExercises[exerciseName]!
                  .add({'횟수': reps, '무게': weight});
            }
          }

          return groupedExercises;
        }
      }

      // 루틴 이름이 없거나 데이터가 비어있는 경우
      return {};
    } catch (e) {
      print('Error fetching routine details: $e');
      return {};
    }
  }



  // List<PieChartSectionData> showingSections(
  //     double carbs, double protein, double fat) {
  //   final total = carbs + protein + fat;
  //   if (total == 0) return [];
  //
  //   return [
  //     PieChartSectionData(
  //       color: Colors.blue,
  //       value: (carbs / total) * 100,
  //       title: '${(carbs / total * 100).toStringAsFixed(1)}%',
  //       radius: 50,
  //       titleStyle: const TextStyle(
  //         fontSize: 16,
  //         fontWeight: FontWeight.bold,
  //         color: Colors.white,
  //       ),
  //     ),
  //     PieChartSectionData(
  //       color: Colors.red,
  //       value: (protein / total) * 100,
  //       title: '${(protein / total * 100).toStringAsFixed(1)}%',
  //       radius: 50,
  //       titleStyle: const TextStyle(
  //         fontSize: 16,
  //         fontWeight: FontWeight.bold,
  //         color: Colors.white,
  //       ),
  //     ),
  //     PieChartSectionData(
  //       color: Colors.green,
  //       value: (fat / total) * 100,
  //       title: '${(fat / total * 100).toStringAsFixed(1)}%',
  //       radius: 50,
  //       titleStyle: const TextStyle(
  //         fontSize: 16,
  //         fontWeight: FontWeight.bold,
  //         color: Colors.white,
  //       ),
  //     ),
  //   ];
  // }

  void _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
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
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String todayDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      appBar: AppBar(
        title: Text(
          "운동일지",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade700,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              onPressed: () => _selectDate(context),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(
                  Colors.blueGrey.shade700,
                ),
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
              child: Text('날짜 선택', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Center(
              child: Text(
                todayDate,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
            ),
          ),
          // Expanded(
          //   child: FutureBuilder<List<Map<String, dynamic>>>(
          //     future: _fetchFoodData(),
          //     builder: (context, snapshot) {
          //       if (snapshot.connectionState == ConnectionState.waiting) {
          //         return Center(child: CircularProgressIndicator());
          //       }
          //       if (snapshot.hasError) {
          //         return Center(child: Text('오류 발생: ${snapshot.error}'));
          //       }
          //       if (!snapshot.hasData || snapshot.data!.isEmpty) {
          //         return Center(
          //             child: Text(
          //           '데이터가 없습니다.',
          //           style: TextStyle(color: Colors.white),
          //         ));
          //       }
          //
          //       var data = snapshot.data!;
          //       var totalCarbs = data.fold<double>(
          //           0.0, (sum, item) => sum + (item['totalCarbs'] ?? 0.0));
          //       var totalProtein = data.fold<double>(
          //           0.0, (sum, item) => sum + (item['totalProtein'] ?? 0.0));
          //       var totalFat = data.fold<double>(
          //           0.0, (sum, item) => sum + (item['totalFat'] ?? 0.0));
          //       var totalCalories = data.fold<double>(
          //           0.0, (sum, item) => sum + (item['totalCalories'] ?? 0.0));
          //
          //       return Column(
          //         children: [
          //           Expanded(
          //             child: ListView.builder(
          //               itemCount: data.length,
          //               itemBuilder: (context, index) {
          //                 var item = data[index];
          //                 return Padding(
          //                   padding: const EdgeInsets.all(16.0),
          //                   child: Column(
          //                     crossAxisAlignment: CrossAxisAlignment.start,
          //                     children: [
          //                       Row(
          //                         mainAxisAlignment:
          //                             MainAxisAlignment.spaceBetween,
          //                         children: [
          //                           Text(
          //                             '오늘 먹은 칼로리: ${item['totalCalories']}',
          //                             style: TextStyle(
          //                               color: Colors.white,
          //                               fontWeight: FontWeight.bold, // 글자를 두껍게
          //                               fontSize: 15, // 글자 크기를 20으로 설정
          //                             ),
          //                           ),
          //                           IconButton(
          //                             icon: Icon(Icons.delete,
          //                                 color: Colors.white),
          //                             onPressed: () {
          //                               _deleteFood(item['documentId']);
          //                             },
          //                           ),
          //                         ],
          //                       ),
          //                       Text(
          //                         '탄수화물: ${item['totalCarbs']}',
          //                         style: TextStyle(color: Colors.white),
          //                       ),
          //                       Text(
          //                         '단백질: ${item['totalProtein']}',
          //                         style: TextStyle(color: Colors.white),
          //                       ),
          //                       Text(
          //                         '지방: ${item['totalFat']}',
          //                         style: TextStyle(color: Colors.white),
          //                       ),
          //                       SizedBox(
          //                         height: 200,
          //                         child: PieChart(
          //                           PieChartData(
          //                             sections: showingSections(
          //                                 totalCarbs, totalProtein, totalFat),
          //                             sectionsSpace: 0,
          //                             centerSpaceRadius: 40,
          //                             borderData: FlBorderData(show: false),
          //                           ),
          //                         ),
          //                       ),
          //                     ],
          //                   ),
          //                 );
          //               },
          //             ),
          //           ),
          //         ],
          //       );
          //     },
          //   ),
          // ),
          Divider(
            color: Colors.grey,
            thickness: 1,
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchRoutineData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('오류 발생: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                      child: Text(
                    '데이터가 없습니다.',
                    style: TextStyle(color: Colors.white),
                  ));
                }
                var data = snapshot.data!;
                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    var routine = data[index];
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '오늘 한 루틴 이름: ${routine['오늘 한 루틴이름']}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold, // 글자를 두껍게
                                  fontSize: 15, // 글자 크기를 20으로 설정
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.white),
                                onPressed: () {
                                  _deleteRoutine(routine['documentId']);
                                },
                              ),
                            ],
                          ),
                          Text(
                            '오늘 총 운동 세트수: ${routine['오늘 총 세트수']}',
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            '오늘 총 운동 볼륨: ${routine['오늘 총 볼륨']}',
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            '오늘 총 운동 시간: ${routine['오늘 총 시간']}',
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 16),



                          FutureBuilder<Map<String, Map<String, int>>>(
                            future:
                                _fetchRoutineChartData(routine['오늘 한 루틴이름']),
                            builder: (context, chartSnapshot) {
                              if (chartSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                    child: CircularProgressIndicator());
                              }
                              if (chartSnapshot.hasError) {
                                return Center(
                                    child:
                                        Text('오류 발생: ${chartSnapshot.error}'));
                              }
                              if (!chartSnapshot.hasData ||
                                  chartSnapshot.data!.isEmpty) {
                                return Center(
                                    child: Text(
                                  '차트 데이터가 없습니다.',
                                  style: TextStyle(color: Colors.white),
                                ));
                              }

                              Map<String, Map<String, int>> routineData =
                                  chartSnapshot.data!;
                              if (!routineData
                                  .containsKey(routine['오늘 한 루틴이름'])) {
                                return Center(
                                    child: Text(
                                  '차트 데이터가 없습니다.',
                                  style: TextStyle(color: Colors.white),
                                ));
                              }

                              Map<String, int> data =
                                  routineData[routine['오늘 한 루틴이름']]!;

                              // 날짜별로 정렬
                              var sortedEntries = data.entries.toList()
                                ..sort((a, b) =>
                                    DateTime.parse(a.key).compareTo(DateTime.parse(b.key)));

                              // 정렬된 데이터를 기반으로 X축과 Y축 값을 추출
                              List<String> xLabels = sortedEntries
                                  .map((entry) =>
                                  DateFormat('MM/dd').format(DateTime.parse(entry.key)))
                                  .toList();
                              List<double> yValues = sortedEntries
                                  .map((entry) => entry.value.toDouble())
                                  .toList();

                              // Y축 최소값과 최대값 계산
                              double minY = yValues.reduce((a, b) => a < b ? a : b);
                              double maxY = yValues.reduce((a, b) => a > b ? a : b);

                              // FlSpot 데이터 생성
                              List<FlSpot> spots = [];
                              for (int i = 0; i < data.length; i++) {
                                spots.add(FlSpot(i.toDouble(), yValues[i]));
                              }

                              return SizedBox(
                                height: 250, // 높이를 살짝 늘림
                                child: LineChart(
                                  LineChartData(
                                    backgroundColor: Colors.transparent,
                                    gridData: FlGridData(
                                      show: true,
                                      getDrawingHorizontalLine: (value) => FlLine(
                                        color: Colors.grey.shade800, // 수평선 색상
                                        strokeWidth: 0.5,
                                      ),
                                      getDrawingVerticalLine: (value) => FlLine(
                                        color: Colors.grey.shade800, // 수직선 색상
                                        strokeWidth: 0.5,
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                          getTitlesWidget: (value, meta) {
                                            if (value.toInt() < xLabels.length) {
                                              return Text(
                                                xLabels[value.toInt()],
                                                style: TextStyle(color: Colors.white, fontSize: 12),
                                              );
                                            }
                                            return Text('');
                                          },
                                          interval: 1,
                                          reservedSize: 28, // 여백 추가
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false ,
                                          getTitlesWidget: (value, meta) {
                                            return Text(
                                              '${value.toInt()}',
                                              style: TextStyle(color: Colors.white70, fontSize: 12),
                                            );
                                          },
                                          interval: 1,
                                          reservedSize: 32,
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border(
                                        bottom: BorderSide(color: Colors.white54, width: 1),
                                        left: BorderSide(color: Colors.white54, width: 1),
                                        right: BorderSide.none,
                                        top: BorderSide.none,
                                      ),
                                    ),
                                    minX: 0,
                                    maxX: (yValues.length - 1).toDouble(),
                                    minY: minY,
                                    maxY: maxY,
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: spots,
                                        isCurved: true, // 부드러운 곡선
                                        barWidth: 4, // 선 굵기
                                        isStrokeCapRound: true,
                                        gradient: LinearGradient(
                                          colors: [Colors.cyan, Colors.blueAccent], // 선 그래디언트
                                        ),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.cyan.withOpacity(0.3),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                        dotData: FlDotData(
                                          show: true,
                                          getDotPainter: (spot, percent, barData, index) {
                                            return FlDotCirclePainter(
                                              radius: 4, // 점 크기
                                              color: Colors.cyan,

                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 16),

                          FutureBuilder<Map<String, List<Map<String, int>>>>(
                            future: fetchRoutineDetails(routine['오늘 한 루틴이름']),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Center(child: Text('오류 발생: ${snapshot.error}'));
                              }
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return Center(child: Text('데이터가 없습니다.'));
                              }

                              var groupedExercises = snapshot.data!;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: groupedExercises.entries.map((entry) {
                                  String exerciseName = entry.key;
                                  List<Map<String, int>> details = entry.value;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$exerciseName',
                                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        ...details.map((detail) {
                                          return Padding(
                                            padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                                            child: Text(
                                              ' 무게: ${detail['무게']}kg, 횟수: ${detail['횟수']}',
                                              style: TextStyle(color: Colors.white, fontSize: 14),
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          )

                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
