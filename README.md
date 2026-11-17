# Speed Guardian 🚗

تطبيق للسلامة المرورية: كي يتجاوز السائق السرعة المحددة، يوصل إشعار فوري لهاتف الشريك (الزوج/الزوجة).

A road-safety app: when the driver exceeds the speed limit for a sustained period, the paired partner's phone receives an instant alert.

## كيفاش يخدم / How it works

1. كل واحد يثبّت التطبيق ويربط حسابو بالشريك عبر **كود ربط** (موافقة الطرفين ضرورية).
2. وقت القيادة، التطبيق يقيس السرعة بالـ GPS.
3. يجيب السرعة القصوى للطريق من OpenStreetMap.
4. إذا تجاوز السرعة + الهامش لمدة كافية، يسمع السائق **تحذير** أولا، ثم يتبعث **إشعار Push** للشريك.

## الهيكلة / Structure

```
lib/
  main.dart                      نقطة الدخول + شاشة بسيطة
  services/
    overspeed_detector.dart      منطق التجاوز (هامش + مدة + فترة راحة) - بدون تبعيات، قابل للاختبار
    location_service.dart        قراءة السرعة من GPS (خدمة في الخلفية على أندرويد)
    speed_limit_service.dart     جلب السرعة القصوى من OpenStreetMap (Overpass API)
    pairing_service.dart         ربط الحسابين عبر كود
    alert_service.dart           إنشاء التنبيه في Firestore
functions/
  index.js                       Cloud Function ترسل إشعار FCM كي يتخلق تنبيه
test/
  overspeed_detector_test.dart
```

## إعدادات افتراضية / Defaults

| Setting | Value |
|---|---|
| Tolerance over the limit | 10 km/h |
| Sustained duration before alert | 10 s |
| Cooldown between alerts | 5 min |

## البدء / Getting started

> ⚠️ هذا الكود مكتوب بدون تشغيل Flutter (ما كانش مثبت في بيئة الكتابة). لازم تجربو وتصلحو أي خطأ عند أول تشغيل.

```bash
git clone https://github.com/Brahim0226/speed-guardian
cd speed-guardian
flutter create . --org com.speedguardian --project-name speed_guardian   # يولّد android/ و ios/
flutter pub get
dart run flutterfire configure     # يربط مشروع Firebase
flutter test
flutter run
```

### أذونات أندرويد / Android permissions

في `android/app/src/main/AndroidManifest.xml` زيد:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

### iOS

في `ios/Runner/Info.plist` زيد `NSLocationWhenInUseUsageDescription` و`NSLocationAlwaysAndWhenInUseUsageDescription`، وفعّل *Background Modes → Location updates*.

### Firebase

1. أنشئ مشروع Firebase، فعّل **Authentication (Anonymous)** و**Firestore** و**Cloud Messaging**.
2. انشر الـ Function: `cd functions && npm install && firebase deploy --only functions`.
3. قواعد Firestore المقترحة في `firestore.rules`.

## الخصوصية / Privacy

- لا يتم إرسال الموقع للشريك، فقط تنبيه فيه السرعة والحد الأقصى.
- كل طرف يوافق على الربط ويقدر يفكّو في أي وقت.
- نتبع شروط Google Play / App Store حول الموقع في الخلفية (إفصاح واضح للمستخدم).

## حدود معروفة / Known limitations (MVP)

- **الأمان:** قواعد Firestore الحالية بسيطة: أي مستخدم مسجّل يقدر يقرأ وثائق `users` (باش يخدم البحث بالكود). قبل النشر الحقيقي لازم ننقل الربط إلى Cloud Function ونخبّيو `fcmToken`.
- السرعة القصوى من OpenStreetMap قد تكون ناقصة أو قديمة؛ إذا كانت غير معروفة ما يتبعث حتى تنبيه.
- ما تمّ تشغيله على جهاز حقيقي بعد: السلوك في الخلفية (خاصة iOS وبعض هواتف أندرويد اللي تقتل التطبيقات) لازم يتجرب.

## Roadmap

- [ ] تصحيح يدوي للسرعة القصوى (تغطية OSM في الجزائر ناقصة)
- [ ] تقرير أسبوعي ونقاط للسائقين الملتزمين
- [ ] وضع "العائلة" لأكثر من شخصين
- [ ] واجهة بالعربية والفرنسية
