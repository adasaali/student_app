# تطبيق بوابة الطالب (Flutter)

واجهة Flutter لأندرويد و iOS، مطابقة بالتصميم والحقول للوحة الطالب الحالية (PHP).

## 1) تجهيز المشروع

هاد المجلد فيه ملفات `lib/` و`pubspec.yaml` بس، وناقصو باقي هيكلية Flutter
(مجلدات android/ios/... يلي بتتولد تلقائياً). اعمل الخطوات التالية على جهازك:

```bash
# تأكد إنك مثبت Flutter SDK أول: https://docs.flutter.dev/get-started/install

flutter create student_app_full
cd student_app_full

# احذف مجلد lib الفارغ وحط مكانه lib/ يلي جبناها، وبدّل pubspec.yaml
```

بعدين انسخ محتوى مجلد `lib/` وملف `pubspec.yaml` من هاد التسليم إلى المشروع الجديد
(استبدال الموجود).

## 2) تثبيت الحزم

```bash
flutter pub get
```

## 3) ربط التطبيق بالسيرفر

افتح `lib/services/api_service.dart` وبدّل:

```dart
static const String baseUrl = 'https://YOUR-SCHOOL-DOMAIN.com/api';
```

بالرابط الحقيقي لسيرفرك.

⚠️ **مهم جداً:** التطبيق حالياً بيتوقع إنو عندك على السيرفر 3 endpoints ترجع JSON:

| Endpoint | Method | الوظيفة |
|---|---|---|
| `/api/login.php` | POST | تسجيل الدخول وإرجاع JWT token |
| `/api/student_data.php` | GET | بيانات الطالب (يقبل `?student_id=` اختياري لعرض بيانات أخ) |
| `/api/siblings.php` | GET | قائمة إخوة الطالب |

هاد الـ endpoints لسا لازم تُبنى بـ PHP (الكود الحالي يلي عندك بيطبع HTML
مباشرة وبيعتمد على PHP Session، مش مناسب للموبايل). لما تكون جاهز، احكيلي
وبنبني سوا API كامل بـ PHP + JWT مطابق تماماً لهاي الاستدعاءات.

## 4) التشغيل

```bash
flutter run
```

## بنية المشروع

```
lib/
  main.dart                    # نقطة الدخول
  theme/app_theme.dart         # الألوان والتنسيق (مطابق لهوية الموقع)
  models/student.dart          # نموذج بيانات الطالب + الإخوة
  services/
    api_service.dart           # كل استدعاءات الـ API
    auth_service.dart          # تسجيل الدخول + تخزين آمن للتوكن
    student_provider.dart      # حالة بيانات الطالب المعروض + التبديل بين الإخوة
  screens/
    login_screen.dart          # شاشة تسجيل الدخول
    home_shell.dart            # الحاوية (Header + Bottom Nav)
    dashboard_screen.dart      # الرئيسية (ترحيب + كروت الإخوة)
    profile_screen.dart        # الملف الشخصي (كل الحقول)
```

## ملاحظات

- التطبيق يدعم RTL بالكامل ومطابق للهوية البصرية (البنفسجي #6c5ce7).
- التوكن يُخزَّن بشكل آمن عبر `flutter_secure_storage` (Keychain على iOS، Keystore على أندرويد) — أأمن بكثير من SharedPreferences.
- لإضافة خط Cairo فعلياً بالتطبيق: حمّل ملفات الخط وحطها بـ `assets/fonts/` وسجّلها بـ `pubspec.yaml`، أو استخدم حزمة `google_fonts`.
