# التغييرات المطلوبة في Backend

هذا الملف يوثق جميع التغييرات المطلوبة في Backend بعد التحديثات التي تمت على Frontend.

## 1. إضافة دعم `user_id` في Fund Box Endpoint

### المتطلب
Frontend يحتاج إلى جلب أرصدة Fund Box لمستخدمين آخرين (Admin يرى أرصدة Users، SuperAdmin يرى أرصدة Admins).

### التغيير المطلوب
تحديث endpoint `/api/v1/fund-box` لدعم query parameter `user_id`.

#### Endpoint الحالي:
```
GET /api/v1/fund-box
GET /api/v1/fund-box?currency=USD
```

#### Endpoint المطلوب:
```
GET /api/v1/fund-box?user_id={userId}
GET /api/v1/fund-box?user_id={userId}&currency=USD
```

### المتطلبات الأمنية:
- يجب أن يكون المستخدم المصادق عليه (authenticated user) هو **Admin** أو **SuperAdmin**
- **Admin** يمكنه فقط رؤية أرصدة **Users** في مجموعته (group)
- **SuperAdmin** يمكنه رؤية أرصدة جميع **Admins**
- يجب إرجاع **403 Forbidden** إذا حاول المستخدم رؤية أرصدة مستخدم لا يملك صلاحية الوصول إليها
- إذا كان `user_id` غير موجود، يجب إرجاع **404 Not Found**

### Response Format:
```json
{
  "success": true,
  "data": {
    "id": 1,
    "user_id": 3,
    "balance_usd": 1000.00,
    "balance_syp": 11600000.00,
    "balance_try": 32500.00,
    "last_updated": "2025-01-15T10:30:00Z",
    "last_calculated_at": "2025-01-15T10:30:00Z"
  }
}
```

### Implementation Notes:
- إذا لم يتم توفير `user_id`، يجب إرجاع fund box للمستخدم الحالي (سلوك افتراضي)
- إذا تم توفير `user_id`، يجب التحقق من الصلاحيات أولاً
- يجب التحقق من أن المستخدم المستهدف موجود في نفس المجموعة (للـ Admin)
- يجب التحقق من أن المستخدم المستهدف هو Admin (للـ SuperAdmin)

---

## 2. تحديث Exchange Creation Endpoint لدعم `converted_amount`

### المتطلب
Frontend الآن يسمح للمستخدم بإدخال المبلغ المصرف مباشرة (converted amount) بدلاً من سعر الصرف. يجب على Backend قبول `converted_amount` كحقل إضافي أو بديل.

### التغيير المطلوب
تحديث endpoint `/api/v1/exchanges` (POST) لقبول `converted_amount` كحقل اختياري.

#### Request Body الحالي:
```json
{
  "target_currency": "SYP",
  "amount_usd": 100.00,
  "exchange_rate": 11600.00,
  "exchange_date": "2025-01-15",
  "notes": "Exchange for daily expenses",
  "transfer_id": 123  // Optional
}
```

#### Request Body المطلوب:
```json
{
  "target_currency": "SYP",
  "amount_usd": 100.00,
  "exchange_rate": 11600.00,  // Optional if converted_amount is provided
  "converted_amount": 1160000.00,  // NEW: Optional if exchange_rate is provided
  "exchange_date": "2025-01-15",
  "notes": "Exchange for daily expenses",
  "transfer_id": 123  // Optional
}
```

### Logic المطلوب:
1. **إذا تم توفير `converted_amount` و `exchange_rate`:**
   - يجب التحقق من أن `exchange_rate = converted_amount / amount_usd`
   - إذا كانت القيم غير متطابقة، يجب إرجاع **422 Validation Error**

2. **إذا تم توفير `converted_amount` فقط:**
   - يجب حساب `exchange_rate` تلقائياً: `exchange_rate = converted_amount / amount_usd`
   - حفظ `exchange_rate` المحسوب في قاعدة البيانات

3. **إذا تم توفير `exchange_rate` فقط:**
   - يجب الحفاظ على السلوك الحالي
   - حساب `converted_amount` تلقائياً: `converted_amount = amount_usd * exchange_rate`

4. **إذا لم يتم توفير أي منهما:**
   - يجب إرجاع **422 Validation Error**

### Validation Rules:
- `converted_amount` يجب أن يكون رقم موجب (`> 0`)
- `converted_amount` يجب أن يكون أكبر من أو يساوي `amount_usd` (عادة)
- يجب التحقق من أن `amount_usd` موجود ومفعل

### Response Format:
```json
{
  "success": true,
  "data": {
    "id": 1,
    "user_id": 3,
    "transfer_id": null,
    "target_currency": "SYP",
    "amount_usd": 100.00,
    "exchange_rate": 11600.00,
    "converted_amount": 1160000.00,  // NEW: Include in response
    "exchange_date": "2025-01-15",
    "notes": "Exchange for daily expenses",
    "created_at": "2025-01-15T10:30:00Z",
    "updated_at": "2025-01-15T10:30:00Z"
  }
}
```

