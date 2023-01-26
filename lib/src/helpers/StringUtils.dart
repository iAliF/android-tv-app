import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mawaqit/i18n/AppLanguage.dart';
import 'package:provider/provider.dart';
extension StringUtils on String {
  /// convert string to UpperCamelCaseFormat
  String get toCamelCase {
    final separated = trim().toLowerCase().split(' ');

    var value = separated.first;
    for (var i = 1; i < separated.length; i++) {
      final val = separated[i];

      value += toBeginningOfSentenceCase(val) ?? '';
    }

    return value;
  }
}

String? toCamelCase(String? value) {
  return value?.toCamelCase;
}

class StringManager {
  // final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  static RegExp arabicLetters = RegExp(r'[\u0600-\u06ff]');
  static RegExp urduLetters = RegExp(r'[\u0600-\u06ff]+');
  static const fontFamilyKufi = "kufi";
  static const fontFamilyArial = "arial";
  static const fontFamilyHelvetica = "helvetica";

  static String? getFontFamily(BuildContext context) {
    String langCode = "${context.read<AppLanguage>().appLocal}";
    if (langCode == "ar" || langCode == "ur") {
      return fontFamilyKufi;
    }
    return null;
  }
  /// return list
  static List convertStringToList (String text){

    List<String> list = List.from(text.split( RegExp(r"\s+")));


    List<int> arabicIndexes = [];
    arabicIndexes = list.asMap().entries.where((entry) => arabicLetters.hasMatch(entry.value)).map((entry)=>entry.key).toList();
    if (arabicIndexes.isEmpty) return list;
    List<String> sublist = list.sublist(arabicIndexes.first,arabicIndexes.last+1);
// Reverse the sublist
    sublist = sublist.reversed.toList();
// Replace the original sublist with the reversed sublist
    list.replaceRange(arabicIndexes.first, arabicIndexes.last+1, sublist);


    return list ;
  }
}
