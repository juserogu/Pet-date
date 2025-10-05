import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ProfileViewModel with ChangeNotifier {
  final String uid;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  bool _loading = false;
  bool _uploading = false;
  String? _photoUrl;
  Map<String, dynamic> _data = {};
  List<String> _photoUrls = [];

  bool get isLoading => _loading;
  bool get isUploading => _uploading;
  String? get photoUrl => _photoUrl;
  Map<String, dynamic> get data => _data;
  List<String> get photoUrls => List.unmodifiable(_photoUrls);

  ProfileViewModel({
    required this.uid,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        storage = storage ?? FirebaseStorage.instance;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    final doc = await firestore.collection('users').doc(uid).get();
    _data = doc.data() ?? {};
    _photoUrl = (_data['photoUrl'] as String?)?.trim();
    if (_photoUrl != null && _photoUrl!.isEmpty) {
      _photoUrl = null;
    }
    final rawPhotos = _data['photoUrls'];
    if (rawPhotos is List) {
      _photoUrls = rawPhotos.whereType<String>().toList();
    } else if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      _photoUrls = [_photoUrl!];
    } else {
      _photoUrls = [];
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> save(Map<String, dynamic> patch,
      {bool showLoading = true}) async {
    if (showLoading) {
      _loading = true;
      notifyListeners();
    }
    await firestore
        .collection('users')
        .doc(uid)
        .set(patch, SetOptions(merge: true));
    _data.addAll(patch);
    _photoUrl = (_data['photoUrl'] as String?)?.trim();
    if (_photoUrl != null && _photoUrl!.isEmpty) {
      _photoUrl = null;
    }
    final rawPhotos = _data['photoUrls'];
    if (rawPhotos is List) {
      _photoUrls = rawPhotos.whereType<String>().toList();
    }
    if (showLoading) {
      _loading = false;
    }
    notifyListeners();
  }

  Future<String?> uploadPhoto(File file) async {
    _uploading = true;
    notifyListeners();
    try {
      final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = storage.ref().child('users').child(uid).child(filename);
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      _photoUrls = [..._photoUrls, url];
      if (_photoUrls.isNotEmpty && (_photoUrl == null || _photoUrl!.isEmpty)) {
        _photoUrl = _photoUrls.first;
      }
      await save({
        'photoUrls': _photoUrls,
        'photoUrl': _photoUrls.isNotEmpty ? _photoUrls.first : '',
      }, showLoading: false);
      return url;
    } finally {
      _uploading = false;
      notifyListeners();
    }
  }

  Future<void> removePhoto(String url) async {
    if (!_photoUrls.contains(url)) return;
    _photoUrls = _photoUrls.where((element) => element != url).toList();
    _photoUrl = _photoUrls.isNotEmpty ? _photoUrls.first : null;
    notifyListeners();
    await save({
      'photoUrls': _photoUrls,
      'photoUrl': _photoUrl ?? '',
    }, showLoading: false);
    try {
      await storage.refFromURL(url).delete();
    } catch (_) {
      // Ignore delete errors
    }
  }

  Future<void> setPrimaryPhoto(String url) async {
    if (!_photoUrls.contains(url)) return;
    if (_photoUrls.isEmpty || _photoUrls.first == url) return;
    _photoUrls = [
      url,
      ..._photoUrls.where((element) => element != url),
    ];
    _photoUrl = _photoUrls.first;
    notifyListeners();
    await save({
      'photoUrls': _photoUrls,
      'photoUrl': _photoUrl ?? '',
    }, showLoading: false);
  }

  Future<void> reorderPhotos(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _photoUrls.length) return;
    if (newIndex < 0 || newIndex > _photoUrls.length) return;
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;
    final updated = List<String>.from(_photoUrls);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    _photoUrls = updated;
    _photoUrl = _photoUrls.isNotEmpty ? _photoUrls.first : null;
    notifyListeners();
    await save({
      'photoUrls': _photoUrls,
      'photoUrl': _photoUrl ?? '',
    }, showLoading: false);
  }
}
