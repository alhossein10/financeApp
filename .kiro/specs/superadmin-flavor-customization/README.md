# SuperAdmin Flavor Customization Spec

## Overview

This spec defines the customization of the SuperAdmin flavor to provide a distinct user experience tailored for SuperAdmin users who manage multiple admin groups.

## Key Features

1. **Group Code Generation After Registration** - SuperAdmins receive a unique group code immediately after registration to share with admins
2. **Unified Cash Page** - Single page combining fund box and outgoing transfers (no incoming transfers or exchange history)
3. **Exchange Page Removal** - Currency exchange page (تصريف) removed from SuperAdmin interface
4. **Aggregated Expense Monitoring** - View expense status from all admin groups (read-only, no expense creation)
5. **Export Page Removal** - Export functionality removed from SuperAdmin interface
6. **Exchange History Removal** - Exchange history page removed from SuperAdmin interface
7. **Simplified Navigation** - Only 4 navigation items: Group Management, Cash, Expenses, Profile

## Documents

- **requirements.md** - Detailed requirements with EARS-compliant acceptance criteria
- **design.md** - Technical design including architecture, components, data models, and testing strategy
- **tasks.md** - Implementation plan with 12 main tasks and 30+ sub-tasks

## Implementation Status

- [x] Requirements defined
- [x] Design completed
- [x] Tasks planned
- [ ] Implementation in progress

## Quick Start

To begin implementing this spec:

1. Review the requirements document to understand all acceptance criteria
2. Study the design document for technical architecture and component details
3. Open `tasks.md` and start with Task 1: Update FlavorConfig for SuperAdmin
4. Execute tasks sequentially, marking them complete as you go
5. Optional testing and documentation tasks can be done after core features

## Navigation Structure

**SuperAdmin Navigation** (4 items):
1. Group Management - Manage admin groups and members
2. Cash (النقد) - Fund box + outgoing transfers only
3. Expenses - Aggregated expense status from all admin groups
4. Profile - User profile and settings

**Removed from SuperAdmin**:
- Currency Exchange (تصريف)
- Export Page
- Exchange History
- User Cash Inbox (incoming transfers)

## Testing Approach

Core implementation tasks (1-8) are required for MVP. Testing tasks (9-11) and documentation (12) are marked as optional for faster delivery but recommended for production quality.

## Backend Requirements

The following API endpoints need to be implemented by the backend team:

1. **Registration Response Enhancement**
   - Include `groupCode` and `adminGroupName` in SuperAdmin registration response

2. **Expense Summary Endpoints**
   - `GET /api/superadmin/expenses/summary` - Get aggregated expense data for all admin groups
   - `GET /api/superadmin/expenses/by-group/{groupId}` - Get detailed expenses for a specific admin group

3. **Transfer Filtering**
   - Existing transfer endpoints should support filtering by type (incoming/outgoing)

## Notes

- This spec builds on existing admin-group-management-integration features
- Reuses existing components where possible (GroupCodeDisplay, FundBoxBloc, TransferBloc, etc.)
- No database schema changes required
- All changes are UI/UX focused with some API integration
- Maintains backward compatibility with Admin and User flavors
