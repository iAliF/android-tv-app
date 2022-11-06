import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mawaqit/generated/l10n.dart';
import 'package:mawaqit/src/enum/home_active_screen.dart';
import 'package:mawaqit/src/helpers/Api.dart';
import 'package:mawaqit/src/helpers/SharedPref.dart';
import 'package:mawaqit/src/helpers/time_utils.dart';
import 'package:mawaqit/src/models/mosque.dart';
import 'package:mawaqit/src/models/times.dart';

final mawaqitApi = "https://mawaqit.net/api/2.0";

const kAdhanDuration = Duration(minutes: 2);
const kAfterAdhanHadithDuration = Duration(minutes: 1);
const kIqamaaDuration = Duration(minutes: 1);

const kAzkarDuration = Duration(minutes: 2);

const salahDuration = Duration(minutes: 10);

class MosqueManager extends ChangeNotifier {
  final sharedPref = SharedPref();

  // String? mosqueId;
  String? mosqueUUID;

  Mosque? mosque;
  Times? times;

  HomeActiveScreen state = HomeActiveScreen.normal;

  /// get current home url
  String buildUrl(String languageCode) {
    // if (mosqueId != null) return 'https://mawaqit.net/$languageCode/id/$mosqueId?view=desktop';
    // if (mosqueSlug != null) return 'https://mawaqit.net/$languageCode/$mosqueSlug?view=desktop';

    return mosque!.url ?? '';

    return '';
  }

  Future<void> init() async {
    await Api.init();
    await loadFromLocale();
    subscribeToTime();
    notifyListeners();
  }

  salahName(int index) {
    return [
      S.current.fajr,
      S.current.duhr,
      S.current.asr,
      S.current.maghrib,
      S.current.isha,
    ][index];
  }

  // // /// update mosque id in the app and shared preference
  // Future<String> setMosqueId(String id) async {
  //   var url = 'https://mawaqit.net/en/id/$id?view=desktop';
  //
  //   var value = await http.get(Uri.parse(url));
  //   await fetchMosque();
  //
  //   if (value.statusCode != 200) {
  //     throw InvalidMosqueId();
  //   } else {
  //     AnalyticsWrapper.changeMosque(id);
  //
  //     mosqueId = id;
  //
  //     // mosqueSlug = null;
  //
  //     _saveToLocale();
  //
  //     notifyListeners();
  //     return mosqueId!;
  //   }
  // }

  /// update mosque id in the app and shared preference
  Future<void> setMosqueUUid(String uuid) async {
    try {
      mosque = await Api.getMosque(uuid);
      times = await Api.getMosqueTimes(uuid);

      // mosqueId = mosque!.id.toString();
      mosqueUUID = mosque!.uuid!;

      _saveToLocale();
    } catch (e) {}
  }

  Future<void> _saveToLocale() async {
    // await sharedPref.save('mosqueId', mosqueId);
    await sharedPref.save('mosqueUUId', mosqueUUID);
    // sharedPref.save('mosqueSlug', mosqueSlug);
  }

  Future<void> loadFromLocale() async {
    // mosqueId = await sharedPref.read('mosqueId');
    mosqueUUID = await sharedPref.read('mosqueUUId');

    if (mosqueUUID != null) await fetchMosque();
  }

  fetchMosque() async {
    if (mosqueUUID != null) {
      mosque = await Api.getMosque(mosqueUUID!);
      times = await Api.getMosqueTimes(mosqueUUID!);
    }
  }

  Future<List<Mosque>> searchMosques(String mosque, {page = 1}) async {
    final url = Uri.parse("$mawaqitApi/mosque/search?word=$mosque&page=$page");

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final results = jsonDecode(response.body);
      List<Mosque> mosques = [];

      for (var item in results) {
        try {
          mosques.add(Mosque.fromMap(item));
        } catch (e, stack) {
          debugPrintStack(label: e.toString(), stackTrace: stack);
        }
      }

      return mosques;
    } else {
      print(response.body);
      // If that response was not OK, throw an error.
      throw Exception('Failed to fetch mosque');
    }
  }

