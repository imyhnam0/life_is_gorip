import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class RoutineChart extends StatefulWidget {
  @override
  State<RoutineChart> createState() => _RoutineChartState();
}

class _RoutineChartState extends State<RoutineChart> {
  int maxVolume = 0;
  int minVolume = 0;
  String? selectname;

  Future<List<String>> fetchCollectionNames() async {
    List<String> names = [];

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("Routine")
          .doc('Routinename')
          .collection('Names')
          .get();

      names = querySnapshot.docs.map((doc) => doc['name'] as String).toList();
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
          .collection('Calender')
          .doc('health')
          .collection('routines')
          .get();

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
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

  void _showNamesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('이름 목록'),
          content: FutureBuilder<List<String>>(
            future: fetchCollectionNames(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('오류 발생: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('데이터가 없습니다.'));
              } else {
                List<String> names = snapshot.data!;
                return Container(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: names.length,
                    itemBuilder: (context, index) {
                      return CheckboxListTile(
                        title: Text(names[index]),
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
              child: Text('닫기'),
              onPressed: () {
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
        title: Text(
          '루틴 변화 추세',
          style: TextStyle(
            color: Colors.white,
          ),
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
          OutlinedButton(
            onPressed: () {
              _showNamesDialog(context);
            },
            child: Text(
              "루틴이름",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white, width: 1),
            ),
          ),
        ],
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

          if (selectname != null && routineData.containsKey(selectname)) {
            return _buildChart(selectname!, routineData[selectname]!);
          } else {
            return ListView(
              children: routineData.entries.map((entry) {
                return _buildChart(entry.key, entry.value);
              }).toList(),
            );
          }
        },
      ),
    );
  }

  Widget _buildChart(String routineName, Map<String, int> data) {
    DateFormat dateFormat = DateFormat('MM/dd');
    List<String> xLabels = data.keys
        .map((date) => dateFormat.format(DateTime.parse(date)))
        .toList();
    List<double> yValues = data.values.map((volume) => volume.toDouble()).toList();

    double minY = yValues.reduce((a, b) => a < b ? a : b);
    double maxY = yValues.reduce((a, b) => a > b ? a : b);

    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), yValues[i]));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            routineName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < xLabels.length) {
                          return Text(
                            xLabels[value.toInt()],
                            style: TextStyle(color: Colors.white),
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
                          style: TextStyle(color: Colors.white),
                        );
                      },
                      interval: 1,
                      reservedSize: 28,
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
                    bottom: BorderSide(color: Colors.white, width: 1),
                    left: BorderSide(color: Colors.white, width: 1),
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
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}