# دليل البدء السريع - التطبيق المالي

## 🎉 التطبيق الآن باللغة العربية بالكامل!

### ما تم تنفيذه:
✅ جميع النصوص مترجمة للعربية
✅ دعم الاتجاه من اليمين لليسار (RTL)
✅ تصدير PDF بخطوط عربية
✅ تصدير Excel بنصوص عربية
✅ جميع الأزرار والحقول والقوائم بالعربية

### لتشغيل التطبيق:

```bash
flutter pub get
flutter run
```

### الميزات الرئيسية:

#### 1. صفحة النقد (Cash)
- إدارة صندوق الأموال بالدولار
- إنشاء وتعديل التحويلات
- تحويل العملات من دولار إلى ليرة سورية
- حذف واسترداد التحويلات

#### 2. صفحة التحويل (Convert)
- حاسبة تحويل العملات
- تحويل بين الدولار والليرة السورية
- حساب تلقائي عند إدخال الأرقام

#### 3. صفحة المصروفات (Expenses)
- إضافة وتعديل المصروفات
- دعم ثلاث عملات: دولار، ليرة سورية، ليرة تركية
- رفع الفواتير
- تصفية حسب العملة والتاريخ
- خيارات التصفية: اليوم، هذا الأسبوع، هذا الشهر، مخصص

#### 4. صفحة التصدير (Export)
- تصدير PDF بخطوط عربية
- تصدير Excel بنصوص عربية
- يطبق التصفية المحددة في صفحة المصروفات

### تغيير اللغة:

لتغيير اللغة إلى الإنجليزية، افتح ملف `lib/main.dart` وغير:

```dart
locale: const Locale('ar'),  // العربية
```

إلى:

```dart
locale: const Locale('en'),  // الإنجليزية
```

### الملفات المهمة:

- `lib/l10n/app_localizations.dart` - نظام الترجمة
- `lib/main.dart` - إعدادات التطبيق الرئيسية
- `LOCALIZATION.md` - دليل الترجمة الكامل
- `ARABIC_LOCALIZATION_SUMMARY.md` - ملخص التغييرات

### ملاحظات:

- التطبيق يستخدم الخطوط العربية (Amiri) في تصدير PDF
- جميع الحقول والأزرار تدعم الإدخال العربي
- التخطيط يتكيف تلقائياً مع اتجاه النص من اليمين لليسار

---

# Quick Start Guide - Finance App

## 🎉 App is Now Fully in Arabic!

### What Was Implemented:
✅ All text translated to Arabic
✅ RTL (Right-to-Left) support
✅ PDF export with Arabic fonts
✅ Excel export with Arabic text
✅ All buttons, fields, and menus in Arabic

### To Run the App:

```bash
flutter pub get
flutter run
```

### Main Features:

#### 1. Cash Page
- Manage fund box in USD
- Create and edit transfers
- Convert currency from USD to SYP
- Delete and refund transfers

#### 2. Convert Page
- Currency converter calculator
- Convert between USD and SYP
- Automatic calculation on input

#### 3. Expenses Page
- Add and edit expenses
- Support for 3 currencies: USD, SYP, TRY
- Upload invoices
- Filter by currency and date
- Filter options: Today, This Week, This Month, Custom

#### 4. Export Page
- Export PDF with Arabic fonts
- Export Excel with Arabic text
- Applies filters from Expenses page

### Change Language:

To change language to English, open `lib/main.dart` and change:

```dart
locale: const Locale('ar'),  // Arabic
```

to:

```dart
locale: const Locale('en'),  // English
```

### Important Files:

- `lib/l10n/app_localizations.dart` - Translation system
- `lib/main.dart` - Main app configuration
- `LOCALIZATION.md` - Complete localization guide
- `ARABIC_LOCALIZATION_SUMMARY.md` - Summary of changes

### Notes:

- App uses Arabic fonts (Amiri) for PDF export
- All fields and buttons support Arabic input
- Layout automatically adapts to RTL text direction
