import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class CalenderPage extends StatefulWidget {
  const CalenderPage({super.key});

  @override
  _CalenderPageState createState() => _CalenderPageState();
}

class _CalenderPageState extends State<CalenderPage> {
  String? uid;
  DateTime selectedDate = DateTime.now();
  late Future<List<String>> _routineNamesFuture;
  Map<DateTime, List<Map<String, dynamic>>> _eventMap = {};


  void initState() {
    super.initState();
    uid = Provider.of<UserProvider>(context, listen: false).uid;
    _routineNamesFuture = fetchRoutineNames();
    _loadEventDates();
  }

  Future<void> _loadEventDates() async {
    List<Map<String, dynamic>> allData = await _fetchAllRoutineData();
    Map<DateTime, List<Map<String, dynamic>>> events = {};

    for (var item in allData) {
      if (item.containsKey('날짜')) {
        DateTime parsedDate = DateTime.parse(item['날짜']);
        DateTime normalizedDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day); // ✅ 시간 제거
        events.update(normalizedDate, (existing) => [...existing, item], ifAbsent: () => [item]);
      }
    }

    setState(() {
      _eventMap = events;
    });

    print("🔴 이벤트 날짜들: ${_eventMap.keys}");
  }



  // 루틴 삭제 함수
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
    //화면에 반양하는 로직
    setState(() {});
  }

  // 루틴 이름을 가져오는 함수
  Future<List<String>> fetchRoutineNames() async {
    final uid = Provider.of<UserProvider>(context, listen: false).uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('Routine')
        .doc('Routinename')
        .get();

    if (doc.exists && doc.data() != null && doc.data()!['names'] != null) {
      return List<String>.from(doc.data()!['names']);
    } else {
      return [];
    }
  }

  //오늘 날짜에 해당하는 운동 루틴 데이터를 가져오는 함수
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

  //전체 날짜의 루틴 데이터를 가져오는 함수
  Future<List<Map<String, dynamic>>> _fetchAllRoutineData() async {
    var db = FirebaseFirestore.instance;
    try {
      QuerySnapshot snapshot = await db
          .collection('users')
          .doc(uid)
          .collection('Calender')
          .doc('health')
          .collection('routines')
          .get();

      List<Map<String, dynamic>> allDocs = [];
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        data['documentId'] = doc.id;
        allDocs.add(data);
      }
      return allDocs;
    } catch (e) {
      print('Error fetching all routine data: $e');
      return [];
    }
  }

  //치트 데이터 생성
  Future<Map<int, Map<String, int>>> _buildChartData() async {
    final allData =
        await _fetchAllRoutineData(); // 오늘 날짜만 아님, 모든 날짜를 기준으로 해야 정확

    Map<int, Map<String, int>> chartData = {};

    for (var doc in allData) {
      if (doc.containsKey('루틴 인덱스') &&
          doc.containsKey('오늘 총 볼륨') &&
          doc.containsKey('날짜')) {
        int index = doc['루틴 인덱스'];
        String date = doc['날짜'];
        int volume = doc['오늘 총 볼륨'];

        chartData.putIfAbsent(index, () => {});
        chartData[index]![date] = volume;
      }
    }

    return chartData;
  }

  // 날짜 선택 다이얼로그
  void _selectDate(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.blueGrey.shade900,
          contentPadding: EdgeInsets.all(8),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: double.maxFinite,
                child: TableCalendar(
                  focusedDay: selectedDate,
                  firstDay: DateTime(2000),
                  lastDay: DateTime(2100),
                  selectedDayPredicate: (day) => isSameDay(day, selectedDate),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      selectedDate = selected;
                    });
                    Navigator.pop(context); // 다이얼로그 닫기
                  },
                  calendarStyle: CalendarStyle(
                    markerDecoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    markersAlignment: Alignment.bottomCenter,
                    selectedDecoration: BoxDecoration(
                      color: Colors.cyan,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    defaultTextStyle: TextStyle(color: Colors.white),
                    weekendTextStyle: TextStyle(color: Colors.white70),
                  ),
                  eventLoader: (day) {
                    return _eventMap[DateTime(day.year, day.month, day.day)] ?? [];
                  },
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(color: Colors.white),
                    leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                    rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: Colors.grey[300]),
                    weekendStyle: TextStyle(color: Colors.grey[400]),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
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
                  return FutureBuilder<List<String>>(
                      future: _routineNamesFuture,
                      builder: (context, nameSnapshot) {
                        List<String> routineNames = nameSnapshot.data ?? [];
                        return ListView.builder(
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            var routine = data[index];
                            int? routineIndex = routine['루틴 인덱스'];
                            String title = routine['오늘 한 루틴이름'];

                            if (routineIndex != null) {
                              for (var name in routineNames) {
                                final parts = name.split('-');
                                if (parts.length == 2 && int.tryParse(parts[1]) == routineIndex) {
                                  title = parts[0]; // '-' 왼쪽
                                  break;
                                }
                              }
                            }
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '오늘 한 루틴 이름: $title',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          // 글자를 두껍게
                                          fontSize: 15, // 글자 크기를 20으로 설정
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.white),
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
                                    '운동 시작 시간: ${routine['운동 시작 시간']}',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  Text(
                                    '운동 종료 시간: ${routine['운동 종료 시간']}',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  SizedBox(height: 16),
                                  FutureBuilder<Map<int, Map<String, int>>>(
                                    future: _buildChartData(),
                                    builder: (context, chartSnapshot) {
                                      if (chartSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                            child: CircularProgressIndicator());
                                      }
                                      if (chartSnapshot.hasError) {
                                        return Center(
                                            child: Text(
                                                '오류 발생: ${chartSnapshot.error}'));
                                      }
                                      if (!chartSnapshot.hasData ||
                                          chartSnapshot.data!.isEmpty) {
                                        return Center(
                                            child: Text(
                                          '차트 데이터가 없습니다.',
                                          style: TextStyle(color: Colors.white),
                                        ));
                                      }

                                      Map<int, Map<String, int>> routineData =
                                          chartSnapshot.data!;
                                      int? index = routine['루틴 인덱스'];
                                      if (index == null ||
                                          !routineData.containsKey(index)) {
                                        return Center(
                                            child: Text(
                                          '차트 데이터가 없습니다.',
                                          style: TextStyle(color: Colors.white),
                                        ));
                                      }

                                      Map<String, int> data =
                                          routineData[index]!;

                                      // 날짜별로 정렬
                                      var sortedEntries = data.entries.toList()
                                        ..sort((a, b) => DateTime.parse(a.key)
                                            .compareTo(DateTime.parse(b.key)));

                                      // 정렬된 데이터를 기반으로 X축과 Y축 값을 추출
                                      List<String> xLabels = sortedEntries
                                          .map((entry) => DateFormat('MM/dd')
                                              .format(
                                                  DateTime.parse(entry.key)))
                                          .toList();
                                      List<double> yValues = sortedEntries
                                          .map(
                                              (entry) => entry.value.toDouble())
                                          .toList();

                                      // Y축 최소값과 최대값 계산
                                      double minY = yValues
                                          .reduce((a, b) => a < b ? a : b);
                                      double maxY = yValues
                                          .reduce((a, b) => a > b ? a : b);

                                      // FlSpot 데이터 생성
                                      List<FlSpot> spots = [];
                                      for (int i = 0; i < data.length; i++) {
                                        spots.add(
                                            FlSpot(i.toDouble(), yValues[i]));
                                      }

                                      return SizedBox(
                                        height: 250, // 높이를 살짝 늘림
                                        child: LineChart(
                                          LineChartData(
                                            backgroundColor: Colors.transparent,
                                            gridData: FlGridData(
                                              show: true,
                                              getDrawingHorizontalLine:
                                                  (value) => FlLine(
                                                color: Colors.grey.shade800,
                                                // 수평선 색상
                                                strokeWidth: 0.5,
                                              ),
                                              getDrawingVerticalLine: (value) =>
                                                  FlLine(
                                                color: Colors.grey.shade800,
                                                // 수직선 색상
                                                strokeWidth: 0.5,
                                              ),
                                            ),
                                            titlesData: FlTitlesData(
                                              bottomTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: false,
                                                  getTitlesWidget:
                                                      (value, meta) {
                                                    if (value.toInt() <
                                                        xLabels.length) {
                                                      return Text(
                                                        xLabels[value.toInt()],
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12),
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
                                                  showTitles: false,
                                                  getTitlesWidget:
                                                      (value, meta) {
                                                    return Text(
                                                      '${value.toInt()}',
                                                      style: TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 12),
                                                    );
                                                  },
                                                  interval: 1,
                                                  reservedSize: 32,
                                                ),
                                              ),
                                              rightTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                    showTitles: false),
                                              ),
                                              topTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                    showTitles: false),
                                              ),
                                            ),
                                            borderData: FlBorderData(
                                              show: true,
                                              border: Border(
                                                bottom: BorderSide(
                                                    color: Colors.white54,
                                                    width: 1),
                                                left: BorderSide(
                                                    color: Colors.white54,
                                                    width: 1),
                                                right: BorderSide.none,
                                                top: BorderSide.none,
                                              ),
                                            ),
                                            minX: 0,
                                            maxX:
                                                (yValues.length - 1).toDouble(),
                                            minY: minY,
                                            maxY: maxY,
                                            lineBarsData: [
                                              LineChartBarData(
                                                spots: spots,
                                                isCurved: true,
                                                // 부드러운 곡선
                                                barWidth: 4,
                                                // 선 굵기
                                                isStrokeCapRound: true,
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.cyan,
                                                    Colors.blueAccent
                                                  ], // 선 그래디언트
                                                ),
                                                belowBarData: BarAreaData(
                                                  show: true,
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.cyan
                                                          .withOpacity(0.3),
                                                      Colors.transparent,
                                                    ],
                                                  ),
                                                ),
                                                dotData: FlDotData(
                                                  show: true,
                                                  getDotPainter: (spot, percent,
                                                      barData, index) {
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
                                  routine['운동 목록'] != null &&
                                          routine['운동 목록'].isNotEmpty
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: routine['운동 목록']
                                              .map<Widget>((exercise) {
                                            String exerciseName =
                                                exercise['운동 이름'] ?? '운동 이름 없음';
                                            List<dynamic> sets =
                                                exercise['세트'] ?? [];

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 16.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    exerciseName,
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  ...sets
                                                      .asMap()
                                                      .entries
                                                      .map<Widget>((entry) {
                                                    int setIndex = entry.key;
                                                    var set = entry.value;

                                                    String reps =
                                                        set['reps'] ?? '0';
                                                    String weight =
                                                        set['weight'] ?? '0';

                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 8.0,
                                                              top: 4.0),
                                                      child: Text(
                                                        '세트 ${setIndex + 1}: 무게 ${weight}kg, 횟수 ${reps}회',
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 14),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        )
                                      : Text(
                                          '운동 기록이 없습니다.',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                ],
                              ),
                            );
                          },
                        );
                      });
                }),
          ),
        ],
      ),
    );
  }
}
