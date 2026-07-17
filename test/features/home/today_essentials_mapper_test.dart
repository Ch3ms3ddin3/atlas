import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/home/data/mock/home_mock_data.dart';
import 'package:atlas/features/home/data/today_essentials/today_essentials_mapper.dart';
import 'package:atlas/features/home/domain/models/home_models.dart';
import 'package:atlas/features/profile/domain/models/user_profile.dart';

void main() {
  group('TodayEssentialsMapper', () {
    const workingDay = HolidayStatusData(
      isHoliday: false,
      label: 'Jour ouvré',
      detail: 'Administrations et banques ouvertes aux horaires habituels.',
      icon: Icons.event_available_outlined,
    );

    const holiday = HolidayStatusData(
      isHoliday: true,
      label: 'Fête du Trône',
      detail: 'Administrations et banques fermées.',
      icon: Icons.event_outlined,
    );

    test('génère une alerte chaleur au-dessus du seuil', () {
      final essentials = TodayEssentialsMapper.fromContext(
        weather: HomeMockData.weather,
        holidayStatus: workingDay,
        cityName: 'Marrakech',
        userType: AtlasUserType.resident,
      );

      expect(essentials.alert!.title, 'Forte chaleur prévue');
      expect(essentials.alert!.severity, AlertSeverity.caution);
      expect(essentials.alert!.detail, contains('Marrakech'));
    });

    test('génère une alerte pluie selon l\'icône météo', () {
      final essentials = TodayEssentialsMapper.fromContext(
        weather: const WeatherData(
          temperature: 22,
          condition: 'Pluie',
          feelsLike: 22,
          icon: Icons.water_drop_outlined,
          weatherCode: 61,
        ),
        holidayStatus: workingDay,
        cityName: 'Casablanca',
        userType: AtlasUserType.resident,
      );

      expect(essentials.alert!.title, 'Pluie prévue');
      expect(essentials.alert!.severity, AlertSeverity.caution);
    });

    test('masque alerte et conseils météo si météo indisponible', () {
      final essentials = TodayEssentialsMapper.fromContext(
        weather: null,
        holidayStatus: workingDay,
        cityName: 'Marrakech',
        userType: AtlasUserType.resident,
      );

      expect(essentials.alert, isNull);
      expect(essentials.tip.content, HomeMockData.todayEssentials.tip.content);
      expect(essentials.tip.content, isNot(contains('hydratez-vous')));
    });

    test('propose un conseil férié quand les administrations sont fermées', () {
      final essentials = TodayEssentialsMapper.fromContext(
        weather: null,
        holidayStatus: holiday,
        cityName: 'Rabat',
        userType: AtlasUserType.resident,
      );

      expect(essentials.alert, isNull);
      expect(essentials.tip.category, 'Jour férié');
      expect(essentials.tip.content, contains('demain'));
    });

    test('n\'expose pas de rappel administratif fictif', () {
      final essentials = TodayEssentialsMapper.fromContext(
        weather: HomeMockData.weather,
        holidayStatus: workingDay,
        cityName: 'Marrakech',
        userType: AtlasUserType.resident,
      );

      expect(essentials.adminReminder, isNull);
    });

    test('utilise le conseil par défaut hors chaleur et hors férié', () {
      final essentials = TodayEssentialsMapper.fromContext(
        weather: const WeatherData(
          temperature: 24,
          condition: 'Peu nuageux',
          feelsLike: 24,
          icon: Icons.wb_sunny_outlined,
          weatherCode: 1,
        ),
        holidayStatus: workingDay,
        cityName: 'Marrakech',
        userType: AtlasUserType.resident,
      );

      expect(essentials.tip.content, HomeMockData.todayEssentials.tip.content);
    });

    test('adapte le conseil pour un visiteur', () {
      final essentials = TodayEssentialsMapper.fromContext(
        weather: const WeatherData(
          temperature: 24,
          condition: 'Peu nuageux',
          feelsLike: 24,
          icon: Icons.wb_sunny_outlined,
          weatherCode: 1,
        ),
        holidayStatus: workingDay,
        cityName: 'Marrakech',
        userType: AtlasUserType.tourist,
      );

      expect(essentials.tip.category, 'Conseil voyage');
      expect(essentials.tip.content, contains('Prix'));
    });
  });
}