//todo handle page and get more
  Future<List<Mosque>> searchWithGps() async {
    final position = await getCurrentLocation().catchError((e) => throw GpsError());

    final url = Uri.parse("$mawaqitApi/mosque/search?lat=${position.latitude}&lon=${position.longitude}");
    Map<String, String> requestHeaders = {
      // "Api-Access-Token": mawaqitApiToken,
    };
    final response = await http.get(url, headers: requestHeaders);
    print(response.body);
    if (response.statusCode == 200) {
      final results = jsonDecode(response.body);
      List<Mosque> mosques = [];

      for (var item in results) {
        try {
          mosques.add(Mosque.fromMap(item));
        } catch (e, stack) {
          debugPrintStack(label: e.toString(), stackTrace: stack);
        }
      }

      return mosques;
    } else {
      print(response.body);
      // If that response was not OK, throw an error.
      throw Exception('Failed to fetch mosque');
    }
  }

  Future<Position> getCurrentLocation() async {
    // return Position(
    //   longitude: -1.3565692,
    //   latitude: 34.8659187,
    //   timestamp: null,
    //   accuracy: 1,
    //   altitude: 31.0,
    //   heading: 0,
    //   speed: 0,
    //   speedAccuracy: 0,
    // );
    var enabled = await GeolocatorPlatform.instance.isLocationServiceEnabled().timeout(Duration(seconds: 5));

    if (!enabled) {
      enabled = await GeolocatorPlatform.instance.openLocationSettings();
    }
    if (!enabled) throw GpsError();

    final permission = await GeolocatorPlatform.instance.requestPermission();
    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) throw GpsError();

    return await GeolocatorPlatform.instance.getCurrentPosition();
  }
}

extension MosqueHelperUtils on MosqueManager {
  calculateActiveScreen() {
    var state = HomeActiveScreen.normal;

    final now = mosqueDate();
    final lastSalahIndex = (nextSalahIndex() - 1) % 5;

    final lastSalah = actualTimes()[lastSalahIndex];

    final nextIqamaIndex = this.nextIqamaIndex();
    final lastIqamaIndex = (nextIqamaIndex - 1) % 5;
    final lastIqama = actualIqamaTimes()[lastIqamaIndex];

    if (lastSalah.difference(now).abs() < kAdhanDuration) {
      /// we are in adhan time
      state = HomeActiveScreen.adhan;
    } else if (lastSalah.difference(now).abs() < kAdhanDuration + kAfterAdhanHadithDuration) {
      /// adhan has just done
      state = HomeActiveScreen.afterAdhanHadith;
    } else if (lastIqama.difference(now).abs() < kIqamaaDuration) {
      /// we are in iqama time
      state = HomeActiveScreen.iqamaa;
    } else if (nextIqamaIndex == lastSalahIndex) {
      /// we are in time between adhan and iqama
      if (now.weekday == DateTime.friday) {
        state = HomeActiveScreen.jumuaaHadith;
      } else {
        state = HomeActiveScreen.iqamaaCountDown;
      }
    } else if ((now.difference(lastIqama) - salahDuration).abs() < kAzkarDuration) {
      state = HomeActiveScreen.afterSalahAzkar;
    }

    // state = HomeActiveScreen.afterSalahAzkar;

    if (state != this.state) {
      this.state = state;
      notifyListeners();
    }
  }

  /// listen to time and update the active home screens values
  subscribeToTime() => Timer.periodic(Duration(seconds: 1), (timer) => calculateActiveScreen());

  /// get today salah prayer times as a list of times
  List<DateTime> actualTimes() => todayTimes.map((e) => e.toTimeOfDay()!.toDate()).toList();

  /// get today iqama prayer times as a list of times
  List<DateTime> actualIqamaTimes() => [
        for (var i = 0; i < 5; i++)
          todayIqama[i]
              .toTimeOfDay(
                tryOffset: todayTimes[i].toTimeOfDay()!.toDate(),
              )!
              .toDate(),
      ];

  /// return the upcoming salah index
  /// return -1 in case of issue(invalid times format)
  int nextIqamaIndex() {
    final now = mosqueDate();
    final nextIqama = actualIqamaTimes().firstWhere(
      (element) => element.isAfter(now),
      orElse: () => actualIqamaTimes().first,
    );

    return actualIqamaTimes().indexOf(nextIqama);
  }

  /// return the upcoming salah index
  /// return -1 in case of issue(invalid times format)
  int nextSalahIndex() {
    final now = mosqueDate();
    final nextSalah = actualTimes().firstWhere(
      (element) => element.isAfter(now),
      orElse: () => actualTimes().first,
    );

    return actualTimes().indexOf(nextSalah);
  }

  String get imsak {
    try {
      int minutes = int.parse(todayTimes.first.split(':').first) * 60 +
          int.parse(todayTimes.first.split(':').last) -
          times!.imsakNbMinBeforeFajr;

      return DateFormat('HH:mm').format(DateTime(200, 1, 1, minutes ~/ 60, minutes % 60));
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack);
      return '';
    }
  }

  /// used to test time
  DateTime mosqueDate() => DateTime.now().add(Duration());

  List<String> get todayTimes {
    var t = times!.calendar[mosqueDate().month - 1][mosqueDate().day.toString()].cast<String>();
    if (t.length == 6) t.removeAt(1);
    return t;
  }

  List<String> get todayIqama =>
      times!.iqamaCalendar[mosqueDate().month - 1][mosqueDate().day.toString()].cast<String>();
}

/// user for invalid mosque id-slug
class InvalidMosqueId implements Exception {}

/// cant access gps
class GpsError implements Exception {}
