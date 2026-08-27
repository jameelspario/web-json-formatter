import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/cloud_json_model.dart';

abstract class CloudStorageService {
  Future<bool> login(String email, String password);
  Future<bool> signUp(String email, String password);
  Future<void> logout();
  String? getCurrentUserEmail();
  Future<List<CloudJson>> fetchSavedJsons();
  Future<bool> saveJson(String name, String content);
  Future<bool> deleteJson(String id);
  String get modeName;
}

class SimulatedCloudStorageService implements CloudStorageService {
  @override
  String get modeName => "Simulated Sync (Local)";

  static const String _userKey = "cloud_sim_user";
  static const String _docsKeyPrefix = "cloud_sim_docs_";
  static String? _activeEmail;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _activeEmail = prefs.getString(_userKey);
  }

  @override
  String? getCurrentUserEmail() {
    return _activeEmail;
  }

  @override
  Future<bool> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, email);
    _activeEmail = email;
    return true;
  }

  @override
  Future<bool> signUp(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, email);
    _activeEmail = email;
    return true;
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    _activeEmail = null;
  }

  @override
  Future<List<CloudJson>> fetchSavedJsons() async {
    if (_activeEmail == null) return [];
    final prefs = await SharedPreferences.getInstance();
    final key = "$_docsKeyPrefix$_activeEmail";
    final data = prefs.getStringList(key) ?? [];
    return data.map((item) => CloudJson.fromMap(json.decode(item))).toList();
  }

  @override
  Future<bool> saveJson(String name, String content) async {
    if (_activeEmail == null) return false;
    final prefs = await SharedPreferences.getInstance();
    final key = "$_docsKeyPrefix$_activeEmail";
    final data = prefs.getStringList(key) ?? [];
    final list = data.map((item) => CloudJson.fromMap(json.decode(item))).toList();

    if (list.length >= 5) {
      return false; // Limit reached
    }

    final newDoc = CloudJson(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      content: content,
      updatedAt: DateTime.now(),
      size: utf8.encode(content).length,
    );

    list.add(newDoc);
    await prefs.setStringList(key, list.map((item) => json.encode(item.toMap())).toList());
    return true;
  }

  @override
  Future<bool> deleteJson(String id) async {
    if (_activeEmail == null) return false;
    final prefs = await SharedPreferences.getInstance();
    final key = "$_docsKeyPrefix$_activeEmail";
    final data = prefs.getStringList(key) ?? [];
    final list = data.map((item) => CloudJson.fromMap(json.decode(item))).toList();

    list.removeWhere((item) => item.id == id);
    await prefs.setStringList(key, list.map((item) => json.encode(item.toMap())).toList());
    return true;
  }
}

class FirebaseCloudStorageService implements CloudStorageService {
  @override
  String get modeName => "Firebase Firestore";

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }

  @override
  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      print("Firebase login error: $e");
      return false;
    }
  }

  @override
  Future<bool> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      print("Firebase sign up error: $e");
      return false;
    }
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  Future<List<CloudJson>> fetchSavedJsons() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('jsons')
          .orderBy('updatedAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => CloudJson.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print("Firebase fetch error: $e");
      return [];
    }
  }

  @override
  Future<bool> saveJson(String name, String content) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final list = await fetchSavedJsons();
      if (list.length >= 5) {
        return false; // Limit reached
      }
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('jsons')
          .add({
        'name': name,
        'content': content,
        'updatedAt': DateTime.now().toIso8601String(),
        'size': utf8.encode(content).length,
      });
      return true;
    } catch (e) {
      print("Firebase save error: $e");
      return false;
    }
  }

  @override
  Future<bool> deleteJson(String id) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('jsons')
          .doc(id)
          .delete();
      return true;
    } catch (e) {
      print("Firebase delete error: $e");
      return false;
    }
  }
}

class CloudStorageManager {
  static CloudStorageService service = SimulatedCloudStorageService();
  static bool firebaseInitialized = false;

  static Future<void> init() async {
    await SimulatedCloudStorageService.init();
    try {
      if (Firebase.apps.isNotEmpty) {
        service = FirebaseCloudStorageService();
        firebaseInitialized = true;
        return;
      }
      if (kIsWeb) {
        // On web platform, Firebase.initializeApp() requires options parameter.
        // Fallback cleanly to Simulated Cloud Storage without throwing assertion failure.
        service = SimulatedCloudStorageService();
        firebaseInitialized = false;
        return;
      }
      await Firebase.initializeApp();
      service = FirebaseCloudStorageService();
      firebaseInitialized = true;
    } catch (e) {
      service = SimulatedCloudStorageService();
      firebaseInitialized = false;
    }
  }
}
