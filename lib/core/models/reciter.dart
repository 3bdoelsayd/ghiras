import 'package:azlistview/azlistview.dart';
import 'moshaf.dart';

class Reciter extends ISuspensionBean {
  dynamic id;
  dynamic name;
  dynamic letter;
  final List<Moshaf> moshaf;

  Reciter({
    required this.id,
    required this.name,
    required this.letter,
    required this.moshaf,
  });

  factory Reciter.fromJson(Map<String, dynamic> json) {
    return Reciter(
      id: json['id'],
      name: json['name'],
      letter: json['letter'],
      moshaf: (json['moshaf'] as List<dynamic>)
          .map((moshaf) => Moshaf.fromJson(moshaf))
          .toList(),
    );
  }

  // Override == operator to compare Reciter objects by id
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reciter && runtimeType == other.runtimeType && id == other.id;

  // Override hashCode to use the id property for hashing
  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'letter': letter,
      'moshaf': moshaf.map((moshaf) => moshaf.toJson()).toList(),
    };
  }

  @override
  String getSuspensionTag() {
    return letter?.toString() ?? "";
  }
}
