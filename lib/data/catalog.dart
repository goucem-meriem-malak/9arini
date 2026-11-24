import 'package:flutter/material.dart';

const levelIds = ['p1', 'p2', 'p3', 'p4', 'p5', 'm1', 'm2', 'm3', 'm4', 's1', 's2', 's3', 'bac', 'uni', 'adult'];
const subjectIds = ['math', 'physics', 'science', 'arabic', 'french', 'english', 'history', 'islamic', 'philosophy', 'info', 'econ', 'prog', 'other'];
const modeIds = ['in_person', 'online', 'both'];
const reactionKeys = ['like', 'love', 'clap', 'think'];
const reactionEmoji = {'like': '👍', 'love': '❤', 'clap': '👏', 'think': '🤔'};

IconData subjectIcon(String id) => switch (id) {
      'math' => Icons.calculate_rounded,
      'physics' => Icons.bolt_rounded,
      'science' => Icons.science_rounded,
      'arabic' => Icons.menu_book_rounded,
      'french' => Icons.translate_rounded,
      'english' => Icons.language_rounded,
      'history' => Icons.public_rounded,
      'islamic' => Icons.auto_stories_rounded,
      'philosophy' => Icons.psychology_rounded,
      'info' => Icons.computer_rounded,
      'econ' => Icons.trending_up_rounded,
      'prog' => Icons.code_rounded,
      _ => Icons.school_rounded,
    };

/// (code, French name, Arabic name) for the 58 wilayas.
const wilayas = <(String, String, String)>[
  ('1', 'Adrar', 'أدرار'), ('2', 'Chlef', 'الشلف'), ('3', 'Laghouat', 'الأغواط'), ('4', 'Oum El Bouaghi', 'أم البواقي'),
  ('5', 'Batna', 'باتنة'), ('6', 'Béjaïa', 'بجاية'), ('7', 'Biskra', 'بسكرة'), ('8', 'Béchar', 'بشار'),
  ('9', 'Blida', 'البليدة'), ('10', 'Bouira', 'البويرة'), ('11', 'Tamanrasset', 'تمنراست'), ('12', 'Tébessa', 'تبسة'),
  ('13', 'Tlemcen', 'تلمسان'), ('14', 'Tiaret', 'تيارت'), ('15', 'Tizi Ouzou', 'تيزي وزو'), ('16', 'Alger', 'الجزائر'),
  ('17', 'Djelfa', 'الجلفة'), ('18', 'Jijel', 'جيجل'), ('19', 'Sétif', 'سطيف'), ('20', 'Saïda', 'سعيدة'),
  ('21', 'Skikda', 'سكيكدة'), ('22', 'Sidi Bel Abbès', 'سيدي بلعباس'), ('23', 'Annaba', 'عنابة'), ('24', 'Guelma', 'قالمة'),
  ('25', 'Constantine', 'قسنطينة'), ('26', 'Médéa', 'المدية'), ('27', 'Mostaganem', 'مستغانم'), ('28', 'M’Sila', 'المسيلة'),
  ('29', 'Mascara', 'معسكر'), ('30', 'Ouargla', 'ورقلة'), ('31', 'Oran', 'وهران'), ('32', 'El Bayadh', 'البيض'),
  ('33', 'Illizi', 'إليزي'), ('34', 'Bordj Bou Arréridj', 'برج بوعريريج'), ('35', 'Boumerdès', 'بومرداس'), ('36', 'El Tarf', 'الطارف'),
  ('37', 'Tindouf', 'تندوف'), ('38', 'Tissemsilt', 'تيسمسيلت'), ('39', 'El Oued', 'الوادي'), ('40', 'Khenchela', 'خنشلة'),
  ('41', 'Souk Ahras', 'سوق أهراس'), ('42', 'Tipaza', 'تيبازة'), ('43', 'Mila', 'ميلة'), ('44', 'Aïn Defla', 'عين الدفلى'),
  ('45', 'Naâma', 'النعامة'), ('46', 'Aïn Témouchent', 'عين تموشنت'), ('47', 'Ghardaïa', 'غرداية'), ('48', 'Relizane', 'غليزان'),
  ('49', 'Timimoun', 'تيميمون'), ('50', 'Bordj Badji Mokhtar', 'برج باجي مختار'), ('51', 'Ouled Djellal', 'أولاد جلال'),
  ('52', 'Béni Abbès', 'بني عباس'), ('53', 'In Salah', 'عين صالح'), ('54', 'In Guezzam', 'عين قزام'), ('55', 'Touggourt', 'تقرت'),
  ('56', 'Djanet', 'جانت'), ('57', 'El M’Ghair', 'المغير'), ('58', 'El Menia', 'المنيعة'),
];

String wilayaName(String code, String lang) {
  for (final w in wilayas) {
    if (w.$1 == code) return lang == 'ar' ? '${w.$1} · ${w.$3}' : '${w.$1} · ${w.$2}';
  }
  return '';
}

List<(String, String)> wilayaOptions(String lang) => [for (final w in wilayas) (w.$1, wilayaName(w.$1, lang))];
