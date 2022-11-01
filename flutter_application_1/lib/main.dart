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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => addCollection()),
          );
        },
        tooltip: 'Add Collection',
        child: const Icon(Icons.add),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => addItem(
                      choiceID: choiceID,
                    )),
          );
        },
        tooltip: 'Add item to collection',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class addCollection extends StatefulWidget {
  @override
  State<addCollection> createState() => _addCollectionState();
}

class _addCollectionState extends State<addCollection> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController collectionName = TextEditingController();
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Collection'),
      content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: collectionName,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Name of Collection',
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (_formKey.currentState!.validate()) {
                    FirebaseFirestore.instance
                        .collection("mycollections")
                        .doc(collectionName.text)
                        .set({});
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          )),
    );
  }
}

class addItem extends StatefulWidget {
  @override
  addItem({Key? key, required this.choiceID});
  final String choiceID;
  State<addItem> createState() => _addItemState(choiceID: choiceID);
}

class _addItemState extends State<addItem> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController collectionName = TextEditingController();
  _addItemState({Key? key, required this.choiceID});
  final String choiceID;
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add an item to the collection'),
      content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: collectionName,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (_formKey.currentState!.validate()) {
                    FirebaseFirestore.instance
                        .collection("mycollections")
                        .doc(choiceID)
                        .collection("spefCollect")
                        .doc()
                        .set({
                      "Name": collectionName.text,
                    });
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          )),
    );
  }
}
