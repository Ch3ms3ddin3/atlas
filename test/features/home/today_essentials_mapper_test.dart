import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/home/data/mock/home_mock_data.dart';
import 'package:atlas/features/home/data/today_essentials/today_essentials_mapper.dart';
import 'package:atlas/features/home/domain/models/home_models.dart';

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
      );

      expect(essentials.alert.title, 'Forte chaleur prévue');
      expect(essentials.alert.severity, AlertSeverity.caution);
      expect(essentials.alert.detail, contains('Marrakech'));
    });

    test('génère une alerte pluie selon l\'icône météo', () {
      final essentials = TodayEssentialsMapper.fromContext(
        weather: const WeatherData(
          temperature: 22,
          condition: 'Pluie',
          feelsLike: 22,
          icon: Icons.water_drop_outlined,
          updatedAt: 'à l\'instant',
        ),
        holidayStatus: workingDay,
        cityName: 'Casablanca',
      );

      expect(essentials.alert.title, 'Pluie prévue');
      expect(essentials.alert.severity, AlertSeverity.caution);
    });

    test('propose un conseil férié quand les administrations sont fermées', () {
      final essentials = TodayEssentialsMapper.fromContext(
        weather: const WeatherData(
          temperature: 24,
          condition: 'Peu nuageux',
          feelsLike: 24,
          icon: Icons.wb_sunny_outlined,
          updatedAt: 'à l\'instant',
        ),
        holidayStatus: holiday,
        cityName: 'Rabat',
      );

      expect(essentials.tip.category, 'Jour férié');
      expect(essentials.tip.content, contains('demain'));
    });

    test('conserve le rappel administratif mock', () {
      final essentials = TodayEssentialsMapper.fromContext(
        weather: HomeMockData.weather,
        holidayStatus: workingDay,
        cityName: 'Marrakech',
      );

      expect(
        essentials.adminReminder.title,
        HomeMockData.todayEssentials.adminReminder.title,
      );
    });

    test('utilise le conseil par défaut hors chaleur et hors férié', () {
      final essentials = TodayEssentialsMapper.fromContext(
        weather: const WeatherData(
          temperature: 24,
          condition: 'Peu nuageux',
          feelsLike: 24,
          icon: Icons.wb_sunny_outlined,
          updatedAt: 'à l\'instant',
        ),
        holidayStatus: workingDay,
        cityName: 'Marrakech',
      );

      expect(essentials.tip.content, HomeMockData.todayEssentials.tip.content);
    });
  });
}
