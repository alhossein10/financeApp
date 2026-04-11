# User Group Information - Flow Diagrams

## Overview
Visual representation of the User Group Information feature flows.

---

## 1. Join Group Flow

```mermaid
graph TD
    A[User Opens Profile] --> B{Has Group?}
    B -->|No| C[Show Warning Message]
    C --> D[Click 'Join a Group' Button]
    D --> E[Navigate to Join Group Page]
    E --> F[Enter 6-Character Code]
    F --> G{Valid Format?}
    G -->|No| H[Show Validation Error]
    H --> F
    G -->|Yes| I[Enable Submit Button]
    I --> J[Click Submit]
    J --> K[Show Loading State]
    K --> L[API Call: POST /user/join-group]
    L --> M{Success?}
    M -->|Yes| N[Show Success Message]
    N --> O[Navigate to Group Info Page]
    O --> P[Display Group Information]
    M -->|No| Q{Error Type?}
    Q -->|Invalid Code| R[Show 'Invalid Code' Error]
    Q -->|Already in Group| S[Show 'Already in Group' Error]
    Q -->|Other| T[Show Generic Error]
    R --> F
    S --> U[End]
    T --> F
    B -->|Yes| V[Show 'My Group' Button]
    V --> W[Click Button]
    W --> O
```

---

## 2. View Group Info Flow

```mermaid
graph TD
    A[User Opens Profile] --> B{Has Group?}
    B -->|Yes| C[Click 'My Group' Button]
    C --> D[Navigate to Group Info Page]
    D --> E[Show Loading State]
    E --> F[API Call: GET /user/group-info]
    F --> G{Success?}
    G -->|Yes| H[Display Group Information]
    H --> I[Show Group Code]
    H --> J[Show Group Name]
    H --> K[Show Admin Details]
    H --> L[Show Member Count]
    H --> M[Show Join Date]
    H --> N[Enable Refresh]
    N --> O[Pull to Refresh]
    O --> F
    G -->|No| P{Error Type?}
    P -->|Not in Group| Q[Show 'Not in Group' State]
    Q --> R[Show Join Group Button]
    R --> S[Navigate to Join Group Page]
    P -->|Other| T[Show Error State]
    T --> U[Show Retry Button]
    U --> F
    B -->|No| V[Show 'Join a Group' Button]
    V --> S
```

---

## 3. Group Code Validation Flow

```mermaid
graph TD
    A[User Types in Code Input] --> B[Convert to Uppercase]
    B --> C{Length Check}
    C -->|< 6| D[Show 'Too Short' Warning]
    C -->|> 6| E[Show 'Too Long' Error]
    C -->|= 6| F{Character Check}
    F -->|Invalid Chars| G[Show 'Invalid Characters' Error]
    F -->|Valid| H[Show Green Checkmarks]
    H --> I[Enable Submit Button]
    D --> J[Continue Typing]
    E --> K[Prevent Further Input]
    G --> J
    J --> C
```

---

## 4. API Error Handling Flow

```mermaid
graph TD
    A[API Call Made] --> B{Response Status}
    B -->|200/201| C[Parse Response]
    C --> D{Has 'data' Key?}
    D -->|Yes| E[Extract Nested Data]
    D -->|No| F[Use Direct Data]
    E --> G[Transform to DTO]
    F --> G
    G --> H[Return GroupInfoDto]
    B -->|400| I[Already in Group Error]
    I --> J[Show User-Friendly Message]
    B -->|404| K[Not in Group Error]
    K --> L[Redirect to Join Page]
    B -->|422| M[Invalid Code Error]
    M --> N[Show Validation Message]
    B -->|500| O[Server Error]
    O --> P[Show Retry Option]
    B -->|Network Error| Q[Connection Error]
    Q --> R[Show Offline Message]
```

---

## 5. Profile Integration Flow

```mermaid
graph TD
    A[Profile Page Loads] --> B[Load User Data]
    B --> C{Check adminGroupId}
    C -->|null| D[User NOT in Group]
    C -->|has value| E[User IN Group]
    D --> F[Show Warning Container]
    F --> G[Display Warning Icon]
    F --> H[Display Warning Text]
    F --> I[Show 'Join a Group' Button]
    I --> J[Navigate to Join Group Page]
    E --> K[Show 'My Group' Button]
    K --> L[Navigate to Group Info Page]
```

---

## 6. State Management Flow

```mermaid
graph TD
    A[User Action] --> B{Action Type}
    B -->|Join Group| C[Dispatch JoinGroupEvent]
    B -->|Load Info| D[Dispatch LoadUserGroupInfoEvent]
    B -->|Copy Code| E[Dispatch CopyGroupCodeEvent]
    C --> F[AdminGroupBloc]
    D --> F
    E --> F
    F --> G[Process Event]
    G --> H{Event Handler}
    H -->|Join| I[Call API: joinGroup]
    H -->|Load| J[Call API: getUserGroupInfo]
    H -->|Copy| K[Copy to Clipboard]
    I --> L{API Result}
    J --> L
    K --> M[Emit Success State]
    L -->|Success| N[Emit GroupJoined State]
    L -->|Error| O[Emit AdminGroupError State]
    N --> P[UI Updates]
    O --> P
    M --> P
    P --> Q[Show Feedback to User]
```

---

## 7. Complete User Journey

