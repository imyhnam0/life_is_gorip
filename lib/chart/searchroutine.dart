import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/user_provider.dart';

class SearchRoutinePage extends StatefulWidget {
  const SearchRoutinePage({super.key});

  @override
  State<SearchRoutinePage> createState() => _SearchRoutinePageState();
}

class _SearchRoutinePageState extends State<SearchRoutinePage> {
  TextEditingController _controller = TextEditingController();
  String? searchTerm;
  String? uid;

  // 날짜별 세트 정보 (예: '2025-05-26': [{reps: 10, weight: 50}, ...])
  Map<String, List<Map<String, int>>> volumeData = {};

  @override
  void initState() {
    super.initState();
    uid = Provider.of<UserProvider>(context, listen: false).uid;
  }

  Future<void> fetchExerciseVolume(String name) async {
    final db = FirebaseFirestore.instance;
    Map<String, List<Map<String, int>>> result = {};

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
            if (item['운동 이름'] == name) {
              if (item['세트'] is List) {
                for (var s in item['세트']) {
                  int reps = int.tryParse(s['reps'].toString()) ?? 0;
                  int weight = int.tryParse(s['weight'].toString()) ?? 0;
                  result[date] = (result[date] ?? [])..add({'reps': reps, 'weight': weight});
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
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> dates = volumeData.keys.toList();

    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      appBar: AppBar(
        title: Text('운동 종목 검색', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey.shade900,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 검색 입력창
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '운동명을 입력하세요',
                      hintStyle: TextStyle(color: Colors.white60),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.cyan),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    final input = _controller.text.trim();
                    if (input.isNotEmpty) {
                      searchTerm = input;
                      fetchExerciseVolume(searchTerm!);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFD6F2FF), // ✨ 하늘색 배경
                    foregroundColor: Colors.black, // ✨ 글자색
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 3,
                    shadowColor: Colors.black26,
                  ),
                  child: Text(
                    "확인",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Colors.black, // 혹시 foregroundColor가 안 먹히면 이걸로
                    ),
                  ),
                ),

              ],
            ),
            SizedBox(height: 20),

            if (volumeData.isNotEmpty)
              Expanded(
                child: ListView(
                  children: [
                    // 운동 이름 (제목)
                    Text(
                      searchTerm ?? '',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),

                    // 차트
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
                                    .map((s) => s['reps']! * s['weight']!)
                                    .fold(0, (a, b) => a + b);
                                return FlSpot(index.toDouble(), totalVolume.toDouble());
                              }).toList(),
                              isCurved: true,
                              color: Colors.orange,
                              barWidth: 3,
                              belowBarData: BarAreaData(show: false),
                              dotData: FlDotData(show: true),
                            ),
                          ],
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: false,
                                getTitlesWidget: (value, meta) {
                                  int index = value.toInt();
                                  if (index >= 0 && index < dates.length) {
                                    return Text(
                                      DateFormat('MM/dd').format(DateTime.parse(dates[index])),
                                      style: TextStyle(color: Colors.white, fontSize: 10),
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

                    // 날짜 + 세트 reps × weight 목록
                    ...volumeData.entries.map((entry) {
                      final date = DateFormat('MM/dd').format(DateTime.parse(entry.key));
                      final sets = entry.value;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              date,
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
              )
            else if (searchTerm != null)
              Text(
                "해당 운동 기록이 없습니다.",
                style: TextStyle(color: Colors.white70),
              )
          ],
        ),
      ),
    );
  }
}