### Database Schema Update:
- إضافة حقل `converted_amount` إلى جدول `exchanges` إذا لم يكن موجوداً
- أو حساب `converted_amount` ديناميكياً من `amount_usd * exchange_rate`

---

## 3. التحقق من Endpoints الموجودة

### Endpoints التي يجب أن تعمل بدون تغييرات:

#### 3.1 Incoming Endpoints
- `GET /api/v1/incoming` - جلب جميع الواردات (موجود)
- `POST /api/v1/incoming` - إنشاء وارد جديد (موجود)
- `PUT /api/v1/incoming/{id}` - تحديث وارد (موجود)
- `DELETE /api/v1/incoming/{id}` - حذف وارد (موجود)

**ملاحظة:** يجب التأكد من أن SuperAdmin يمكنه إنشاء incoming entries يدوياً.

#### 3.2 Transfer Endpoints
- `GET /api/v1/transfers` - جلب جميع التحويلات (موجود)
- `POST /api/v1/transfers` - إنشاء تحويل جديد (موجود)
- `PUT /api/v1/transfers/{id}` - تحديث تحويل (موجود)
- `DELETE /api/v1/transfers/{id}` - حذف تحويل (موجود)

#### 3.3 Exchange Endpoints
- `GET /api/v1/exchanges` - جلب جميع التصريفات (موجود)
- `GET /api/v1/exchanges/{id}` - جلب تصريف محدد (موجود)
- `GET /api/v1/exchanges/transfer/{transferId}` - جلب تصريفات تحويل محدد (موجود)

#### 3.4 Fund Box Endpoints
- `GET /api/v1/fund-box` - جلب fund box للمستخدم الحالي (موجود)
- `PUT /api/v1/fund-box` - تحديث fund box (موجود، Admin only)

---

## 4. ملخص التغييرات المطلوبة

### الأولوية العالية (مطلوبة للوظائف الأساسية):

1. ✅ **إضافة دعم `user_id` في `/api/v1/fund-box`**
   - ضروري لعرض أرصدة الأعضاء في صفحة Group Management
   - يجب إضافة التحقق من الصلاحيات (Authorization)

2. ✅ **إضافة دعم `converted_amount` في `/api/v1/exchanges` (POST)**
   - ضروري لواجهة التصريف الجديدة
   - يجب إضافة validation logic

### الأولوية المتوسطة (تحسينات):

3. ✅ **إضافة `converted_amount` في Response of Exchange Endpoints**
   - تحسين للـ API consistency
   - يمكن حسابه ديناميكياً إذا لم يكن موجوداً في DB

### الأولوية المنخفضة (اختيارية):

4. ⚠️ **تحسين Error Messages**
   - رسائل خطأ أكثر وضوحاً باللغة العربية
   - رسائل خطأ محددة للصلاحيات (403 errors)

---

## 5. أمثلة على Requests والResponses

### مثال 1: جلب Fund Box لمستخدم محدد (Admin يرى User)

**Request:**
```
GET /api/v1/fund-box?user_id=5
Authorization: Bearer {admin_token}
```

**Response (Success):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "user_id": 5,
    "balance_usd": 500.00,
    "balance_syp": 5800000.00,
    "balance_try": 16250.00,
    "last_updated": "2025-01-15T10:30:00Z",
    "last_calculated_at": "2025-01-15T10:30:00Z"
  }
}
```

**Response (403 Forbidden - No Permission):**
```json
{
  "success": false,
  "message": "Access denied. You do not have permission to view this user's fund box.",
  "errors": null
}
```

**Response (404 Not Found - User Not Found):**
```json
{
  "success": false,
  "message": "User fund box not found.",
  "errors": null
}
```

### مثال 2: إنشاء Exchange مع `converted_amount`

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

**Response (Success):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "user_id": 3,
    "transfer_id": null,
    "target_currency": "SYP",
    "amount_usd": 100.00,
    "exchange_rate": 11600.00,
    "converted_amount": 1160000.00,
    "exchange_date": "2025-01-15",
    "notes": "Exchange for daily expenses",
    "created_at": "2025-01-15T10:30:00Z",
    "updated_at": "2025-01-15T10:30:00Z"
  }
}
```

**Response (422 Validation Error - Mismatch):**
```json
{
  "success": false,
  "message": "Validation error",
  "errors": {
    "converted_amount": [
      "The converted_amount does not match the calculated value based on exchange_rate."
    ]
  }
}
```

### مثال 3: إنشاء Exchange مع `exchange_rate` فقط (Backward Compatibility)

