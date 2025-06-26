import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/user_provider.dart';

class RoutineChartPage extends StatefulWidget {
  final String routineName;
  const RoutineChartPage({super.key, required this.routineName});

  @override
  State<RoutineChartPage> createState() => _RoutineChartPageState();
}

class _RoutineChartPageState extends State<RoutineChartPage> {
  String? uid;
  Map<String, List<Map<String, dynamic>>> volumeData = {}; // 날짜별 세트 목록

  @override
  void initState() {
    super.initState();
    uid = Provider.of<UserProvider>(context, listen: false).uid;
    fetchRoutineData();
  }

  Future<void> fetchRoutineData() async {
    final db = FirebaseFirestore.instance;
    Map<String, List<Map<String, dynamic>>> result = {};

    try {
      final snapshot = await db
          .collection("users")
          .doc(uid)
          .collection("Calender")
          .doc("health")
          .collection("routines")
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = data['날짜'];
        final exercises = data['운동 목록'];

        if (exercises is List) {
          for (var item in exercises) {
            if (item['운동 이름'] == widget.routineName) {
              final sets = item['세트'];
              if (sets is List) {
                for (var s in sets) {
                  int reps = int.tryParse(s['reps'].toString()) ?? 0;
                  int weight = int.tryParse(s['weight'].toString()) ?? 0;

                  result[date] = (result[date] ?? [])..add({
                    '운동 이름': item['운동 이름'],
                    'reps': reps,
                    'weight': weight,
                  });
                }
              }
            }
          }
        }
      }

      final sorted = Map.fromEntries(result.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key)));

      setState(() {
        volumeData = sorted;
      });
    } catch (e) {
      print("Error fetching routine data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> dates = volumeData.keys.toList();

    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      appBar: AppBar(
        title: Text(widget.routineName, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey.shade900,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: volumeData.isEmpty
            ? Center(
          child: Text(
            "운동 기록이 없습니다.",
            style: TextStyle(color: Colors.white70),
          ),
        )
            : ListView(
          children: [
            // 📈 차트
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: volumeData.entries
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                        final index = entry.key;
                        final sets = entry.value.value;
                        final totalVolume = sets
                            .map((s) => (s['reps'] ?? 0) * (s['weight'] ?? 0))
                            .fold<num>(0, (a, b) => a + b);

                        return FlSpot(index.toDouble(),
                            totalVolume.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.cyanAccent,
                      barWidth: 3,
                      belowBarData: BarAreaData(show: false),
                      dotData: FlDotData(show: true),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < dates.length) {
                            return Text(
                              DateFormat('MM/dd')
                                  .format(DateTime.parse(dates[index])),
                              style: TextStyle(
                                  color: Colors.white, fontSize: 10),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  minY: 0,
                ),
              ),
            ),
            SizedBox(height: 20),

            // 🗓 운동 세트 기록
            ...volumeData.entries.map((entry) {
              final dateStr = DateFormat('MM/dd')
                  .format(DateTime.parse(entry.key));
              final sets = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    ...sets.map((s) => Padding(
                      padding: const EdgeInsets.only(left: 10, top: 2),
                      child: Text(
                        'reps: ${s['reps']} × weight: ${s['weight']}',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )),
                  ],
                ),
              );
            }).toList()
          ],
        ),
      ),
    );
  }
}
