import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'user_provider.dart';
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
    List<String> names = [];

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
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
          .collection('users')
          .doc(uid)
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
        double minY = [weightData.values, muscleData.values, fatData.values]
            .expand((e) => e)
            .reduce((a, b) => a < b ? a : b);
        double maxY = [weightData.values, muscleData.values, fatData.values]
            .expand((e) => e)
            .reduce((a, b) => a > b ? a : b);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '몸무게 변화 추세',
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
                            if (value.toInt() < dates.length) {
                              return Column(
                                children: [
                                  Text(
                                    DateFormat('MM/dd').format(
                                        DateTime.parse(dates[value.toInt()])),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
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
                          interval: 0.01,
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
                    maxX: (dates.length - 1).toDouble(),
                    minY: minY,
                    maxY: maxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: weightData.entries
                            .map((e) => FlSpot(
                                dates.indexOf(e.key).toDouble(), e.value))
                            .toList(),
                        isCurved: true,
                        barWidth: 5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(show: false),
                        color: Colors.red,
                      ),
                      LineChartBarData(
                        spots: muscleData.entries
                            .map((e) => FlSpot(
                                dates.indexOf(e.key).toDouble(), e.value))
                            .toList(),
                        isCurved: true,
                        barWidth: 5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(show: false),
                        color: Colors.green,
                      ),
                      LineChartBarData(
                        spots: fatData.entries
                            .map((e) => FlSpot(
                                dates.indexOf(e.key).toDouble(), e.value))
                            .toList(),
                        isCurved: true,
                        barWidth: 5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(show: false),
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  
                  Text(
                    '몸무게',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Icon(Icons.circle, color: Colors.red),
                 SizedBox(width: 20),
                  Text(
                    '골격근량',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                      Icon(Icons.circle, color: Colors.green),
                  SizedBox(width: 20),
                  Text(
                    '체지방량',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Icon(Icons.circle, color: Colors.blue),
                ],
              ),
              SizedBox(height: 10),
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildChart(String routineName, Map<String, int> data) {
    DateFormat dateFormat = DateFormat('MM/dd');
    List<String> xLabels = data.keys
        .map((date) => dateFormat.format(DateTime.parse(date)))
        .toList();
    List<double> yValues =
        data.values.map((volume) => volume.toDouble()).toList();

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