**Request:**
```json
POST /api/v1/exchanges
Authorization: Bearer {token}
Content-Type: application/json

{
  "target_currency": "SYP",
  "amount_usd": 100.00,
  "exchange_rate": 11600.00,
  "exchange_date": "2025-01-15",
  "notes": "Exchange for daily expenses"
}
```

**Response (Success):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "user_id": 3,
    "transfer_id": null,
    "target_currency": "SYP",
    "amount_usd": 100.00,
    "exchange_rate": 11600.00,
    "converted_amount": 1160000.00,
    "exchange_date": "2025-01-15",
    "notes": "Exchange for daily expenses",
    "created_at": "2025-01-15T10:30:00Z",
    "updated_at": "2025-01-15T10:30:00Z"
  }
}
```

---

## 6. Testing Checklist

### Fund Box with user_id:
- [ ] Admin يمكنه جلب أرصدة User في مجموعته
- [ ] Admin لا يمكنه جلب أرصدة User خارج مجموعته (403)
- [ ] SuperAdmin يمكنه جلب أرصدة أي Admin
- [ ] SuperAdmin لا يمكنه جلب أرصدة User مباشرة (403)
- [ ] User لا يمكنه جلب أرصدة مستخدم آخر (403)
- [ ] إرجاع 404 عندما يكون user_id غير موجود
- [ ] إرجاع fund box للمستخدم الحالي عندما لا يتم توفير user_id

### Exchange with converted_amount:
- [ ] إنشاء exchange مع `converted_amount` فقط
- [ ] إنشاء exchange مع `exchange_rate` فقط (backward compatibility)
- [ ] إنشاء exchange مع كلا الحقلين (validation)
- [ ] إرجاع 422 عندما تكون القيم غير متطابقة
- [ ] إرجاع 422 عندما لا يتم توفير أي من الحقلين
- [ ] حساب `exchange_rate` تلقائياً من `converted_amount`
- [ ] حساب `converted_amount` تلقائياً من `exchange_rate`
- [ ] تضمين `converted_amount` في response

---

## 7. ملاحظات إضافية

### Performance Considerations:
- عند جلب fund box لمستخدمين متعددين (في Group Management)، يجب النظر في إضافة endpoint batch:
  - `GET /api/v1/fund-box/batch?user_ids=1,2,3,4`
- يجب استخدام caching للأرصدة المكلفة حسابياً

### Security Considerations:
- يجب تسجيل (log) جميع محاولات الوصول إلى أرصدة مستخدمين آخرين
- يجب إضافة rate limiting للـ endpoints الحساسة
- يجب التحقق من الصلاحيات في كل request

### Backward Compatibility:
- جميع التغييرات يجب أن تكون backward compatible
- الـ endpoints القديمة يجب أن تستمر في العمل
- إضافة حقول جديدة يجب أن تكون optional

---

## 8. التحديثات على Postman Collection

بعد تطبيق التغييرات في Backend، يجب تحديث Postman Collection لتشمل:

1. **Endpoint جديد: Get Fund Box by User ID**
   - `GET /api/v1/fund-box?user_id={userId}`
   - أمثلة لـ Admin و SuperAdmin tokens

2. **Endpoint محدث: Create Exchange with converted_amount**
   - `POST /api/v1/exchanges` مع `converted_amount` في body
   - أمثلة للـ validation errors

---

## 9. Timeline المقترح

1. **الأسبوع الأول:** تطبيق دعم `user_id` في Fund Box endpoint
2. **الأسبوع الثاني:** تطبيق دعم `converted_amount` في Exchange endpoint
3. **الأسبوع الثالث:** Testing والـ bug fixes
4. **الأسبوع الرابع:** Documentation والـ deployment

---

## 10. الأسئلة الشائعة

### Q: هل يجب إضافة `converted_amount` كحقل في قاعدة البيانات؟
**A:** نعم، يُفضل إضافة الحقل في قاعدة البيانات للـ consistency والـ performance. لكن يمكن حسابه ديناميكياً إذا لزم الأمر.

### Q: ماذا يحدث إذا كان `user_id` يشير إلى المستخدم الحالي؟
**A:** يجب إرجاع fund box للمستخدم الحالي (نفس السلوك كما لو لم يتم توفير `user_id`).

### Q: هل يمكن للـ Admin رؤية أرصدة Admin آخر؟
**A:** لا، Admin يمكنه فقط رؤية أرصدة Users في مجموعته. فقط SuperAdmin يمكنه رؤية أرصدة Admins.

### Q: ماذا يحدث إذا كان `converted_amount` و `exchange_rate` غير متطابقين؟
**A:** يجب إرجاع 422 Validation Error مع رسالة توضح عدم التطابق.

---

**تاريخ الإنشاء:** 2025-01-15  
**آخر تحديث:** 2025-01-15  
**الإصدار:** 1.0

