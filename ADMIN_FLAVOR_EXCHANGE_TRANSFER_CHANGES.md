# Admin Flavor - Exchange & Transfer Changes

## Summary
Made UI improvements for the admin flavor only:
1. Removed Exchange button from bottom navigation bar
2. Added Exchange button to Cash page (both Incoming and Outgoing tabs)
3. Modified Transfer dialog to use dropdown for group members
4. Removed the 3 exchange-related text fields from Transfer dialog

## Changes Made

### 1. Main Navigation (lib/main.dart)
- **Removed Exchange from bottom navigation bar (admin flavor only)**
  - Exchange History page is now only shown in user flavor
  - Admin users access Exchange through the Cash page instead
  
### 2. Cash Page (lib/ui/cash_inbox_page.dart)

#### Added Imports:
- `AdminGroupBloc`, `AdminGroupEvent`, `AdminGroupState`
- `GroupMember` entity
- `FlavorConfig` for flavor detection

#### Added Exchange Button to Both Tabs:
- **Outgoing Tab**: Added "Exchange History" button next to "Transfer" button
- **Incoming Tab**: Added "Exchange History" button next to "Add Incoming" button
- Both buttons navigate to `/exchange-history` route

#### Modified Transfer Dialog:
**Before:**
- Text field for recipient name
- Amount field
- Transaction date picker
- 3 exchange-related fields:
  - Converted Amount (USD)
  - Exchange Rate
  - Converted Total (SYP)

**After (Admin Flavor):**
- **Dropdown menu** for recipient (populated with group members)
- Amount field
- Transaction date picker
- Removed all 3 exchange-related fields

**After (User Flavor):**
- Text field for recipient name (unchanged)
- Amount field
- Transaction date picker
- Removed all 3 exchange-related fields

#### Implementation Details:
- On dialog open, loads group members using `AdminGroupBloc`
- Dropdown shows all group members by name
- Falls back to text field if no members are loaded or in user flavor
- Simplified transfer creation (no exchange calculations)

## Testing Checklist

### Admin Flavor:
- [ ] Exchange button NOT visible in bottom navigation bar
- [ ] Exchange button visible in Cash page - Outgoing tab
- [ ] Exchange button visible in Cash page - Incoming tab
- [ ] Clicking Exchange button navigates to Exchange History page
- [ ] Transfer dialog shows dropdown with group members
- [ ] Transfer dialog does NOT show exchange-related fields
- [ ] Can create transfer by selecting member from dropdown

### User Flavor:
- [ ] Exchange button still visible in bottom navigation bar
- [ ] Cash page does NOT show Exchange buttons (user flavor doesn't have cash module)
- [ ] Transfer functionality unchanged (if applicable)

## Files Modified
1. `lib/main.dart` - Navigation configuration
2. `lib/ui/cash_inbox_page.dart` - Cash page UI and transfer dialog

## Notes
- Changes are flavor-aware and only affect admin flavor
- User flavor remains unchanged
- Group members are loaded dynamically when opening transfer dialog
- Exchange functionality moved to dedicated Exchange History page
- Transfer dialog simplified by removing exchange calculations
