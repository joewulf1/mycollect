import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

bool loading = false;
Color themeColor = const Color.fromARGB(255, 83, 114, 78);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        primarySwatch: Colors.green,
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
              return Center(child: Loading());
            } else {
              return ListView.builder(
                  itemExtent: 80.0,
                  itemCount: snapshot.data?.docs.length,
                  itemBuilder: (context, index) =>
                      baseCard(context, snapshot.data!.docs[index]));
            }
          }),
      floatingActionButton: FloatingActionButton(
        heroTag: "createCollection",
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
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Card(
        child: InkWell(
      splashColor: Colors.blue.withAlpha(30),
      child: SizedBox(
        height: 100,
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(child: Text(document.id)),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FloatingActionButton.small(
                  heroTag: document.id,
                  child: const Icon(Icons.delete),
                  onPressed: () {
                    print("object");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              youSure(context, document, document.id)),
                    );
                  }),
            ),
          ],
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => collectionPage(choiceID: document.id)),
        );
      },
    )),
  );
}

Widget collectCard(
    BuildContext context, DocumentSnapshot document, String choiceID) {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final double widthScreen = MediaQuery.of(context).size.width;
  String docID = document.id;

  return Stack(
    children: [
      Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: widthScreen * .75,
          child: Card(
              child: ExpansionTile(title: Text(document["Name"]), children: [
            SizedBox(
              child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("mycollections")
                      .doc(choiceID)
                      .collection("spefCollect")
                      .doc(docID)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Text("Loading.....");
                    } else {
                      return ListView(
                        shrinkWrap: true,
                        children: (snapshot.data?.get("Descriptors")
                                as Map<String, dynamic>)
                            .entries
                            .map((MapEntry mapEntry) {
                          return ListTile(
                              title: Text(mapEntry.key),
                              trailing: Text(mapEntry.value.toString()));
                        }).toList(),
                      );
                    }
                    ;
                  }),
            ),
            SizedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: FloatingActionButton.small(
                        heroTag: docID,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => addField(
                                      choiceID: choiceID,
                                      docID: docID,
                                    )),
                          );
                        },
                        tooltip: 'Add field to collection',
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: FloatingActionButton.small(
                          heroTag: "itemDeletion",
                          child: const Icon(Icons.delete),
                          onPressed: () {
                            delItem(docID, choiceID);
                          }),
                    ),
                  ),
                ],
              ),
            ),
          ])),
        ),
      ),
    ],
  );
}

Future delItem(String docID, String choiceID) {
  final fireStoreReference = FirebaseFirestore.instance;
  return fireStoreReference
      .collection("mycollections")
      .doc(choiceID)
      .collection("spefCollect")
      .doc(docID)
      .delete();
}

Future delCollection(String docID) {
  final fireStoreReference = FirebaseFirestore.instance;
  return fireStoreReference.runTransaction((transaction) async => transaction
      .delete(fireStoreReference.collection("mycollections").doc(docID)));
}

Future delCollectionAdd(String choiceID) {
  final fireStoreReference = FirebaseFirestore.instance;
  return fireStoreReference
      .collection("mycollections")
      .doc(choiceID)
      .collection("spefCollect")
      .doc() /* Add code that refrences every document in the collection */
      .delete();
}

Widget youSure(
    BuildContext context, DocumentSnapshot document, String choiceID) {
  return AlertDialog(
      title: Text("Are you sure you want to delete $choiceID"),
      content: ElevatedButton(
        onPressed: () {
          delCollection(document.id);
          delCollectionAdd(document.id);
          Navigator.of(context).pop();
        },
        child: Text("Delete"),
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
    final double widthScreen = MediaQuery.of(context).size.width;
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
            if (!snapshot.hasData) {
              return loading
                  ? Loading()
                  : const Center(
                      child: Text(
                      "Loading",
                    ));
            } else {
              return ListView.builder(
                  itemCount: snapshot.data?.docs.length,
                  itemBuilder: (context, index) => collectCard(
                      context, snapshot.data!.docs[index], choiceID));
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
      title: const Text('Add Collection'),
      content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                onFieldSubmitted: (value) {
                  Navigator.of(context).pop();
                  if (_formKey.currentState!.validate()) {
                    FirebaseFirestore.instance
                        .collection("mycollections")
                        .doc(collectionName.text)
                        .set({});
                  }
                },
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
  @override
  State<addItem> createState() => _addItemState(choiceID: choiceID);
}

class _addItemState extends State<addItem> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController collectionName = TextEditingController();
  _addItemState({Key? key, required this.choiceID});
  final String choiceID;
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add an item to the collection'),
      content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                onFieldSubmitted: (value) {
                  Navigator.of(context).pop();
                  if (_formKey.currentState!.validate()) {
                    FirebaseFirestore.instance
                        .collection("mycollections")
                        .doc(choiceID)
                        .collection("spefCollect")
                        .doc()
                        .set({
                      "Name": collectionName.text,
                      "Descriptors": Map<String, dynamic>(),
                    });
                  }
                },
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
                      "Descriptors": Map<String, dynamic>(),
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

class addField extends StatefulWidget {
  @override
  addField({Key? key, required this.choiceID, required this.docID});
  final String choiceID;
  final String docID;
  State<addField> createState() =>
      _addFieldState(choiceID: choiceID, docID: docID);
}

class _addFieldState extends State<addField> {
  TextEditingController fieldName = TextEditingController();
  TextEditingController fieldContent = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  _addFieldState({Key? key, required this.choiceID, required this.docID});
  final String choiceID;
  final String docID;
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add a field for the item in the collection"),
      content: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                onFieldSubmitted: (value) {
                  Navigator.of(context).pop();
                  if (_formKey.currentState!.validate()) {
                    String wCombo = "Descriptors.${fieldName.text}";
                    FirebaseFirestore.instance
                        .collection("mycollections")
                        .doc(choiceID)
                        .collection("spefCollect")
                        .doc(docID)
                        .update(
                      {wCombo: fieldContent.text},
                      // SetOptions(merge: true),
                    );
                  }
                },
                controller: fieldName,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Field Name',
                ),
              ),
              TextFormField(
                onFieldSubmitted: (value) {
                  Navigator.of(context).pop();
                  if (_formKey.currentState!.validate()) {
                    String wCombo = "Descriptors.${fieldName.text}";
                    FirebaseFirestore.instance
                        .collection("mycollections")
                        .doc(choiceID)
                        .collection("spefCollect")
                        .doc(docID)
                        .update(
                      {wCombo: fieldContent.text},
                      // SetOptions(merge: true),
                    );
                  }
                },
                controller: fieldContent,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Field Content',
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (_formKey.currentState!.validate()) {
                    String wCombo = "Descriptors." + fieldName.text;
                    FirebaseFirestore.instance
                        .collection("mycollections")
                        .doc(choiceID)
                        .collection("spefCollect")
                        .doc(docID)
                        .update(
                      {wCombo: fieldContent.text},
                      // SetOptions(merge: true),
                    );
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          )),
    );
  }
}
