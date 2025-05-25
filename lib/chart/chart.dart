import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/user_provider.dart';
import 'package:provider/provider.dart';

class RoutineChart extends StatefulWidget {
  @override
  State<RoutineChart> createState() => _RoutineChartState();
}

class _RoutineChartState extends State<RoutineChart> {
  int maxVolume = 0;
  int minVolume = 0;
  String? selectname;
  String? uid;
  bool isRoutineChart = true; // 현재 보여줄 차트 종류를 결정

  void initState() {
    super.initState();
    uid = Provider.of<UserProvider>(context, listen: false).uid;
  }

  Future<List<String>> fetchCollectionNames() async {
    //루틴 이름 불러오는 거 저장
    List<String> names = [];

    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('Routine')
          .doc('Myroutine')
          .get();

      if (documentSnapshot.exists) {
        var data = documentSnapshot.data() as Map<String, dynamic>;
        names = data.keys.toList();
      }
    } catch (e) {
      print('Error fetching collection names: $e');
    }

    return names;
  }

  Future<Map<String, Map<String, int>>> _RoutineChartGet() async {
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
        // print('👉 문서: ${doc.id}');
        // print('👉 data.keys: ${data.keys}');
        String routineName = data['오늘 한 루틴이름'];
        int volume = data['오늘 총 볼륨'] ?? 0;
        String formattedDate = data['날짜'];

        if (routineData.containsKey(routineName)) {
          routineData[routineName]![formattedDate] = volume;
        } else {
          routineData[routineName] = {formattedDate: volume};
        }

        if (volume > maxVolume) {
          maxVolume = volume;
        }
        if (minVolume == 0 || volume < minVolume) {
          minVolume = volume;
        }
      }

      return routineData;
    } catch (e) {
      print('Error fetching documents: $e');
      return {};
    }
  }

  Future<Map<String, Map<String, double>>> _WeightChartGet() async {
    var db = FirebaseFirestore.instance;
    Map<String, Map<String, double>> weightData = {
      'weight': {},
      'muscle': {},
      'fat': {},
    };

    try {
      QuerySnapshot snapshot = await db
          .collection('users')
          .doc(uid)
          .collection('Calender')
          .doc('body')
          .collection('weight')
          .get();

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        double weight = double.parse(data['weight'] ?? '0');
        double muscle = double.parse(data['muscleMass'] ?? '0');
        double fat = double.parse(data['bodyFat'] ?? '0');
        String formattedDate = data['date'];

        weightData['weight']![formattedDate] = weight;
        weightData['muscle']![formattedDate] = muscle;
        weightData['fat']![formattedDate] = fat;
      }

      return weightData;
    } catch (e) {
      print('Error fetching weight data: $e');
      return {};
    }
  }

  void _showNamesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.blueGrey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            '이름 목록',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: FutureBuilder<List<String>>(
            future: fetchCollectionNames(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(color: Colors.white));
              } else if (snapshot.hasError) {
                return Center(
                    child: Text('오류 발생: ${snapshot.error}',
                        style: TextStyle(color: Colors.white)));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                    child: Text('데이터가 없습니다.',
                        style: TextStyle(color: Colors.white)));
              } else {
                List<String> names = snapshot.data!;
                return Container(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: names.length,
                    itemBuilder: (context, index) {
                      return CheckboxListTile(
                        checkColor: Colors.black,
                        activeColor: Colors.white,
                        title: Text(
                          names[index],
                          style: TextStyle(color: Colors.white),
                        ),
                        value: selectname == names[index],
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectname = names[index];
                            } else {
                              selectname = null;
                            }
                          });
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                );
              }
            },
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
                '닫기',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRoutineData(String routineName) async {
  var db = FirebaseFirestore.instance;

  try {
    QuerySnapshot snapshot = await db
        .collection('users')
        .doc(uid)
        .collection('Calender')
        .doc('health')
        .collection('routines')
        .where('오늘 한 루틴이름', isEqualTo: routineName)
        .get();

    for (var doc in snapshot.docs) {
      await db
          .collection('users')
          .doc(uid)
          .collection('Calender')
          .doc('health')
          .collection('routines')
          .doc(doc.id)
          .delete();
    }

    setState(() {
      // 데이터를 삭제한 후 UI를 갱신하기 위해 FutureBuilder를 다시 호출합니다.
    });
  } catch (e) {
    print('Error deleting routine data: $e');
  }
}


  void _showChartOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          backgroundColor: Colors.blueGrey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            '차트 선택',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          children: [
            SimpleDialogOption(
              child: Text(
                '루틴 변화 추세',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              onPressed: () {
                setState(() {
                  isRoutineChart = true;
                });
                Navigator.of(context).pop();
              },
            ),
            SimpleDialogOption(
              child: Text(
                '몸무게 변화 추세',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              onPressed: () {
                setState(() {
                  isRoutineChart = false;
                });
                Navigator.of(context).pop();
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
      backgroundColor: Colors.blueGrey.shade900,
      appBar: AppBar(
        title: InkWell(
          onTap: () => _showChartOptions(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isRoutineChart ? '루틴 변화 추세' : '몸무게 변화 추세',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Oswald',
                ),
              ),
              Icon(Icons.arrow_drop_down, color: Colors.white),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade900,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
          tooltip: '뒤로 가기',
        ),
        actions: [
          if (isRoutineChart)
            Padding(
              padding: const EdgeInsets.only(right: 5.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  _showNamesDialog(context);
                },
                icon: Icon(
                  Icons.list,
                  color: Colors.white,
                  size: 12,
                ),
                label: Text(
                  "루틴이름",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade700,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.black,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
        ],
      ),
      body: isRoutineChart ? _buildRoutineChart() : _buildWeightChart(),
    );
  }

  Widget _buildRoutineChart() {
    return FutureBuilder<Map<String, Map<String, int>>>(
      future: _RoutineChartGet(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No data available'));
        }

        Map<String, Map<String, int>> routineData = snapshot.data!;

        if (selectname != null && routineData.containsKey(selectname)) {
          print('🔥 selectname: $selectname');
          print('🔥 routineData keys: ${routineData.keys}');

          return _buildChart(selectname!, routineData[selectname]!);
        } else {
          return ListView(
            children: routineData.entries.map((entry) {
              return _buildChart(entry.key, entry.value);
            }).toList(),
          );
        }
      },
    );
  }

  Widget _buildWeightChart() {
    return FutureBuilder<Map<String, Map<String, double>>>(
      future: _WeightChartGet(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No data available'));
        }

        Map<String, Map<String, double>> data = snapshot.data!;
        Map<String, double> weightData = data['weight']!;
        Map<String, double> muscleData = data['muscle']!;
        Map<String, double> fatData = data['fat']!;

        List<String> dates = weightData.keys.toList();
        double minYWeight = weightData.values.reduce((a, b) => a < b ? a : b);
        double maxYWeight = weightData.values.reduce((a, b) => a > b ? a : b);
        double minYMuscle = muscleData.values.reduce((a, b) => a < b ? a : b);
        double maxYMuscle = muscleData.values.reduce((a, b) => a > b ? a : b);
        double minYFat = fatData.values.reduce((a, b) => a < b ? a : b);
        double maxYFat = fatData.values.reduce((a, b) => a > b ? a : b);

        return ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            // 화면 상단의 데이터 테이블
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '날짜',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      ...dates.map((date) => Text(
                        DateFormat('MM/dd').format(DateTime.parse(date)),
                        style: TextStyle(color: Colors.white),
                      )),
                    ],
                  ),
                  SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '몸무게',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      ...dates.map((date) => Text(
                        weightData[date].toString(),
                        style: TextStyle(color: Colors.white),
                      )),
                    ],
                  ),
                  SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '골격근량',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      ...dates.map((date) => Text(
                        muscleData[date].toString(),
                        style: TextStyle(color: Colors.white),
                      )),
                    ],
                  ),
                  SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '체지방량',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      ...dates.map((date) => Text(
                        fatData[date].toString(),
                        style: TextStyle(color: Colors.white),
                      )),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // 몸무게 변화 차트
            _buildSingleChart(
              title: "몸무게 변화 추세",
              data: weightData,
              dates: dates,
              minY: minYWeight,
              maxY: maxYWeight,
              color: Colors.cyan,
            ),
            SizedBox(height: 20),
            // 골격근량 변화 차트
            _buildSingleChart(
              title: "골격근량 변화 추세",
              data: muscleData,
              dates: dates,
              minY: minYMuscle,
              maxY: maxYMuscle,
              color: Colors.cyan,
            ),
            SizedBox(height: 20),
            // 체지방량 변화 차트
            _buildSingleChart(
              title: "체지방량 변화 추세",
              data: fatData,
              dates: dates,
              minY: minYFat,
              maxY: maxYFat,
              color: Colors.cyan,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSingleChart({
    required String title,
    required Map<String, double> data,
    required List<String> dates,
    required double minY,
    required double maxY,
    required Color color,
  }) {
    var sortedEntries = data.entries.toList()
      ..sort((a, b) => DateTime.parse(a.key).compareTo(DateTime.parse(b.key)));

    // x축 및 y축 값 생성
    List<FlSpot> spots = sortedEntries
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.value))
        .toList();

    // Y축 범위 조정 (0.1 추가로 범위를 약간 확장)
    minY = minY - 0.1;
    maxY = maxY + 0.1;


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(
          height: 250, // 차트 높이를 살짝 증가
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.blueGrey.shade700.withOpacity(0.5), // 수평선 색상
                  strokeWidth: 0.5,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: Colors.blueGrey.shade700.withOpacity(0.5), // 수직선 색상
                  strokeWidth: 0.5,
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < dates.length) {
                        return Text(
                          DateFormat('MM/dd').format(
                              DateTime.parse(dates[value.toInt()])),
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        );
                      }
                      return Text('');
                    },
                    interval: 1,
                    reservedSize: 30, // 축 레이블 공간 확장
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false, // Y축 레이블 표시
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}kg',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      );
                    },
                    interval: (maxY - minY) / 5, // Y축 간격
                    reservedSize: 40,
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
                border: Border.all(color: Colors.white10, width: 1),
              ),
              minX: 0,
              maxX: (dates.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true, // 선을 부드럽게 처리
                  barWidth: 3.5, // 선 두께
                  isStrokeCapRound: true,
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  dotData: FlDotData(
                    show: true, // 점 표시
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 3, // 점 크기
                        color: color,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey,
                      Colors.cyanAccent,
                    ], // 선의 그래디언트
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildChart(String routineName, Map<String, int> data) {
    var sortedEntries = data.entries.toList()
      ..sort((a, b) => DateTime.parse(a.key).compareTo(DateTime.parse(b.key)));

    List<String> xLabels = sortedEntries
        .map((entry) => DateFormat('MM/dd').format(DateTime.parse(entry.key)))
        .toList();
    List<double> yValues =
    sortedEntries.map((entry) => entry.value.toDouble()).toList();

    double minY = yValues.reduce((a, b) => a < b ? a : b);
    double maxY = yValues.reduce((a, b) => a > b ? a : b);

    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), yValues[i]));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Colors.blueGrey.shade800,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    routineName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.grey),
                    onPressed: () {
                      _deleteRoutineData(routineName);
                    },
                  ),
                ],
              ),
              SizedBox(height: 200, child: _buildLineChart(spots, xLabels, minY, maxY)),
              SizedBox(height: 20),
              Text(
                '날짜별 볼륨량',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Divider(color: Colors.white54),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: sortedEntries.length,
                itemBuilder: (context, index) {
                  var entry = sortedEntries[index];
                  String date = DateFormat('MM/dd').format(DateTime.parse(entry.key));
                  int volume = entry.value;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          date,
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        Text(
                          '$volume',
                          style: TextStyle(color: Colors.lightBlue, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(
      List<FlSpot> spots, List<String> xLabels, double minY, double maxY) {
    return LineChart(
      LineChartData(
        backgroundColor: Colors.transparent,
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.blueGrey.shade500,
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.blueGrey.shade500, // 수직선 색상 조정
            strokeWidth: 1,
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
                    style: TextStyle(color: Colors.white70, fontSize: 12),
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
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                );
              },
              interval: 1,
              reservedSize: 28,
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false, // 오른쪽 숫자 제거
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false, // 상단 숫자 제거
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white10, width: 1),
        ),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(colors: [Colors.blue, Colors.cyan]),
            barWidth: 3,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [Colors.blue.withOpacity(0.3), Colors.transparent],
              ),
            ),
            dotData: FlDotData(
              show: true,

            ),
          ),
        ],
      ),
    );
  }
}
