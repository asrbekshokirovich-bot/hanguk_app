/// Lightweight, dependency-free language detector for the Hanguk AI chat.
///
/// The chat backend replies in whatever language we pass as the `language`
/// hint. Previously we always passed the *app UI locale*, so a user who
/// typed in Korean while the app was set to Uzbek got an Uzbek answer. This
/// detector inspects the **message the user actually typed** and returns the
/// best-matching supported language so the AI mirrors the user's language.
///
/// Supported codes (matching the app's locales): 'ko', 'ru', 'vi', 'uz',
/// 'en'. When the text is too short or ambiguous to call confidently, the
/// caller's [fallback] (the app locale) is returned instead.
library;

/// Detects the language of [text], returning one of the supported codes.
///
/// Strategy:
///  1. Script-based detection first — Hangul, Cyrillic and Vietnamese
///     diacritics are unambiguous and win immediately.
///  2. For plain Latin text (Uzbek vs English), score against small
///     stop-word sets and pick the winner.
///  3. If nothing is conclusive, return [fallback].
String detectMessageLanguage(String text, {required String fallback}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return fallback;

  // ── 1. Unambiguous scripts ────────────────────────────────────────────
  // Korean Hangul: syllables + compatibility/conjoining Jamo.
  if (RegExp(r'[가-힣ᄀ-ᇿ㄰-㆏]').hasMatch(trimmed)) {
    return 'ko';
  }
  // Cyrillic → Russian (the app's only Cyrillic locale).
  if (RegExp(r'[Ѐ-ӿ]').hasMatch(trimmed)) {
    return 'ru';
  }
  // Vietnamese: Latin Extended Additional block + the đ/ơ/ư letters that
  // don't appear in Uzbek/English Latin text.
  if (RegExp(r'[Ạ-ỹĂăĐđƠơƯưÀ-ÃÈ-ÊÌÍÒ-ÕÙÚÝà-ãè-êìíò-õùúý]')
      .hasMatch(trimmed)) {
    return 'vi';
  }

  // ── 2. Latin: Uzbek vs English ────────────────────────────────────────
  final lower = trimmed.toLowerCase();

  // Uzbek uses the modifier-letter / apostrophe forms oʻ and gʻ — a strong
  // Uzbek signal that never shows up in English.
  if (RegExp(r"[ʻʼ‘’`]").hasMatch(trimmed) &&
      RegExp(r"(o[ʻʼ‘’`]|g[ʻʼ‘’`])").hasMatch(lower)) {
    return 'uz';
  }

  final words = lower
      .split(RegExp(r'[^a-z]+'))
      .where((w) => w.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) return fallback;

  const uzStop = {
    'men',
    'sen',
    'biz',
    'siz',
    'uchun',
    'qanday',
    'qanaqa',
    'qayer',
    'qayerda',
    'nima',
    'nega',
    'salom',
    'rahmat',
    'iltimos',
    'kerak',
    'bormi',
    'yoki',
    'ham',
    'va',
    'bilan',
    'qilish',
    'boladi',
    'yaxshi',
    'universitet',
    'hujjat',
    'ariza',
    'talab',
    'qabul',
    'haqida',
    'menga',
    'sizga',
    'qachon',
    'kim',
  };
  const enStop = {
    'the',
    'a',
    'an',
    'is',
    'are',
    'am',
    'was',
    'were',
    'what',
    'how',
    'why',
    'when',
    'where',
    'who',
    'which',
    'please',
    'hello',
    'hi',
    'thanks',
    'thank',
    'you',
    'your',
    'i',
    'me',
    'my',
    'we',
    'can',
    'could',
    'should',
    'would',
    'do',
    'does',
    'about',
    'for',
    'and',
    'or',
    'with',
    'university',
    'document',
    'need',
    'want',
    'help',
  };

  var uz = 0;
  var en = 0;
  for (final w in words) {
    if (uzStop.contains(w)) uz++;
    if (enStop.contains(w)) en++;
  }

  if (uz > en) return 'uz';
  if (en > uz) return 'en';

  // ── 3. Inconclusive — defer to the app locale. ───────────────────────
  return fallback;
}
