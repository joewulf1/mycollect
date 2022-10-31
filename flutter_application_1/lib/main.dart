import 'package:firebase_database/firebase_database.dart';
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
      child: Center(child: Text(document.id)),
    ),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => collectionPage(choiceID: document.id)),
      );
    },
  ));
}

Widget collectCard(BuildContext context, DocumentSnapshot document) {
  // This is the base of the homepage items //
  return Card(
      child: InkWell(
    splashColor: Colors.blue.withAlpha(30),
    child: Container(
      height: 100,
      width: double.infinity,
      child: Center(child: Text(document["Name"])),
    ),
    // onTap: () {
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //         builder: (context) => collectionPage(choiceID: document.id)),
    //   );
    // },
  ));
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

class collectionPage extends StatelessWidget {
  collectionPage({Key? key, required this.choiceID});
  final String choiceID;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(choiceID),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("mycollections")
              .doc(choiceID)
              .collection("spefCollect")
              .snapshots(),
          builder: (context, snapshot) {
            print(choiceID);
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
                      collectCard(context, snapshot.data!.docs[index]));
            }
          }),
    );
  }
}
