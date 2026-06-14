class CityData {
  final String nameAr;
  final String nameEn;
  final double lat;
  final double lng;
  const CityData(this.nameAr, this.nameEn, this.lat, this.lng);
}

class CountryData {
  final String nameAr;
  final String flag;
  final List<CityData> cities;
  const CountryData(this.nameAr, this.flag, this.cities);
}

const List<CountryData> kWorldCities = [
  CountryData("مصر", "🇪🇬", [
    CityData("القاهرة", "Cairo", 30.0444, 31.2357),
    CityData("الإسكندرية", "Alexandria", 31.2001, 29.9187),
    CityData("الجيزة", "Giza", 30.0131, 31.2089),
    CityData("المنصورة", "Mansoura", 31.0409, 31.3785),
    CityData("طنطا", "Tanta", 30.7865, 31.0004),
    CityData("أسيوط", "Asyut", 27.1783, 31.1859),
    CityData("المنيا", "Minya", 28.0991, 30.7500),
    CityData("سوهاج", "Sohag", 26.5591, 31.6957),
    CityData("الأقصر", "Luxor", 25.6872, 32.6396),
    CityData("أسوان", "Aswan", 24.0889, 32.8998),
    CityData("بورسعيد", "Port Said", 31.2653, 32.3019),
    CityData("الإسماعيلية", "Ismailia", 30.5965, 32.2715),
    CityData("السويس", "Suez", 29.9668, 32.5498),
    CityData("دمياط", "Damietta", 31.4165, 31.8133),
    CityData("الزقازيق", "Zagazig", 30.5877, 31.5021),
    CityData("شبين الكوم", "Shibin El Kom", 30.5500, 31.0100),
    CityData("كفر الشيخ", "Kafr El Sheikh", 31.1107, 30.9388),
    CityData("بنها", "Banha", 30.4626, 31.1853),
    CityData("سنبلاوين", "Sinbillawin", 30.8908, 31.4668),
    CityData("المحلة الكبرى", "Mahalla El Kubra", 30.9769, 31.1628),
  ]),
  CountryData("السعودية", "🇸🇦", [
    CityData("الرياض", "Riyadh", 24.7136, 46.6753),
    CityData("جدة", "Jeddah", 21.5433, 39.1728),
    CityData("مكة المكرمة", "Mecca", 21.3891, 39.8579),
    CityData("المدينة المنورة", "Medina", 24.5247, 39.5692),
    CityData("الدمام", "Dammam", 26.4207, 50.0888),
    CityData("الطائف", "Taif", 21.2854, 40.4149),
    CityData("تبوك", "Tabuk", 28.3998, 36.5715),
    CityData("أبها", "Abha", 18.2164, 42.5053),
  ]),
  CountryData("الإمارات", "🇦🇪", [
    CityData("دبي", "Dubai", 25.2048, 55.2708),
    CityData("أبوظبي", "Abu Dhabi", 24.4539, 54.3773),
    CityData("الشارقة", "Sharjah", 25.3463, 55.4209),
    CityData("عجمان", "Ajman", 25.4052, 55.5136),
    CityData("رأس الخيمة", "Ras Al Khaimah", 25.7895, 55.9432),
    CityData("الفجيرة", "Fujairah", 25.1288, 56.3265),
  ]),
  CountryData("الكويت", "🇰🇼", [
    CityData("الكويت", "Kuwait City", 29.3759, 47.9774),
    CityData("حولي", "Hawalli", 29.3323, 48.0293),
    CityData("الأحمدي", "Ahmadi", 29.0769, 48.0838),
  ]),
  CountryData("قطر", "🇶🇦", [
    CityData("الدوحة", "Doha", 25.2854, 51.5310),
    CityData("الريان", "Al Rayyan", 25.2922, 51.4247),
    CityData("الوكرة", "Al Wakrah", 25.1666, 51.6025),
  ]),
  CountryData("البحرين", "🇧🇭", [
    CityData("المنامة", "Manama", 26.2154, 50.5832),
    CityData("المحرق", "Muharraq", 26.2577, 50.6120),
    CityData("الرفاع", "Riffa", 26.1297, 50.5550),
  ]),
  CountryData("عُمان", "🇴🇲", [
    CityData("مسقط", "Muscat", 23.6086, 58.5922),
    CityData("صلالة", "Salalah", 17.0151, 54.0924),
    CityData("صحار", "Sohar", 24.3647, 56.7450),
    CityData("نزوى", "Nizwa", 22.9333, 57.5333),
  ]),
  CountryData("اليمن", "🇾🇪", [
    CityData("صنعاء", "Sanaa", 15.3694, 44.1910),
    CityData("عدن", "Aden", 12.7797, 45.0095),
    CityData("تعز", "Taiz", 13.5789, 44.0209),
    CityData("الحديدة", "Hodeidah", 14.7978, 42.9450),
  ]),
  CountryData("العراق", "🇮🇶", [
    CityData("بغداد", "Baghdad", 33.3152, 44.3661),
    CityData("البصرة", "Basra", 30.5085, 47.7835),
    CityData("الموصل", "Mosul", 36.3350, 43.1189),
    CityData("أربيل", "Erbil", 36.1912, 44.0092),
    CityData("النجف", "Najaf", 31.9980, 44.3350),
    CityData("كركوك", "Kirkuk", 35.4681, 44.3922),
  ]),
  CountryData("سوريا", "🇸🇾", [
    CityData("دمشق", "Damascus", 33.5138, 36.2765),
    CityData("حلب", "Aleppo", 36.2021, 37.1343),
    CityData("حمص", "Homs", 34.7324, 36.7137),
    CityData("اللاذقية", "Latakia", 35.5310, 35.7910),
  ]),
  CountryData("لبنان", "🇱🇧", [
    CityData("بيروت", "Beirut", 33.8938, 35.5018),
    CityData("طرابلس", "Tripoli", 34.4367, 35.8497),
    CityData("صيدا", "Sidon", 33.5633, 35.3706),
  ]),
  CountryData("الأردن", "🇯🇴", [
    CityData("عمان", "Amman", 31.9539, 35.9106),
    CityData("الزرقاء", "Zarqa", 32.0728, 36.0880),
    CityData("إربد", "Irbid", 32.5556, 35.8500),
    CityData("العقبة", "Aqaba", 29.5267, 35.0068),
  ]),
  CountryData("فلسطين", "🇵🇸", [
    CityData("غزة", "Gaza", 31.5017, 34.4668),
    CityData("رام الله", "Ramallah", 31.9038, 35.2034),
    CityData("الخليل", "Hebron", 31.5326, 35.0998),
    CityData("نابلس", "Nablus", 32.2211, 35.2544),
    CityData("القدس", "Jerusalem", 31.7683, 35.2137),
  ]),
  CountryData("ليبيا", "🇱🇾", [
    CityData("طرابلس", "Tripoli", 32.9025, 13.1806),
    CityData("بنغازي", "Benghazi", 32.1194, 20.0868),
    CityData("مصراتة", "Misrata", 32.3754, 15.0925),
  ]),
  CountryData("تونس", "🇹🇳", [
    CityData("تونس", "Tunis", 36.8065, 10.1815),
    CityData("صفاقس", "Sfax", 34.7406, 10.7603),
    CityData("سوسة", "Sousse", 35.8256, 10.6084),
  ]),
  CountryData("الجزائر", "🇩🇿", [
    CityData("الجزائر", "Algiers", 36.7372, 3.0865),
    CityData("وهران", "Oran", 35.6969, -0.6331),
    CityData("قسنطينة", "Constantine", 36.3650, 6.6147),
    CityData("عنابة", "Annaba", 36.9000, 7.7667),
  ]),
  CountryData("المغرب", "🇲🇦", [
    CityData("الرباط", "Rabat", 34.0209, -6.8416),
    CityData("الدار البيضاء", "Casablanca", 33.5731, -7.5898),
    CityData("مراكش", "Marrakech", 31.6295, -7.9811),
    CityData("فاس", "Fes", 34.0181, -5.0078),
    CityData("طنجة", "Tangier", 35.7595, -5.8340),
  ]),
  CountryData("موريتانيا", "🇲🇷", [
    CityData("نواكشوط", "Nouakchott", 18.0858, -15.9785),
    CityData("نواذيبو", "Nouadhibou", 20.9310, -17.0347),
  ]),
  CountryData("السودان", "🇸🇩", [
    CityData("الخرطوم", "Khartoum", 15.5007, 32.5599),
    CityData("أم درمان", "Omdurman", 15.6445, 32.4777),
    CityData("بورتسودان", "Port Sudan", 19.6158, 37.2164),
  ]),
  CountryData("الصومال", "🇸🇴", [
    CityData("مقديشو", "Mogadishu", 2.0469, 45.3182),
    CityData("هرجيسا", "Hargeisa", 9.5600, 44.0650),
  ]),
  CountryData("جيبوتي", "🇩🇯", [
    CityData("جيبوتي", "Djibouti", 11.8251, 42.5903),
  ]),
  CountryData("إريتريا", "🇪🇷", [
    CityData("أسمرة", "Asmara", 15.3381, 38.9316),
  ]),
  CountryData("تشاد", "🇹🇩", [
    CityData("نجامينا", "N'Djamena", 12.1048, 15.0445),
  ]),
  CountryData("النيجر", "🇳🇪", [
    CityData("نيامي", "Niamey", 13.5137, 2.1098),
  ]),
  CountryData("مالي", "🇲🇱", [
    CityData("باماكو", "Bamako", 12.6392, -8.0029),
    CityData("تمبكتو", "Timbuktu", 16.7666, -3.0026),
  ]),
  CountryData("السنغال", "🇸🇳", [
    CityData("داكار", "Dakar", 14.7167, -17.4677),
  ]),
  CountryData("غينيا", "🇬🇳", [
    CityData("كوناكري", "Conakry", 9.6412, -13.5784),
  ]),
  CountryData("نيجيريا", "🇳🇬", [
    CityData("لاغوس", "Lagos", 6.5244, 3.3792),
    CityData("كانو", "Kano", 12.0022, 8.5920),
    CityData("أبوجا", "Abuja", 9.0579, 7.4951),
    CityData("إبادان", "Ibadan", 7.3775, 3.9470),
  ]),
  CountryData("كينيا", "🇰🇪", [
    CityData("نيروبي", "Nairobi", -1.2921, 36.8219),
    CityData("مومباسا", "Mombasa", -4.0435, 39.6682),
  ]),
  CountryData("تنزانيا", "🇹🇿", [
    CityData("دار السلام", "Dar es Salaam", -6.7924, 39.2083),
    CityData("دودوما", "Dodoma", -6.1722, 35.7395),
    CityData("زنجبار", "Zanzibar", -6.1659, 39.1999),
  ]),
  CountryData("أوغندا", "🇺🇬", [
    CityData("كمبالا", "Kampala", 0.3476, 32.5825),
  ]),
  CountryData("إثيوبيا", "🇪🇹", [
    CityData("أديس أبابا", "Addis Ababa", 9.0320, 38.7469),
    CityData("دير داوا", "Dire Dawa", 9.6000, 41.8500),
  ]),
  CountryData("موزمبيق", "🇲🇿", [
    CityData("مابوتو", "Maputo", -25.9692, 32.5732),
  ]),
  CountryData("مدغشقر", "🇲🇬", [
    CityData("أنتاناناريفو", "Antananarivo", -18.9137, 47.5361),
  ]),
  CountryData("تركيا", "🇹🇷", [
    CityData("إسطنبول", "Istanbul", 41.0082, 28.9784),
    CityData("أنقرة", "Ankara", 39.9334, 32.8597),
    CityData("إزمير", "Izmir", 38.4192, 27.1287),
    CityData("بورصة", "Bursa", 40.1826, 29.0665),
    CityData("أنطاليا", "Antalya", 36.8969, 30.7133),
    CityData("أضنة", "Adana", 37.0000, 35.3213),
    CityData("طرابزون", "Trabzon", 41.0015, 39.7178),
  ]),
  CountryData("إيران", "🇮🇷", [
    CityData("طهران", "Tehran", 35.6892, 51.3890),
    CityData("مشهد", "Mashhad", 36.2605, 59.6168),
    CityData("أصفهان", "Isfahan", 32.6539, 51.6660),
    CityData("شيراز", "Shiraz", 29.5918, 52.5837),
    CityData("تبريز", "Tabriz", 38.0800, 46.2919),
  ]),
  CountryData("باكستان", "🇵🇰", [
    CityData("كراتشي", "Karachi", 24.8607, 67.0011),
    CityData("لاهور", "Lahore", 31.5497, 74.3436),
    CityData("إسلام آباد", "Islamabad", 33.7215, 73.0433),
    CityData("فيصل آباد", "Faisalabad", 31.4154, 73.0886),
    CityData("راولبندي", "Rawalpindi", 33.5651, 73.0169),
    CityData("بيشاور", "Peshawar", 34.0151, 71.5249),
    CityData("كويتة", "Quetta", 30.1798, 66.9750),
  ]),
  CountryData("إندونيسيا", "🇮🇩", [
    CityData("جاكرتا", "Jakarta", -6.2088, 106.8456),
    CityData("سورابايا", "Surabaya", -7.2575, 112.7521),
    CityData("باندونغ", "Bandung", -6.9175, 107.6191),
    CityData("ميدان", "Medan", 3.5952, 98.6722),
  ]),
  CountryData("ماليزيا", "🇲🇾", [
    CityData("كوالالمبور", "Kuala Lumpur", 3.1390, 101.6869),
    CityData("جورج تاون", "George Town", 5.4141, 100.3288),
    CityData("جوهور بهرو", "Johor Bahru", 1.4927, 103.7414),
  ]),
  CountryData("الهند", "🇮🇳", [
    CityData("نيودلهي", "New Delhi", 28.6139, 77.2090),
    CityData("مومباي", "Mumbai", 19.0760, 72.8777),
    CityData("بنغالور", "Bangalore", 12.9716, 77.5946),
  ]),
  CountryData("الصين", "🇨🇳", [
    CityData("بكين", "Beijing", 39.9042, 116.4074),
    CityData("شنغهاي", "Shanghai", 31.2304, 121.4737),
    CityData("أورومتشي", "Urumqi", 43.8256, 87.6168),
  ]),
  CountryData("المملكة المتحدة", "🇬🇧", [
    CityData("لندن", "London", 51.5074, -0.1278),
    CityData("برمنغهام", "Birmingham", 52.4862, -1.8904),
    CityData("مانشستر", "Manchester", 53.4808, -2.2426),
  ]),
  CountryData("فرنسا", "🇫🇷", [
    CityData("باريس", "Paris", 48.8566, 2.3522),
    CityData("مرسيليا", "Marseille", 43.2965, 5.3698),
  ]),
  CountryData("ألمانيا", "🇩🇪", [
    CityData("برلين", "Berlin", 52.5200, 13.4050),
    CityData("هامبورغ", "Hamburg", 53.5753, 10.0153),
    CityData("ميونيخ", "Munich", 48.1351, 11.5820),
  ]),
  CountryData("إسبانيا", "🇪🇸", [
    CityData("مدريد", "Madrid", 40.4168, -3.7038),
    CityData("برشلونة", "Barcelona", 41.3851, 2.1734),
  ]),
  CountryData("إيطاليا", "🇮🇹", [
    CityData("روما", "Rome", 41.9028, 12.4964),
    CityData("ميلان", "Milan", 45.4642, 9.1900),
  ]),
  CountryData("كندا", "🇨🇦", [
    CityData("تورنتو", "Toronto", 43.6532, -79.3832),
    CityData("مونتريال", "Montreal", 45.5017, -73.5673),
    CityData("فانكوفر", "Vancouver", 49.2827, -123.1207),
  ]),
  CountryData("الولايات المتحدة", "🇺🇸", [
    CityData("نيويورك", "New York", 40.7128, -74.0060),
    CityData("لوس أنجلوس", "Los Angeles", 34.0522, -118.2437),
    CityData("شيكاغو", "Chicago", 41.8781, -87.6298),
    CityData("واشنطن", "Washington DC", 38.9072, -77.0369),
    CityData("ديربورن", "Dearborn", 42.3223, -83.1763),
  ]),
  CountryData("أستراليا", "🇦🇺", [
    CityData("سيدني", "Sydney", -33.8688, 151.2093),
    CityData("ملبورن", "Melbourne", -37.8136, 144.9631),
  ]),
];
