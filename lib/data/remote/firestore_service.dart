import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference collection(String path) => _db.collection(path);

  static DocumentReference doc(String path) => _db.doc(path);
}
