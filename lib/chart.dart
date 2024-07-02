import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class RoutineChart extends StatelessWidget {
  int maxVolume = 0;
  int minVolume = 0;

  Future<Map<String, Map<String, int>>> _RoutineChartGet() async {
    var db = FirebaseFirestore.instance;
    Map<String, Map<String, int>> routineData = {};

    int maxVolume = 0;
    int minVolume = 0;

    try {
      QuerySnapshot snapshot = await db
          .collection('Calender')
          .doc('health')
          .collection('routines')
          .get();

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String routineName = data['오늘 한 루틴이름'];
        int volume = data['오늘 총 볼륨'] ?? 0;
        String formattedDate = data['날짜']; // '날짜' 필드를 사용하여 날짜를 가져옵니다.

        if (routineData.containsKey(routineName)) {
          routineData[routineName]![formattedDate] = volume;
        } else {
          routineData[routineName] = {formattedDate: volume};
        }

        // 가장 큰 볼륨 값과 가장 작은 볼륨 값을 추적합니다.
        if (routineData.isNotEmpty) {
          if (volume > maxVolume) {
            maxVolume = volume;
          }
          if (minVolume == 0 || volume < minVolume) {
            minVolume = volume;
          }
        }
      }

      return routineData;
    } catch (e) {
      print('Error fetching documents: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('루틴 변화 추세'),
        ),
        body: FutureBuilder<Map<String, Map<String, int>>>(
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

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: routineData.entries.map((entry) {
                  String routineName = entry.key;
                  Map<String, int> data = entry.value;

                  // X축 라벨을 위한 날짜 포맷터
                  DateFormat dateFormat = DateFormat('MM/dd');

                  // X축 라벨과 Y축 값을 추출
                  List<String> xLabels = data.keys
                      .map((date) => dateFormat.format(DateTime.parse(date)))
                      .toList();
                  List<double> yValues =
                      data.values.map((volume) => volume.toDouble()).toList();

                  // Y축 최소값과 최대값 계산
                  double minY = yValues.reduce((a, b) => a < b ? a : b);
                  double maxY = yValues.reduce((a, b) => a > b ? a : b);

                  // FlSpot 데이터 생성
                  List<FlSpot> spots = [];
                  for (int i = 0; i < data.length; i++) {
                    spots.add(FlSpot(i.toDouble(), yValues[i]));
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routineName,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 300,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false), //표 안에 점선들 표시
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true, //x축에 내 날짜 값들 표시
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() < xLabels.length) {
                                      return Text(xLabels[value.toInt()]);
                                    }
                                    return Text('');
                                  },
                                  interval: 1,
                                  reservedSize: 22,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: false, //y축 값들 표시할거냐
                                  getTitlesWidget: (value, meta) {
                                    return Text('${value.toInt()}');
                                  },
                                  interval: 1,
                                  reservedSize: 28,
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: false), // right y축 타이틀 제거
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: false), // top x축 타이틀 제거
                              ),
                            ),
                            borderData: FlBorderData(
                              //차트의 x y축 경계 표시할거냐
                              show: true,
                              border: Border(
                                bottom: BorderSide(
                                    color: const Color(0xff37434d),
                                    width: 1), // x축 경계
                                left: BorderSide(
                                    color: const Color(0xff37434d),
                                    width: 1), // y축 경계
                                right: BorderSide.none, // 오른쪽 경계 제거
                                top: BorderSide.none, // 상단 경계 제거
                              ),
                            ),
                            minX: 0,
                            maxX: (data.length - 1).toDouble(),
                            minY: minY,
                            maxY: maxY,
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: false,
                                barWidth: 5,
                                isStrokeCapRound: true,
                                dotData: FlDotData(show: true), //점 찍을거냐
                                belowBarData:
                                    BarAreaData(show: false), //라인 아래 영역
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}

void main() {
  runApp(RoutineChart());
}
