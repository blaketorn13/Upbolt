import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(UpBoltApp());
}

class UpBoltApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(primary: Colors.blueAccent),
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TimeOfDay? alarmTime;
  Timer? timer;
  Duration remaining = Duration.zero;
  bool alarmActive = false;
  int streak = 0;

  @override
  void initState() {
    super.initState();
    loadStreak();
  }

  Future<void> loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      streak = prefs.getInt('streak') ?? 0;
    });
  }

  Future<void> saveStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('streak', streak);
  }

  void setAlarm(TimeOfDay picked) {
    setState(() {
      alarmTime = picked;
      alarmActive = true;
    });

    DateTime now = DateTime.now();
    DateTime alarmDate = DateTime(
      now.year,
      now.month,
      now.day,
      picked.hour,
      picked.minute,
    );

    if (alarmDate.isBefore(now)) {
      alarmDate = alarmDate.add(Duration(days: 1));
    }

    remaining = alarmDate.difference(now);

    timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        remaining = remaining - Duration(seconds: 1);
        if (remaining.inSeconds <= 0) {
          timer?.cancel();
          showChallenge();
        }
      });
    });
  }

  void showChallenge() {
    int a = Random().nextInt(10) + 1;
    int b = Random().nextInt(10) + 1;
    int answer = a + b;

    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("Solve to Wake Up ⚡"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("$a + $b = ?"),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
            )
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (int.tryParse(controller.text) == answer) {
                Navigator.pop(context);
                setState(() {
                  streak++;
                  alarmActive = false;
                });
                saveStreak();
              }
            },
            child: Text("Submit"),
          )
        ],
      ),
    );
  }

  String formatDuration(Duration d) {
    return "${d.inHours.toString().padLeft(2, '0')}:"
        "${(d.inMinutes % 60).toString().padLeft(2, '0')}:"
        "${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("UpBolt ⚡"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Streak: $streak ⚡",
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            alarmActive
                ? Text(
                    formatDuration(remaining),
                    style: TextStyle(fontSize: 48),
                  )
                : Text(
                    "No Alarm Set",
                    style: TextStyle(fontSize: 24),
                  ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null) {
                  setAlarm(picked);
                }
              },
              child: Text("Set Alarm"),
            ),
          ],
        ),
      ),
    );
  }
}
