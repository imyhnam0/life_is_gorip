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

  Future<List<Map<String, dynamic>>> _fetchFoodData() async {
    var db = FirebaseFirestore.instance;
    String todayDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    try {
      QuerySnapshot snapshot = await db
          .collection('users')
          .doc(uid)
          .collection('Calender')
          .doc('food')
          .collection('todayfood')
          .where('date', isEqualTo: todayDate)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching documents: $e');
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

  List<PieChartSectionData> showingSections(
      double carbs, double protein, double fat) {
    final total = carbs + protein + fat;
    if (total == 0) return [];

    return [
      PieChartSectionData(
        color: Colors.blue,
        value: (carbs / total) * 100,
        title: '${(carbs / total * 100).toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.red,
        value: (protein / total) * 100,
        title: '${(protein / total * 100).toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.green,
        value: (fat / total) * 100,
        title: '${(fat / total * 100).toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

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
                backgroundColor: MaterialStateProperty.all<Color>(
                  Colors.blueGrey.shade700,
                ),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
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
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchFoodData(),
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
                var totalCarbs = data.fold<double>(
                    0.0, (sum, item) => sum + (item['totalCarbs'] ?? 0.0));
                var totalProtein = data.fold<double>(
                    0.0, (sum, item) => sum + (item['totalProtein'] ?? 0.0));
                var totalFat = data.fold<double>(
                    0.0, (sum, item) => sum + (item['totalFat'] ?? 0.0));
                var totalCalories = data.fold<double>(
                    0.0, (sum, item) => sum + (item['totalCalories'] ?? 0.0));

                return ListView(children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '오늘 먹은 칼로리: $totalCalories',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold, // 글자를 두껍게
                            fontSize: 15, // 글자 크기를 20으로 설정
                          ),
                        ),
                        Text(
                          '탄수화물: $totalCarbs',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          '단백질: $totalProtein',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          '지방: $totalFat',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: <Widget>[
                            Text(
                              '탄수화물 : ',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            Container(
                              width: 12,
                              height: 12,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 10), // 간격 추가
                            Text(
                              '단백질 : ',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            Container(
                              width: 12,
                              height: 12,
                              color: Colors.red,
                            ),
                            SizedBox(width: 10), // 간격 추가
                            Text(
                              '지방 : ',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            Container(
                              width: 12,
                              height: 12,
                              color: Colors.green,
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sections: showingSections(
                                  totalCarbs, totalProtein, totalFat),
                              centerSpaceRadius: 40,
                              sectionsSpace: 0,
                              pieTouchData: PieTouchData(
                                touchCallback:
                                    (FlTouchEvent event, pieTouchResponse) {},
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]);
              },
            ),
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
                          Text(
                            '오늘 한 루틴 이름: ${routine['오늘 한 루틴이름']}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold, // 글자를 두껍게
                              fontSize: 15, // 글자 크기를 20으로 설정
                            ),
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

                              // X축 라벨을 위한 날짜 포맷터
                              DateFormat dateFormat = DateFormat('MM/dd');

                              // X축 라벨과 Y축 값을 추출
                              List<String> xLabels = data.keys
                                  .map((date) =>
                                      dateFormat.format(DateTime.parse(date)))
                                  .toList();
                              List<double> yValues = data.values
                                  .map((volume) => volume.toDouble())
                                  .toList();

                              // Y축 최소값과 최대값 계산
                              double minY =
                                  yValues.reduce((a, b) => a < b ? a : b);
                              double maxY =
                                  yValues.reduce((a, b) => a > b ? a : b);

                              // FlSpot 데이터 생성
                              List<FlSpot> spots = [];
                              for (int i = 0; i < data.length; i++) {
                                spots.add(FlSpot(i.toDouble(), yValues[i]));
                              }

                              return SizedBox(
                                height: 200,
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            if (value.toInt() <
                                                xLabels.length) {
                                              return Text(
                                                xLabels[value.toInt()],
                                                style: TextStyle(
                                                    color: Colors.white),
                                              );
                                            }
                                            return Text('');
                                          },
                                          interval: 1,
                                          reservedSize: 22,
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                          getTitlesWidget: (value, meta) {
                                            return Text(
                                              '${value.toInt()}',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            );
                                          },
                                          interval: 1,
                                          reservedSize: 28,
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border(
                                        bottom: BorderSide(
                                            color: Colors.white, width: 1),
                                        left: BorderSide(
                                            color: Colors.white, width: 1),
                                        right: BorderSide.none,
                                        top: BorderSide.none,
                                      ),
                                    ),
                                    minX: 0,
                                    maxX: (data.length - 1).toDouble(),
                                    minY: minY,
                                    maxY: maxY,
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: spots,
                                        isCurved: true,
                                        barWidth: 5,
                                        isStrokeCapRound: true,
                                        dotData: FlDotData(show: true),
                                        belowBarData: BarAreaData(show: false),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
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
