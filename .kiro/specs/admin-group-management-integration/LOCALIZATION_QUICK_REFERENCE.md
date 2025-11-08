# Admin Group Localization - Quick Reference

## How to Use Translations

### Basic Usage
```dart
import 'package:finance_app/l10n/app_localizations.dart';

// In your widget
final l10n = AppLocalizations.of(context);

Text(l10n.adminGroupCode ?? 'Group Code')
```

## Available Translation Keys

### Labels & Titles
| Getter | English | Arabic |
|--------|---------|--------|
| `adminGroupCode` | Group Code | رمز المجموعة |
| `adminGroupName` | Group Name | اسم المجموعة |
| `adminGroupMembersCount` | Members | الأعضاء |
| `adminGroupManagement` | Group Management | إدارة المجموعة |
| `adminGroupMyGroup` | My Group | مجموعتي |

### Actions
| Getter | English | Arabic |
|--------|---------|--------|
| `adminGroupCopyCode` | Copy | نسخ |
| `adminGroupCopied` | Copied! | تم النسخ! |
| `adminGroupRegenerateCode` | Regenerate | إعادة إنشاء |
| `adminGroupRemoveMember` | Remove | إزالة |
| `adminGroupJoinGroup` | Join Group | الانضمام للمجموعة |

### Input Fields
| Getter | English | Arabic |
|--------|---------|--------|
| `adminGroupEnterCode` | Enter group code | أدخل رمز المجموعة |
| `adminGroupCodeHint` | 6 characters | 6 أحرف |
| `adminGroupSearchMembers` | Search members... | البحث عن الأعضاء... |

### Instructions
| Getter | English | Arabic |
|--------|---------|--------|
| `adminGroupGetFromAdmin` | Get this code from your admin | احصل على هذا من المسؤول |
| `adminGroupShareWithTeam` | Share this code with your team members | شارك هذا الرمز مع أعضاء فريقك |
| `adminGroupJoinInstructions` | Enter the 6-character group code... | أدخل رمز المجموعة المكون من 6 أحرف... |

### Validation Messages
| Getter | English | Arabic |
|--------|---------|--------|
| `adminGroupCodeRequired` | Group code is required | رمز المجموعة مطلوب |
| `adminGroupCodeTooShort` | Code must be 6 characters | يجب أن يكون الرمز 6 أحرف |
| `adminGroupCodeTooLong` | Code must be exactly 6 characters | يجب أن يكون الرمز 6 أحرف بالضبط |
| `adminGroupCodeInvalidChars` | Code must contain only letters and numbers | يجب أن يحتوي الرمز على أحرف وأرقام فقط |

### Success Messages
| Getter | English | Arabic |
|--------|---------|--------|
| `adminGroupCodeCopied` | Group code copied to clipboard | تم نسخ رمز المجموعة |
| `adminGroupMemberRemoved` | Member removed successfully | تمت إزالة العضو بنجاح |
| `adminGroupCodeRegenerated` | Group code regenerated successfully | تم إعادة إنشاء رمز المجموعة بنجاح |
| `adminGroupJoinedGroup` | Successfully joined the group | تم الانضمام للمجموعة بنجاح |

### Error Messages
| Getter | English | Arabic |
|--------|---------|--------|
| `adminGroupInvalidCode` | The selected group code is invalid | رمز المجموعة المحدد غير صالح |
| `adminGroupAlreadyInGroup` | You are already in a group | أنت بالفعل في مجموعة |
| `adminGroupAdminCannotJoin` | Admins cannot join other groups | لا يمكن للمسؤولين الانضمام لمجموعات أخرى |
| `adminGroupMemberNotFound` | User not found or not in your group | المستخدم غير موجود أو ليس في مجموعتك |

### Filters & Search
| Getter | English | Arabic |
|--------|---------|--------|
| `adminGroupFilterByDepartment` | Filter by Department | تصفية حسب القسم |
| `adminGroupAllDepartments` | All Departments | جميع الأقسام |
| `adminGroupClearFilters` | Clear Filters | مسح الفلاتر |

### Empty States
| Getter | English | Arabic |
|--------|---------|--------|
| `adminGroupNoMembersFound` | No members found matching your filters | لم يتم العثور على أعضاء مطابقين للفلاتر |
| `adminGroupNoMembersYet` | No members in this group yet | لا يوجد أعضاء في هذه المجموعة بعد |
| `adminGroupLoadingMembers` | Loading members... | جاري تحميل الأعضاء... |

### Confirmations
| Getter | English | Arabic |
|--------|---------|--------|
| `adminGroupConfirmRemove` | Are you sure you want to remove this member? | هل أنت متأكد من إزالة هذا العضو؟ |
| `adminGroupConfirmRemoveTitle` | Remove Member | إزالة عضو |
| `adminGroupConfirmRegenerate` | Regenerating will invalidate the old code. Continue? | إعادة الإنشاء ستلغي الرمز القديم. هل تريد المتابعة؟ |

## Common Patterns

### Form Validation
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: l10n.adminGroupCode,
    hintText: l10n.adminGroupCodeHint,
  ),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return l10n.adminGroupCodeRequired;
    }
    if (value.length < 6) {
      return l10n.adminGroupCodeTooShort;
    }
    if (value.length > 6) {
      return l10n.adminGroupCodeTooLong;
    }
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
      return l10n.adminGroupCodeInvalidChars;
    }
    return null;
  },
)
```

### Success Snackbar
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(l10n.adminGroupCodeCopied ?? 'Code copied'),
    backgroundColor: Colors.green,
  ),
);
```

### Error Dialog
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Error'),
    content: Text(l10n.adminGroupInvalidCode ?? 'Invalid code'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('OK'),
      ),
    ],
  ),
);
```

### Confirmation Dialog
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(l10n.adminGroupConfirmRemoveTitle ?? 'Remove Member'),
    content: Text(l10n.adminGroupConfirmRemove ?? 'Are you sure?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text(l10n.cancel ?? 'Cancel'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text(l10n.adminGroupRemoveMember ?? 'Remove'),
      ),
    ],
  ),
);
```

## Tips

1. **Always provide fallback text**: Use the null-aware operator `??` with a default English string
2. **Test both languages**: Switch between English and Arabic to verify translations
3. **Check RTL layout**: Arabic text should flow right-to-left properly
4. **Use consistent terminology**: Follow the established translation patterns
5. **Keep translations concise**: Mobile screens have limited space

## Language Switching

Users can switch languages through the app settings. The app will automatically use the appropriate translations based on the selected locale.

```dart
// Current locale
final currentLocale = Localizations.localeOf(context);

// Check if Arabic
final isArabic = currentLocale.languageCode == 'ar';
```
