# Export Feature Quick Guide

## Admin Flavor - Export Page Features

### 🎯 Quick Overview

The export page now supports:
1. ✅ Filter-aware expense exports (PDF, Excel, Invoices)
2. ✅ Combined exchange & expense export
3. ✅ Synchronized filters across pages
4. ✅ Validation to ensure data consistency

---

## 📋 Step-by-Step Guide

### Export Expenses for a Specific User

1. Go to **Expenses** page
2. Select user from dropdown filter
3. Go to **Export** page
4. Click any expense export button (PDF/Excel/Invoices)
5. ✅ Only that user's expenses will be exported

### Export Exchanges & Expenses for a User

1. Go to **Exchange History** page
2. Select recipient from dropdown filter
3. Go to **Expenses** page  
4. Select the **same user** from dropdown filter
5. Go to **Export** page
6. Verify both filters show the same user
7. Click **"Export Exchanges & Expenses"** (green button)
8. ✅ Excel file with both sheets will be generated

---

## ⚠️ Important Rules

### Combined Export Validation

The system will show an error if:
- ❌ No recipient selected for exchanges
- ❌ No user selected for expenses
- ❌ Different users selected in each filter

**Error Message (Arabic):**
> يجب أن تختار نفس المستخدم لسجل الصرافة والمصاريف حتى يتم تصدير الملف

**Error Message (English):**
> You must select the same user for exchange history and expenses to export the file

---

## 📊 Export File Structure

### Combined Export File: `user_[username]_data.xlsx`

#### Sheet 1: Exchanges
| التاريخ | المبلغ بالدولار | سعر الصرف | المبلغ بالليرة السورية | المستلم | ملاحظات |
|---------|----------------|-----------|----------------------|---------|---------|
| Data... | Data...        | Data...   | Data...              | Data... | Data... |
| **الإجمالي** | **Total USD** | | **Total SYP** | | |

#### Sheet 2: Expenses
| الوصف | دولار | ليرة سورية | ليرة تركية | فاتورة |
|-------|-------|-----------|-----------|--------|
| Data... | Data... | Data... | Data... | Data... |
| **الإجمالي** | **Total USD** | **Total SYP** | **Total TRY** | |

---

## 🔄 Filter Synchronization

Filters are **automatically synchronized** between pages:

```
Exchange History Page → Recipient Filter
         ↓
    (Synchronized)
         ↓
Export Page → Shows both filters
         ↓
    (Synchronized)
         ↓
Expense Page → User Filter
```

**Benefit**: Select filters once, use everywhere!

---

## 💡 Tips

1. **Check filters before exporting**: The export page shows current filter selections
2. **Use combined export for complete user reports**: Get all data in one file
3. **Clear filters to export all data**: Set both filters to "All Users"
4. **File naming**: Combined exports are named `user_[username]_data.xlsx`

---

## 🐛 Troubleshooting

### Problem: Can't see recipient dropdown in Exchange History
**Solution**: Make sure you're using admin flavor and group members are loaded

### Problem: Export button is disabled
**Solution**: Wait for any ongoing export to complete

### Problem: Error when clicking combined export
**Solution**: Check that both filters are set to the same user

### Problem: Filters not showing in Export page
**Solution**: Only available in admin flavor, not user flavor

---

## 📱 UI Elements

### Exchange History Page
- **Filter Label**: "Filter by Recipient" / "تصفية حسب المستلم"
- **Dropdown**: Shows all group members

### Expense Page  
- **Filter Label**: "Filter by User" / "تصفية حسب المستخدم"
- **Dropdown**: Shows all group members

### Export Page
- **Section 1**: Filters (shows current selections)
- **Section 2**: Expense exports (PDF, Excel, Invoices)
- **Section 3**: Combined export (green button)

---

## 🎨 Visual Indicators

- 🟢 **Green Button**: Combined export (Exchanges & Expenses)
- 🔵 **Blue Buttons**: Individual expense exports
- 🔴 **Red Error**: Validation failed (filters don't match)
- ⚪ **Gray Text**: Informational notes

---

## 📝 Example Workflow

```
1. Admin wants to export all data for user "Ahmad"

2. Steps:
   ├─ Go to Exchange History
   ├─ Select "Ahmad" from recipient filter
   ├─ Go to Expenses  
   ├─ Select "Ahmad" from user filter
   ├─ Go to Export
   ├─ Verify both filters show "Ahmad"
   └─ Click "Export Exchanges & Expenses"

3. Result:
   └─ File: user_Ahmad_data.xlsx
      ├─ Exchanges sheet (Ahmad's exchanges)
      └─ Expenses sheet (Ahmad's expenses)
```

---

## 🔐 Permissions

- ✅ **Admin Flavor**: All features available
- ❌ **User Flavor**: Combined export not available

---

## 📞 Support

If you encounter issues:
1. Check that you're using the admin flavor
2. Verify group members are loaded
3. Ensure filters are set correctly
4. Check console for error messages
