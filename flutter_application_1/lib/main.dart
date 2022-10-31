import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

bool loading = false;

Future<void> main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyCollect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: const MyHomePage(title: 'MyCollect Landing Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // int _counter = 0;

  // void _incrementCounter() {
  //   setState(() {
  //     _counter++;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.title),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("mycollections")
              .snapshots(),
          builder: (context, snapshot) {
            print(snapshot.data?.docs.length);
            if (!snapshot.hasData) {
              return loading
                  ? Loading()
                  : const Center(
                      child: Text(
                      "Loading",
                    ));
            } else {
              return ListView.builder(
                  itemExtent: 80.0,
                  itemCount: snapshot.data?.docs.length,
                  itemBuilder: (context, index) =>
                      baseCard(context, snapshot.data!.docs[index]));
            }
          }),
      floatingActionButton: const FloatingActionButton(
        onPressed: null,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}

Widget baseCard(BuildContext context, DocumentSnapshot document) {
  // This is the base of the homepage items //
  return Card(
      child: InkWell(
          splashColor: Colors.blue.withAlpha(30),
          child: Container(
            height: 100,
            width: double.infinity,
            child: Center(child: Text("Penis")),
          )));
}

class Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: const Center(
        child: SpinKitChasingDots(
          color: Color(0xFF500000),
          size: 50.0,
        ),
      ),
    );
  }
}
