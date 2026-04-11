# Frontend-Backend Compatibility (v3.1+)

## ملخص التحديثات

تم تحديث Frontend ليتوافق مع Backend v3.1+ الذي يدعم:
1. ✅ دعم `user_id` في Fund Box endpoint
2. ✅ دعم `converted_amount` في Exchange creation

---

## 1. Fund Box with user_id Support

### التغييرات في Frontend:

#### الملفات المعدلة:
- `lib/features/fund_box/data/datasources/fund_box_api_datasource.dart`
- `lib/features/fund_box/data/repositories/fund_box_repository_impl.dart`
- `lib/features/fund_box/domain/repositories/fund_box_repository.dart`
- `lib/features/fund_box/domain/usecases/get_fund_box_usecase.dart`
- `lib/features/admin_group/presentation/widgets/member_fund_box_balance.dart`

#### الوظيفة الجديدة:
- **`getFundBoxByUserId(userId, {currency})`**: جلب fund box لمستخدم محدد
- يتم استخدامه في `MemberFundBoxBalance` widget لعرض أرصدة الأعضاء

#### الاستخدام:
```dart
// في MemberFundBoxBalance widget
final result = await di.sl<GetFundBoxUseCase>().call(widget.userId);
```

#### الصلاحيات:
- **Admin** يمكنه فقط رؤية أرصدة **Users** في مجموعته
- **SuperAdmin** يمكنه فقط رؤية أرصدة **Admins** في مجموعته
- يتم التحقق من الصلاحيات في Backend

---

## 2. Exchange with converted_amount Support

### التغييرات في Frontend:

#### الملفات المعدلة:
1. **ExchangeDto** (`lib/features/exchanges/data/models/exchange_dto.dart`):
   - تحديث `fromJson` لقراءة `converted_amount` من Backend response
   - دعم `amount_syp` و `amount_try` و `converted_amount`

2. **ExchangeApiDataSource** (`lib/features/exchanges/data/datasources/exchange_api_datasource.dart`):
   - تحديث `createExchange` لقبول `convertedAmount` كحقل اختياري
   - `exchangeRate` أصبح اختياري أيضاً
   - يجب توفير واحد على الأقل من `exchangeRate` أو `convertedAmount`

3. **ExchangeRepository** (`lib/features/exchanges/domain/repositories/exchange_repository.dart`):
   - تحديث interface لدعم `convertedAmount`

4. **ExchangeRepositoryImpl** (`lib/features/exchanges/data/repositories/exchange_repository_impl.dart`):
   - تحديث implementation لتمرير `convertedAmount` إلى API

5. **CreateExchangeUseCase** (`lib/features/exchanges/domain/usecases/create_exchange_usecase.dart`):
   - تحديث use case لدعم `convertedAmount`

6. **CreateExchangeEvent** (`lib/features/exchanges/presentation/bloc/exchange_event.dart`):
   - تحديث event لدعم `convertedAmount`

7. **ExchangeBloc** (`lib/features/exchanges/presentation/bloc/exchange_bloc.dart`):
   - تحديث bloc لتمرير `convertedAmount` إلى use case

8. **UI Pages**:
   - `lib/ui/currency_tool_page.dart` (Admin Exchange Page)
   - `lib/features/exchanges/presentation/pages/user_exchange_page.dart` (User Exchange Page)
   - الآن يرسلان `convertedAmount` مباشرة بدلاً من `exchangeRate`

### السلوك الجديد:

#### قبل التحديث:
```dart
// Frontend كان يحسب exchange_rate ثم يرسله
final exchangeRate = convertedAmount / amountUsd;
CreateExchangeEvent(
  exchangeRate: exchangeRate, // Required
  // ...
)
```

#### بعد التحديث:
```dart
// Frontend يرسل converted_amount مباشرة
CreateExchangeEvent(
  exchangeRate: null, // Optional
  convertedAmount: convertedAmount, // Send directly
  // ...
)
```

### Backend Logic:
- إذا تم توفير `converted_amount` فقط: Backend يحسب `exchange_rate` تلقائياً
- إذا تم توفير `exchange_rate` فقط: Backend يحسب `converted_amount` تلقائياً
- إذا تم توفير كليهما: Backend يتحقق من التطابق (tolerance = 0.01)

---

## 3. Backward Compatibility

### Fund Box:
- ✅ إذا لم يتم توفير `user_id`، يتم إرجاع fund box للمستخدم الحالي (نفس السلوك السابق)

### Exchange:
- ✅ يمكن إرسال `exchange_rate` فقط (backward compatible)
- ✅ يمكن إرسال `converted_amount` فقط (new feature)
- ✅ يمكن إرسال كليهما (validation)

---

## 4. Testing Checklist

