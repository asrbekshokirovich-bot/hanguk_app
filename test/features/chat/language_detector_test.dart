import 'package:flutter_test/flutter_test.dart';
import 'package:hanguk_app/features/chat/data/language_detector.dart';

void main() {
  group('detectMessageLanguage', () {
    test('detects Korean Hangul', () {
      expect(
        detectMessageLanguage('안녕하세요, 한국 대학교에 대해 알려주세요',
            fallback: 'uz'),
        'ko',
      );
    });

    test('detects Russian Cyrillic', () {
      expect(
        detectMessageLanguage('Расскажите про корейские университеты',
            fallback: 'en'),
        'ru',
      );
    });

    test('detects Vietnamese diacritics', () {
      expect(
        detectMessageLanguage('Tôi muốn học đại học ở Hàn Quốc',
            fallback: 'en'),
        'vi',
      );
    });

    test('detects Uzbek via stop-words', () {
      expect(
        detectMessageLanguage('Salom, universitetga ariza haqida nima kerak',
            fallback: 'en'),
        'uz',
      );
    });

    test('detects Uzbek via oʻ/gʻ letters', () {
      expect(
        detectMessageLanguage("oʻqishni boshlamoqchiman", fallback: 'en'),
        'uz',
      );
    });

    test('detects English via stop-words', () {
      expect(
        detectMessageLanguage('What documents do I need for the university',
            fallback: 'uz'),
        'en',
      );
    });

    test('falls back when ambiguous / too short', () {
      expect(detectMessageLanguage('OK', fallback: 'ru'), 'ru');
      expect(detectMessageLanguage('123 456', fallback: 'ko'), 'ko');
      expect(detectMessageLanguage('', fallback: 'vi'), 'vi');
    });

    test('Korean wins even when mixed with Latin', () {
      expect(
        detectMessageLanguage('TOPIK 시험 준비', fallback: 'en'),
        'ko',
      );
    });
  });
}
