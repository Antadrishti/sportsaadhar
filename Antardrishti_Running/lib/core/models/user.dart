class User {
  final String id;
  final String name;
  final String aadhaarNumber;
  final int age;
  final double height; // in cm
  final double weight; // in kg
  final String gender; // Male, Female, Other
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String disability; // None, Visual, Hearing, Locomotor, Intellectual, Multiple
  final String phoneNumber; // Mandatory
  final String? email; // Optional
  final String? profileImageUrl;
  final String token; // JWT

  User({
    required this.id,
    required this.name,
    required this.aadhaarNumber,
    required this.age,
    required this.height,
    required this.weight,
    required this.gender,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.disability,
    required this.phoneNumber,
    this.email,
    this.profileImageUrl,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['_id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      aadhaarNumber: (json['aadhaarNumber'] ?? '') as String,
      age: (json['age'] ?? 0) as int,
      height: (json['height'] is int) 
          ? (json['height'] as int).toDouble() 
          : (json['height'] ?? 0.0) as double,
      weight: (json['weight'] is int) 
          ? (json['weight'] as int).toDouble() 
          : (json['weight'] ?? 0.0) as double,
      gender: (json['gender'] ?? 'Other') as String,
      address: (json['address'] ?? '') as String,
      city: (json['city'] ?? '') as String,
      state: (json['state'] ?? '') as String,
      pincode: (json['pincode'] ?? '') as String,
      disability: (json['disability'] ?? 'None') as String,
      phoneNumber: (json['phoneNumber'] ?? '') as String,
      email: json['email'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      token: (json['token'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'aadhaarNumber': aadhaarNumber,
        'age': age,
        'height': height,
        'weight': weight,
        'gender': gender,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'disability': disability,
        'phoneNumber': phoneNumber,
        if (email != null) 'email': email,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        'token': token,
      };
}