```mermaid
graph TD
    A[New User Registers] --> B[Login to App]
    B --> C[Navigate to Profile]
    C --> D[See 'Not in Group' Warning]
    D --> E[Click 'Join a Group']
    E --> F[Enter Code from Admin]
    F --> G[Validate Code Format]
    G --> H{Valid?}
    H -->|No| I[Fix Code]
    I --> F
    H -->|Yes| J[Submit Code]
    J --> K[API Verification]
    K --> L{Verified?}
    L -->|No| M[Show Error]
    M --> N{Retry?}
    N -->|Yes| F
    N -->|No| O[Exit]
    L -->|Yes| P[Join Successful]
    P --> Q[Navigate to Group Info]
    Q --> R[View Group Details]
    R --> S[See Admin Contact]
    R --> T[See Member Count]
    R --> U[See Join Date]
    R --> V[Copy Group Code]
    V --> W[Share with Others]
    R --> X[Return to Profile]
    X --> Y[Now Shows 'My Group' Button]
    Y --> Z[Can Access Group Info Anytime]
```

---

## 8. Error Recovery Flow

```mermaid
graph TD
    A[Error Occurs] --> B{Error Type}
    B -->|Validation| C[Show Inline Error]
    C --> D[User Corrects Input]
    D --> E[Retry Automatically]
    B -->|API Error| F[Show Error Message]
    F --> G[Show Retry Button]
    G --> H[User Clicks Retry]
    H --> I[Retry API Call]
    B -->|Network Error| J[Show Offline Message]
    J --> K[Wait for Connection]
    K --> L{Connected?}
    L -->|Yes| M[Auto Retry]
    L -->|No| N[Keep Waiting]
    N --> K
    B -->|Already in Group| O[Show Info Message]
    O --> P[Navigate to Group Info]
    B -->|Not in Group| Q[Show Empty State]
    Q --> R[Navigate to Join Page]
```

---

## 9. Data Transformation Flow

```mermaid
graph TD
    A[API Response Received] --> B{Response Structure}
    B -->|Nested| C[Extract 'data' Object]
    B -->|Flat| D[Use Direct Object]
    C --> E{Has 'group' Key?}
    E -->|Yes| F[Extract Group Object]
    E -->|No| G[Use Data Object]
    F --> H[Transform Fields]
    G --> H
    D --> H
    H --> I[Map group_code]
    H --> J[Map group_name]
    H --> K[Map admin Details]
    H --> L[Map members_count]
    H --> M[Map joined_at]
    I --> N[Create GroupInfoDto]
    J --> N
    K --> N
    L --> N
    M --> N
    N --> O[Return to Caller]
```

---

## 10. UI Component Hierarchy

```mermaid
graph TD
    A[Profile Page] --> B[User Info Section]
    A --> C[Group Status Section]
    C --> D{Has Group?}
    D -->|No| E[Warning Container]
    E --> F[Warning Icon]
    E --> G[Warning Text]
    E --> H[Join Group Button]
    H --> I[Join Group Page]
    I --> J[Join Group Form]
    J --> K[Group Code Input]
    J --> L[Submit Button]
    J --> M[Help Text]
    D -->|Yes| N[My Group Button]
    N --> O[Group Info Page]
    O --> P[Group Code Display]
    O --> Q[Group Info Card]
    Q --> R[Group Name]
    Q --> S[Admin Details]
    Q --> T[Member Count]
    Q --> U[Join Date]
    O --> V[Help Container]
```

---

## Key Interaction Points

### 1. Profile Page
- **Entry Point:** User navigates to profile
- **Decision Point:** Check if user has `adminGroupId`
- **Actions:** Show appropriate button (My Group or Join Group)

### 2. Join Group Page
- **Entry Point:** User clicks "Join a Group" button
- **Input:** 6-character group code
- **Validation:** Real-time format checking
- **Submission:** API call to join group
- **Success:** Navigate to Group Info page
- **Error:** Show error message and allow retry

### 3. Group Info Page
- **Entry Point:** User clicks "My Group" button or after successful join
- **Loading:** Fetch group information from API
- **Display:** Show all group details
- **Actions:** Refresh, copy code
- **Error:** Show error state with retry option

---

## State Transitions

```
Initial State
    ↓
[User Not in Group]
    ↓
User Clicks "Join Group"
    ↓
[Join Group Page]
    ↓
User Enters Code
    ↓
[Validating Code]
    ↓
User Submits
    ↓
[Loading - API Call]
    ↓
    ├─→ [Success] → [Group Joined] → [Group Info Page]
    └─→ [Error] → [Show Error] → [Retry or Exit]
```

---

## Navigation Map

```
Profile Page
    ├─→ Join Group Page (if not in group)
    │       └─→ Group Info Page (on success)
    └─→ Group Info Page (if in group)
            └─→ Profile Page (back button)
```

---

## Validation States

```
Empty Input
    ↓
User Types
    ↓
    ├─→ Length < 6: Show "Too Short" Warning
    ├─→ Length > 6: Prevent Input
    ├─→ Invalid Chars: Show "Invalid Characters" Error
    └─→ Length = 6 & Valid Chars: Show Success Indicators
```

---

## Error Handling Matrix

| Error Code | User Message | Action | Recovery |
|-----------|--------------|--------|----------|
| 400 | Already in a group | Show info | Navigate to group info |
| 404 | Not in any group | Show empty state | Navigate to join page |
| 422 | Invalid group code | Show error | Allow retry |
| 500 | Server error | Show error | Retry button |
| Network | Connection error | Show offline | Auto-retry on reconnect |

---

## Success Indicators

### Visual Feedback
1. ✅ Green checkmarks for valid requirements
2. 🔄 Loading spinner during API calls
3. ✔️ Success message after joining
4. 📋 Copy confirmation for group code

### State Changes
1. Button text changes (Join → My Group)
2. Warning disappears
3. Group info becomes accessible
4. Profile updates with group data

---

**Last Updated:** 2024
**Version:** 1.0
**Status:** Complete
