import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    User? user = FirebaseAuth.instance.currentUser;
    return MaterialApp(
      title: 'MyCollect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Palette.newTheme,
      ),
      home: LoginPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title, required this.user});
  final String title;
  User? user = FirebaseAuth.instance.currentUser;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  User? user = FirebaseAuth.instance.currentUser;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.title),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("Users")
              .doc(user?.uid)
              .collection("collections")
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
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: FloatingActionButton(
              heroTag: "Signout",
              onPressed: () {
                print("Here");
                FirebaseAuth.instance.signOut();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              tooltip: 'Sign Out',
              child: const Icon(Icons.logout, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: FloatingActionButton(
              heroTag: "createCollection",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => addCollection()),
                );
              },
              tooltip: 'Add Collection',
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
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
            Center(child: Text(document["Name"])),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FloatingActionButton.small(
                  heroTag: document.id,
                  child: const Icon(Icons.delete, color: Colors.white),
                  onPressed: () {
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
  User? user = FirebaseAuth.instance.currentUser;

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
                      .collection("Users")
                      .doc(user?.uid)
                      .collection("collections")
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
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: FloatingActionButton.small(
                          heroTag: "itemDeletion",
                          child: const Icon(Icons.delete, color: Colors.white),
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
  User? user = FirebaseAuth.instance.currentUser;
  return fireStoreReference
      .collection("Users")
      .doc(user?.uid)
      .collection("collections")
      .doc(choiceID)
      .collection("spefCollect")
      .doc(docID)
      .delete();
}

Future delCollection(String docID) {
  final fireStoreReference = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;
  return fireStoreReference.runTransaction((transaction) async =>
      transaction.delete(fireStoreReference
          .collection("Users")
          .doc(user?.uid)
          .collection("collections")
          .doc(docID)));
}

// Future delCollectionAdd(String choiceID) {
//   final fireStoreReference = FirebaseFirestore.instance;
//   return fireStoreReference
//       .collection("mycollections")
//       .doc(choiceID)
//       .collection("spefCollect")
//       .doc() /* Add code that refrences every document in the collection */
//       .delete();
// }

Widget youSure(
    BuildContext context, DocumentSnapshot document, String choiceID) {
  return AlertDialog(
      title: Text("Are you sure you want to delete $choiceID"),
      content: ElevatedButton(
        onPressed: () {
          delCollection(document.id);
          // delCollectionAdd(document.id);
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
          color: Color(0xff56805C),
          size: 50.0,
        ),
      ),
    );
  }
}

// showDisplayName(String choiceID) async {
//   var collection = FirebaseFirestore.instance.collection('users');
//   //userUid is the current auth user
//   var docSnapshot = await collection.doc(choiceID).get();

//   Map<String, dynamic> data = docSnapshot.data()!;

//   return data['Name'].text;
// }

// class Database {
//   Database({Key? key, required this.choiceID});
//   final String choiceID;
//   static String? userName;
//   static User? user = FirebaseAuth.instance.currentUser;

//   static void showDisplayName() async {
//     var collection = FirebaseFirestore.instance
//         .collection("Users")
//         .doc(user?.uid)
//         .collection("collections");
//     var docSnapshot = await collection.doc(choiceID).get();

//     Map<String, dynamic> data = docSnapshot.data()!;

//     userName = data['displayName'];
//   }
// }

class collectionPage extends StatelessWidget {
  collectionPage({Key? key, required this.choiceID});
  final String choiceID;
  User? user = FirebaseAuth.instance.currentUser;
  @override
  Widget build(BuildContext context) {
    final double widthScreen = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(choiceID),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("Users")
              .doc(user?.uid)
              .collection("collections")
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
        child: const Icon(Icons.add, color: Colors.white),
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
  User? user = FirebaseAuth.instance.currentUser;
  TextEditingController collectionName = TextEditingController();
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Collection'),
      content: Stack(children: <Widget>[
        Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  onFieldSubmitted: (value) {
                    Navigator.of(context).pop();
                    if (_formKey.currentState!.validate()) {
                      FirebaseFirestore.instance
                          .collection("Users")
                          .doc(user?.uid)
                          .collection("collections")
                          .doc(collectionName.text)
                          .set({"Name": collectionName.text});
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
                          .collection("Users")
                          .doc(user?.uid)
                          .collection("collections")
                          .doc(collectionName.text)
                          .set({"Name": collectionName.text});
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            )),
        Positioned(
          right: 0.0,
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Align(
              alignment: Alignment.topRight,
              child: CircleAvatar(
                radius: 14.0,
                backgroundColor: Colors.white,
                child: Icon(Icons.close, color: Colors.red),
              ),
            ),
          ),
        ),
      ]),
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
  User? user = FirebaseAuth.instance.currentUser;
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
                        .collection("Users")
                        .doc(user?.uid)
                        .collection("collections")
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
                        .collection("Users")
                        .doc(user?.uid)
                        .collection("collections")
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
  User? user = FirebaseAuth.instance.currentUser;
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
                        .collection("Users")
                        .doc(user?.uid)
                        .collection("collections")
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
                        .collection("Users")
                        .doc(user?.uid)
                        .collection("collections")
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
                        .collection("Users")
                        .doc(user?.uid)
                        .collection("collections")
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

class Palette {
  static const MaterialColor newTheme = MaterialColor(
    0xff56805C, // 0% comes in here, this will be color picked if no shade is selected when defining a Color property which doesn’t require a swatch.
    <int, Color>{
      50: Color(0xff56805C), //10%
      100: Color(0xff56805C), //20%
      200: Color(0xff56805C), //30%
      300: Color(0xff56805C), //40%
      400: Color(0xff56805C), //50%
      500: Color(0xff56805C), //60%
      600: Color(0xff56805C), //70%
      700: Color(0xffccd9ce), //80%
      800: Color(0xffdde6de), //90%
      900: Color(0xffeef2ef), //100%
    },
  );
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailTextController = TextEditingController();
  final _passwordTextController = TextEditingController();

  final _focusEmail = FocusNode();
  final _focusPassword = FocusNode();

  bool _isProcessing = false;

  Future<FirebaseApp> _initializeFirebase() async {
    FirebaseApp firebaseApp = await Firebase.initializeApp();

    User? user = FirebaseAuth.instance.currentUser;

    return firebaseApp;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _focusEmail.unfocus();
        _focusPassword.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(''),
        ),
        body: FutureBuilder(
          future: _initializeFirebase(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Padding(
                padding: const EdgeInsets.only(left: 24.0, right: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Text(
                        'Login',
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                    ),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          TextFormField(
                            controller: _emailTextController,
                            focusNode: _focusEmail,
                            validator: (value) => Validator.validateEmail(
                              email: value!,
                            ),
                            decoration: InputDecoration(
                              hintText: "Email",
                              errorBorder: UnderlineInputBorder(
                                borderRadius: BorderRadius.circular(6.0),
                                borderSide: BorderSide(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8.0),
                          TextFormField(
                            controller: _passwordTextController,
                            focusNode: _focusPassword,
                            obscureText: true,
                            validator: (value) => Validator.validatePassword(
                              password: value!,
                            ),
                            decoration: InputDecoration(
                              hintText: "Password",
                              errorBorder: UnderlineInputBorder(
                                borderRadius: BorderRadius.circular(6.0),
                                borderSide: BorderSide(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 24.0),
                          _isProcessing
                              ? CircularProgressIndicator()
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          _focusEmail.unfocus();
                                          _focusPassword.unfocus();

                                          if (_formKey.currentState!
                                              .validate()) {
                                            setState(() {
                                              _isProcessing = true;
                                            });

                                            User? user = await FireAuth
                                                .signInUsingEmailPassword(
                                              email: _emailTextController.text,
                                              password:
                                                  _passwordTextController.text,
                                              context: context,
                                            );

                                            setState(() {
                                              _isProcessing = false;
                                            });

                                            if (user != null) {
                                              Navigator.of(context)
                                                  .pushReplacement(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      MyHomePage(
                                                          title: "Home page",
                                                          user: user),
                                                ),
                                              );
                                            } else {
                                              Navigator.of(context)
                                                  .pushReplacement(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: const Text('Error'),
                                                    content:
                                                        SingleChildScrollView(
                                                      child: ListBody(
                                                        children: const <
                                                            Widget>[
                                                          Text(
                                                              'You have entered the wrong password'),
                                                        ],
                                                      ),
                                                    ),
                                                    actions: <Widget>[
                                                      TextButton(
                                                        child: const Text(
                                                            'Aknowledge'),
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pushReplacement(
                                                            MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        LoginPage()),
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        child: const Text(
                                          'Sign In',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 24.0),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  RegisterPage(),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'Register',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                        ],
                      ),
                    )
                  ],
                ),
              );
            }

            return Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }
}

class FireAuth {
  static Future<User?> registerUsingEmailPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user;
    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = userCredential.user;
      await user!.updateDisplayName(name);
      await user.reload();
      user = auth.currentUser;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
    } catch (e) {
      print(e);
    }
    return user;
  }

  static Future<User?> signInUsingEmailPassword({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user;

    try {
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided.');
      }
    }

    return user;
  }
}

class Validator {
  static String? validateName({required String name}) {
    if (name == null) {
      return null;
    }
    if (name.isEmpty) {
      return 'Name can\'t be empty';
    }

    return null;
  }

  static String? validateEmail({required String email}) {
    if (email == null) {
      return null;
    }
    RegExp emailRegExp = RegExp(
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$");

    if (email.isEmpty) {
      return 'Email can\'t be empty';
    } else if (!emailRegExp.hasMatch(email)) {
      return 'Enter a correct email';
    }

    return null;
  }

  static String? validatePassword({required String password}) {
    if (password == null) {
      return null;
    }
    if (password.isEmpty) {
      return 'Password can\'t be empty';
    } else if (password.length < 6) {
      return 'Enter a password with length at least 6';
    }

    return null;
  }
}

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _registerFormKey = GlobalKey<FormState>();

  final _nameTextController = TextEditingController();
  final _emailTextController = TextEditingController();
  final _passwordTextController = TextEditingController();

  final _focusName = FocusNode();
  final _focusEmail = FocusNode();
  final _focusPassword = FocusNode();

  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _focusName.unfocus();
        _focusEmail.unfocus();
        _focusPassword.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Register'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Form(
                  key: _registerFormKey,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        controller: _nameTextController,
                        focusNode: _focusName,
                        validator: (value) => Validator.validateName(
                          name: value!,
                        ),
                        decoration: InputDecoration(
                          hintText: "Name",
                          errorBorder: UnderlineInputBorder(
                            borderRadius: BorderRadius.circular(6.0),
                            borderSide: BorderSide(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.0),
                      TextFormField(
                        controller: _emailTextController,
                        focusNode: _focusEmail,
                        validator: (value) => Validator.validateEmail(
                          email: value!,
                        ),
                        decoration: InputDecoration(
                          hintText: "Email",
                          errorBorder: UnderlineInputBorder(
                            borderRadius: BorderRadius.circular(6.0),
                            borderSide: BorderSide(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.0),
                      TextFormField(
                        controller: _passwordTextController,
                        focusNode: _focusPassword,
                        obscureText: true,
                        validator: (value) => Validator.validatePassword(
                          password: value!,
                        ),
                        decoration: InputDecoration(
                          hintText: "Password",
                          errorBorder: UnderlineInputBorder(
                            borderRadius: BorderRadius.circular(6.0),
                            borderSide: const BorderSide(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 32.0),
                      _isProcessing
                          ? CircularProgressIndicator()
                          : Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      setState(() {
                                        _isProcessing = true;
                                      });

                                      if (_registerFormKey.currentState!
                                          .validate()) {
                                        User? user = await FireAuth
                                            .registerUsingEmailPassword(
                                          name: _nameTextController.text,
                                          email: _emailTextController.text,
                                          password:
                                              _passwordTextController.text,
                                        );

                                        FirebaseFirestore.instance
                                            .collection("Users")
                                            .doc(user?.uid)
                                            .collection("collections")
                                            .doc("Example Collection")
                                            .set({
                                          "Name": "Example Collection!"
                                        });

                                        setState(() {
                                          _isProcessing = false;
                                        });

                                        if (user != null) {
                                          Navigator.of(context)
                                              .pushAndRemoveUntil(
                                            MaterialPageRoute(
                                              builder: (context) => MyHomePage(
                                                  title: "Home Page",
                                                  user: user),
                                            ),
                                            ModalRoute.withName('/'),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text(
                                      'Sign up',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