### Fund Box with user_id:
- [x] Admin يمكنه جلب أرصدة User في مجموعته
- [x] Admin لا يمكنه جلب أرصدة User خارج مجموعته (403)
- [x] SuperAdmin يمكنه جلب أرصدة أي Admin في مجموعته
- [x] SuperAdmin لا يمكنه جلب أرصدة User مباشرة (403)
- [x] User لا يمكنه جلب أرصدة مستخدم آخر (403)
- [x] إرجاع 404 عندما يكون user_id غير موجود
- [x] إرجاع fund box للمستخدم الحالي عندما لا يتم توفير user_id

### Exchange with converted_amount:
- [x] إنشاء exchange مع `converted_amount` فقط
- [x] إنشاء exchange مع `exchange_rate` فقط (backward compatibility)
- [x] إنشاء exchange مع كلا الحقلين (validation)
- [x] إرجاع 422 عندما تكون القيم غير متطابقة
- [x] إرجاع 422 عندما لا يتم توفير أي من الحقلين
- [x] حساب `exchange_rate` تلقائياً من `converted_amount` (في Backend)
- [x] حساب `converted_amount` تلقائياً من `exchange_rate` (في Backend)
- [x] تضمين `converted_amount` في response
- [x] قراءة `converted_amount` من response في Frontend

---

## 5. API Request/Response Examples

### Fund Box with user_id:

**Request:**
```
GET /api/v1/fund-box?user_id=5
Authorization: Bearer {admin_token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "user_id": 5,
    "balance_usd": 500.00,
    "balance_syp": 5800000.00,
    "balance_try": 16250.00,
    "last_calculated_at": "2025-01-15T10:30:00Z",
    "updated_at": "2025-01-15T10:30:00Z"
  }
}
```

### Exchange with converted_amount:

**Request:**
```json
POST /api/v1/exchanges
Authorization: Bearer {token}
Content-Type: application/json

{
  "target_currency": "SYP",
  "amount_usd": 100.00,
  "converted_amount": 1160000.00,
  "exchange_date": "2025-01-15",
  "notes": "Exchange for daily expenses"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Exchange created successfully",
  "data": {
    "id": 1,
    "user_id": 3,
    "transfer_id": null,
    "target_currency": "SYP",
    "amount_usd": 100.00,
    "exchange_rate": 11600.00,
    "converted_amount": 1160000.00,
    "amount_syp": 1160000.00,
    "amount_try": null,
    "exchange_date": "2025-01-15",
    "notes": "Exchange for daily expenses",
    "created_at": "2025-01-15T10:30:00Z",
    "updated_at": "2025-01-15T10:30:00Z"
  }
}
```

---

## 6. Files Modified Summary

### Fund Box Changes:
1. `lib/features/fund_box/data/datasources/fund_box_api_datasource.dart`
2. `lib/features/fund_box/data/repositories/fund_box_repository_impl.dart`
3. `lib/features/fund_box/domain/repositories/fund_box_repository.dart`
4. `lib/features/fund_box/domain/usecases/get_fund_box_usecase.dart`
5. `lib/features/admin_group/presentation/widgets/member_fund_box_balance.dart` (New)
6. `lib/features/admin_group/presentation/widgets/group_member_card.dart`

### Exchange Changes:
1. `lib/features/exchanges/data/models/exchange_dto.dart`
2. `lib/features/exchanges/data/datasources/exchange_api_datasource.dart`
3. `lib/features/exchanges/data/repositories/exchange_repository_impl.dart`
4. `lib/features/exchanges/domain/repositories/exchange_repository.dart`
5. `lib/features/exchanges/domain/usecases/create_exchange_usecase.dart`
6. `lib/features/exchanges/presentation/bloc/exchange_event.dart`
7. `lib/features/exchanges/presentation/bloc/exchange_bloc.dart`
8. `lib/ui/currency_tool_page.dart`
9. `lib/features/exchanges/presentation/pages/user_exchange_page.dart`

---

## 7. Migration Notes

### للانتقال من Backend v3.0 إلى v3.1+:

1. **Fund Box**: لا يتطلب تغييرات في الكود الحالي (backward compatible)
2. **Exchange**: 
   - الكود الحالي يعمل بدون تغييرات (يرسل `exchange_rate`)
   - للتحديث لاستخدام `converted_amount`، قم بتحديث UI pages (تم بالفعل)

---

## 8. Known Issues

### None
- جميع التغييرات backward compatible
- لا توجد breaking changes

---

## 9. Future Improvements

1. **Batch Fund Box Fetching**: 
   - إضافة endpoint batch لجلب أرصدة مستخدمين متعددين في request واحد
   - `GET /api/v1/fund-box/batch?user_ids=1,2,3,4`

2. **Exchange Rate Validation**:
   - إضافة client-side validation للتحقق من التطابق قبل الإرسال
   - تقليل network requests الفاشلة

---

**تاريخ الإنشاء:** 2025-01-15  
**الإصدار:** 1.0  
**Backend Version:** v3.1+  
**Frontend Version:** Compatible with Backend v3.1+

