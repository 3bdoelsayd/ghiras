class Moshaf {
  dynamic id;
  dynamic name;
  dynamic server;
  dynamic surahTotal;
  dynamic moshafType;
  dynamic surahList;

  Moshaf({
    required this.id,
    required this.name,
    required this.server,
    required this.surahTotal,
    required this.moshafType,
    required this.surahList,
  });

  factory Moshaf.fromJson(Map<String, dynamic> json) {
    return Moshaf(
      id: json['id'],
      name: json['name'],
      server: json['server'],
      surahTotal: json['surah_total'],
      moshafType: json['moshaf_type'],
      surahList: json['surah_list'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'server': server,
      'surah_total': surahTotal,
      'moshaf_type': moshafType,
      'surah_list': surahList,
    };
  }
}
