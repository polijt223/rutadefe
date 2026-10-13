class Friend {
  final String uid;
  final String displayName;
  final String? photoUrl;

  Friend({required this.uid, required this.displayName, this.photoUrl});

  factory Friend.fromMap(String uid, Map<String, dynamic> map) {
    return Friend(
      uid: uid,
      displayName: map['displayName'] ?? 'Usuario',
      photoUrl: map['photoUrl'],
    );
  }
}
