# Production Monitoring Guide
## Admin Group Management Feature

This guide provides instructions for monitoring the Admin Group Management feature in production.

---

## Table of Contents

1. [Overview](#overview)
2. [Key Metrics](#key-metrics)
3. [Monitoring Tools](#monitoring-tools)
4. [Alert Thresholds](#alert-thresholds)
5. [Dashboard Setup](#dashboard-setup)
6. [Incident Response](#incident-response)

---

## Overview

### Monitoring Objectives

- Ensure feature stability (crash-free rate > 99%)
- Track feature adoption and usage
- Identify and resolve issues quickly
- Maintain optimal performance
- Ensure data integrity

### Monitoring Schedule

**First 24 Hours**: Check every 2-4 hours  
**First Week**: Check daily  
**Ongoing**: Check weekly + automated alerts

---

## Key Metrics

### 1. Stability Metrics

#### Crash-Free Rate
- **Target**: > 99%
- **Warning**: < 99%
- **Critical**: < 97%
- **Source**: Firebase Crashlytics / Play Console

#### ANR (App Not Responding) Rate
- **Target**: < 0.5%
- **Warning**: > 0.5%
- **Critical**: > 1%
- **Source**: Play Console

#### API Error Rate
- **Target**: < 2%
- **Warning**: > 2%
- **Critical**: > 5%
- **Source**: Backend logs / APM

### 2. Adoption Metrics

#### New Admin Registrations
- **Metric**: Count of new admin users
- **Expected**: Steady growth
- **Source**: Backend analytics

#### New User Registrations with Group Code
- **Metric**: Count of users joining with codes
- **Expected**: Higher than admin registrations
- **Source**: Backend analytics

#### Groups Created
- **Metric**: Total active groups
- **Expected**: Matches admin registrations
- **Source**: Database query

#### Users Joined to Groups
- **Metric**: Users successfully joined
- **Expected**: > 90% of user registrations
- **Source**: Backend analytics

### 3. Usage Metrics

#### Group Management Page Views
- **Metric**: Admin page visits
- **Expected**: Regular activity
- **Source**: Firebase Analytics

#### Group Code Copies
- **Metric**: Copy button clicks
- **Expected**: High frequency
- **Source**: Firebase Analytics

#### Member Removals
- **Metric**: Remove member actions
- **Expected**: Low frequency
- **Source**: Backend logs

#### Code Regenerations
- **Metric**: Regenerate code actions
- **Expected**: Very low frequency
- **Source**: Backend logs

### 4. Performance Metrics

#### App Launch Time
- **Target**: < 3 seconds
- **Warning**: > 3 seconds
- **Critical**: > 5 seconds
- **Source**: Firebase Performance

#### Page Load Time (Group Management)
- **Target**: < 1 second
- **Warning**: > 1 second
- **Critical**: > 2 seconds
- **Source**: Firebase Performance

#### API Response Time
- **Target**: < 500ms
- **Warning**: > 500ms
- **Critical**: > 1000ms
- **Source**: Backend APM

#### Member List Load Time
- **Target**: < 1 second
- **Warning**: > 1 second
- **Critical**: > 2 seconds
- **Source**: Firebase Performance

### 5. Data Integrity Metrics

#### Orphaned Users (no group)
- **Target**: 0
- **Warning**: > 0
- **Check**: Daily database query
- **Source**: Database

#### Invalid Group Codes
- **Target**: 0
- **Warning**: > 0
- **Check**: Daily database query
- **Source**: Database

#### Data Scoping Violations
- **Target**: 0
- **Critical**: > 0
- **Check**: Audit logs
- **Source**: Backend logs

---

## Monitoring Tools

### 1. Google Play Console

**Access**: https://play.google.com/console

**What to Monitor**:
- Crash reports
- ANR reports
- User reviews and ratings
- Installation statistics
- Uninstall statistics

**Check Frequency**: Every 4 hours (first 24h), then daily

### 2. Firebase Crashlytics

**Access**: Firebase Console > Crashlytics

**What to Monitor**:
- Crash-free users percentage
- Crash trends
- Top crashes
- Affected users
- Stack traces

**Setup Alerts**:
```dart
// Ensure Crashlytics is initialized
await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

// Log custom events
FirebaseCrashlytics.instance.log('Admin group created');
FirebaseCrashlytics.instance.log('User joined group');
```

**Check Frequency**: Every 2 hours (first 24h), then daily

### 3. Firebase Analytics

**Access**: Firebase Console > Analytics

**Custom Events to Track**:

```dart
// Track group creation
FirebaseAnalytics.instance.logEvent(
  name: 'group_created',
  parameters: {
    'admin_id': adminId,
    'timestamp': DateTime.now().toIso8601String(),
  },
);

// Track user join
FirebaseAnalytics.instance.logEvent(
  name: 'user_joined_group',
  parameters: {
    'user_id': userId,
    'group_code': groupCode,
    'timestamp': DateTime.now().toIso8601String(),
  },
);

// Track member removal
FirebaseAnalytics.instance.logEvent(
  name: 'member_removed',
  parameters: {
    'admin_id': adminId,
    'removed_user_id': removedUserId,
    'timestamp': DateTime.now().toIso8601String(),
  },
);

// Track code regeneration
FirebaseAnalytics.instance.logEvent(
  name: 'code_regenerated',
  parameters: {
    'admin_id': adminId,
    'old_code': oldCode,
    'new_code': newCode,
    'timestamp': DateTime.now().toIso8601String(),
  },
);

// Track group code copy
FirebaseAnalytics.instance.logEvent(
  name: 'group_code_copied',
  parameters: {
    'user_id': userId,
    'group_code': groupCode,
    'timestamp': DateTime.now().toIso8601String(),
  },
);
```

**Check Frequency**: Daily

### 4. Backend Monitoring

**Tools**: Application Performance Monitoring (APM) like New Relic, Datadog, or custom

**What to Monitor**:
- API endpoint response times
- Error rates by endpoint
- Database query performance
- Server resource usage (CPU, memory)
- Request volume

**Key Endpoints**:
- `GET /api/v1/admin/group`
- `POST /api/v1/admin/group/regenerate`
- `GET /api/v1/admin/group/members`
- `DELETE /api/v1/admin/group/members/{id}`
- `POST /api/v1/user/join-group`
- `GET /api/v1/user/group-info`

**Check Frequency**: Every 2 hours (first 24h), then daily

### 5. Database Monitoring

**Queries to Run Daily**:

```sql
-- Count active groups
SELECT COUNT(*) as active_groups 
FROM admin_groups 
WHERE is_active = true;

-- Count users by group
SELECT admin_group_id, COUNT(*) as member_count 
FROM users 
WHERE admin_group_id IS NOT NULL 
GROUP BY admin_group_id;

-- Find orphaned users (no group)
SELECT COUNT(*) as orphaned_users 
FROM users 
WHERE admin_group_id IS NULL 
AND role = 'user';

-- Find duplicate group codes (should be 0)
SELECT group_code, COUNT(*) as count 
FROM admin_groups 
GROUP BY group_code 
HAVING COUNT(*) > 1;

-- Recent group activity
SELECT 
  DATE(created_at) as date,
  COUNT(*) as groups_created 
FROM admin_groups 
WHERE created_at >= NOW() - INTERVAL 7 DAY 
GROUP BY DATE(created_at);
```

---

## Alert Thresholds

### Critical Alerts (Immediate Action Required)

| Metric | Threshold | Action |
|--------|-----------|--------|
| Crash-free rate | < 97% | Investigate immediately, consider rollback |
| API error rate | > 5% | Check backend, investigate errors |
| Data scoping violation | > 0 | Security incident, investigate immediately |
| Backend down | > 1 minute | Escalate to DevOps |
| Database errors | > 10/minute | Escalate to database team |

### Warning Alerts (Action Required Within 1 Hour)

| Metric | Threshold | Action |
|--------|-----------|--------|
| Crash-free rate | < 99% | Investigate crashes |
| API error rate | > 2% | Review error logs |
| Response time | > 1 second | Check performance |
| ANR rate | > 0.5% | Investigate UI blocking |
| Negative reviews | > 5 in 1 hour | Review feedback |

### Info Alerts (Monitor)

| Metric | Threshold | Action |
|--------|-----------|--------|
| Low adoption | < 10% after 1 week | Review marketing |
| High uninstall rate | > 5% | Investigate user feedback |
| Low feature usage | < 50% | Review UX |

---

## Dashboard Setup

### Firebase Dashboard

**Create Custom Dashboard**:

1. Go to Firebase Console > Analytics > Dashboard
2. Click "Create Dashboard"
3. Name: "Admin Group Management"
4. Add cards:
   - Event count: `group_created`
   - Event count: `user_joined_group`
   - Event count: `member_removed`
   - Event count: `code_regenerated`
   - Event count: `group_code_copied`
   - User engagement
   - Crash-free users

### Play Console Dashboard

**Monitor**:
1. Go to Play Console > Dashboard
2. Check:
   - Crashes & ANRs
   - User reviews
   - Installation metrics
   - Uninstall metrics

### Backend Dashboard

**Create Monitoring Dashboard** (example using Grafana):

```yaml
# Example Grafana dashboard config
dashboard:
  title: "Admin Group Management API"
  panels:
    - title: "API Response Time"
      type: "graph"
      targets:
        - expr: "http_request_duration_seconds{endpoint=~'/api/v1/(admin|user)/.*'}"
    
    - title: "API Error Rate"
      type: "graph"
      targets:
        - expr: "rate(http_requests_total{status=~'5..'}[5m])"
    
    - title: "Groups Created (24h)"
      type: "stat"
      targets:
        - query: "SELECT COUNT(*) FROM admin_groups WHERE created_at > NOW() - INTERVAL 1 DAY"
    
    - title: "Users Joined (24h)"
      type: "stat"
      targets:
        - query: "SELECT COUNT(*) FROM users WHERE admin_group_id IS NOT NULL AND created_at > NOW() - INTERVAL 1 DAY"
```

---

## Incident Response

### Severity Levels

#### P0 - Critical (Immediate Response)
- App completely broken
- Data loss or corruption
- Security breach
- Crash rate > 10%

**Response Time**: Immediate  
**Escalation**: CTO, Engineering Lead

#### P1 - High (Response Within 1 Hour)
- Major feature broken
- Crash rate 3-10%
- API errors > 5%
- Data scoping issues

**Response Time**: < 1 hour  
**Escalation**: Engineering Lead

#### P2 - Medium (Response Within 4 Hours)
- Minor feature issues
- Crash rate 1-3%
- Performance degradation
- UI issues

**Response Time**: < 4 hours  
**Escalation**: Team Lead

#### P3 - Low (Response Within 24 Hours)
- Cosmetic issues
- Minor bugs
- Enhancement requests

**Response Time**: < 24 hours  
**Escalation**: None

### Incident Response Process

1. **Detect**: Alert triggered or issue reported
2. **Assess**: Determine severity level
3. **Notify**: Alert appropriate team members
4. **Investigate**: Identify root cause
5. **Mitigate**: Implement temporary fix or rollback
6. **Resolve**: Deploy permanent fix
7. **Document**: Create incident report
8. **Review**: Post-mortem meeting

### Rollback Procedure

**When to Rollback**:
- Crash rate > 5%
- Critical security issue
- Data integrity problems
- Complete feature failure

**How to Rollback**:

1. **Immediate**: Halt rollout in Play Console
   ```
   Play Console > Production > Halt rollout
   ```

2. **Quick**: Deploy previous version
   ```
   Play Console > Create new release > Upload previous AAB > 100% rollout
   ```

3. **Hotfix**: Fix and redeploy
   ```
   Fix bug > Bump build number > Build > Test > Deploy
   ```

### Communication Template

**For Critical Issues**:

```
Subject: [CRITICAL] Admin Group Management Issue - [Brief Description]

Status: Investigating / Mitigating / Resolved
Severity: P0 / P1 / P2 / P3
Impact: [Number] users affected
Started: [Time]

Issue:
[Description of the problem]

Impact:
[What users are experiencing]

Current Status:
[What we're doing about it]

ETA for Resolution:
[Estimated time]

Next Update:
[When we'll provide next update]

Contact:
[On-call engineer contact]
```

---

## Monitoring Checklist

### Daily Checks (First Week)

- [ ] Check crash-free rate in Crashlytics
- [ ] Review top crashes
- [ ] Check ANR rate in Play Console
- [ ] Review user reviews and ratings
- [ ] Check API error rate
- [ ] Review backend logs for errors
- [ ] Check adoption metrics
- [ ] Run database integrity queries
- [ ] Review support tickets

### Weekly Checks (Ongoing)

- [ ] Review weekly metrics summary
- [ ] Check adoption trends
- [ ] Review performance metrics
- [ ] Analyze user feedback
- [ ] Check for security issues
- [ ] Review database health
- [ ] Update monitoring dashboard
- [ ] Team sync on metrics

### Monthly Checks

- [ ] Comprehensive metrics review
- [ ] Feature adoption analysis
- [ ] Performance optimization review
- [ ] User satisfaction survey
- [ ] Security audit
- [ ] Documentation updates
- [ ] Monitoring improvements

---

## Metrics Report Template

### Weekly Metrics Report

```markdown
# Admin Group Management - Weekly Metrics Report
Week of: [Date Range]

## Stability
- Crash-free rate: _____% (Target: > 99%)
- Total crashes: _____
- ANR rate: _____% (Target: < 0.5%)
- API error rate: _____% (Target: < 2%)

## Adoption
- New admin registrations: _____
- New user registrations: _____
- Groups created: _____
- Users joined: _____
- Total active groups: _____

## Usage
- Group management page views: _____
- Group code copies: _____
- Member removals: _____
- Code regenerations: _____

## Performance
- Avg app launch time: _____s (Target: < 3s)
- Avg page load time: _____s (Target: < 1s)
- Avg API response time: _____ms (Target: < 500ms)

## User Feedback
- User reviews: _____ (Avg rating: _____)
- Support tickets: _____
- Feature requests: _____

## Issues
- Critical issues: _____
- High priority issues: _____
- Medium priority issues: _____
- Low priority issues: _____

## Action Items
1. _____
2. _____
3. _____

## Notes
_____
```

---

## Contact Information

### On-Call Rotation

| Week | Primary | Secondary |
|------|---------|-----------|
| Week 1 | [Name] | [Name] |
| Week 2 | [Name] | [Name] |
| Week 3 | [Name] | [Name] |
| Week 4 | [Name] | [Name] |

### Escalation Contacts

- **Engineering Lead**: [Email] / [Phone]
- **DevOps**: [Email] / [Phone]
- **Database Admin**: [Email] / [Phone]
- **Product Owner**: [Email] / [Phone]
- **CTO**: [Email] / [Phone]

---

## Tools and Resources

### Monitoring Tools
- Firebase Console: https://console.firebase.google.com
- Play Console: https://play.google.com/console
- Backend APM: [Your APM URL]
- Database Dashboard: [Your DB dashboard URL]

### Documentation
- User Guide: [Link]
- API Documentation: [Link]
- Troubleshooting Guide: [Link]
- Incident Response Playbook: [Link]

### Communication Channels
- Slack: #admin-group-monitoring
- Email: monitoring@financeapp.com
- PagerDuty: [Link]

---

**Document Version**: 1.0  
**Last Updated**: November 1, 2025  
**Next Review**: December 1, 2025
