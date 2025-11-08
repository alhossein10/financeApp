#!/bin/bash

###############################################################################
# Admin Group Management - Rollback Script
###############################################################################
#
# This script automates the rollback of the Admin Group Management feature.
# 
# IMPORTANT: Review docs/ADMIN_GROUP_ROLLBACK_GUIDE.md before running!
#
# Usage: ./scripts/rollback_admin_groups.sh [--skip-backup] [--force]
#
# Options:
#   --skip-backup    Skip database backup (NOT RECOMMENDED)
#   --force          Skip confirmation prompts
#
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SKIP_BACKUP=false
FORCE=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --skip-backup)
            SKIP_BACKUP=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Usage: $0 [--skip-backup] [--force]"
            exit 1
            ;;
    esac
done

###############################################################################
# Functions
###############################################################################

print_header() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
}

print_error() {
    echo -e "${RED}❌ ERROR: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

confirm() {
    if [ "$FORCE" = true ]; then
        return 0
    fi
    
    read -p "$1 (yes/no): " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

###############################################################################
# Pre-flight Checks
###############################################################################

print_header "Admin Group Rollback - Pre-flight Checks"

# Check if Laravel is installed
if [ ! -f "artisan" ]; then
    print_error "artisan file not found. Are you in the Laravel root directory?"
    exit 1
fi

# Check if .env exists
if [ ! -f ".env" ]; then
    print_error ".env file not found"
    exit 1
fi

print_success "Pre-flight checks passed"

###############################################################################
# Warning and Confirmation
###############################################################################

echo ""
print_warning "This script will rollback the Admin Group Management feature"
print_warning "The following data will be PERMANENTLY DELETED:"
echo "  - All admin groups and group codes"
echo "  - All user group assignments"
echo "  - Organization and department text fields"
echo ""
print_warning "Please ensure you have:"
echo "  1. Read docs/ADMIN_GROUP_ROLLBACK_GUIDE.md"
echo "  2. Scheduled a maintenance window"
echo "  3. Notified all users"
echo "  4. Tested this process in staging"
echo ""

if ! confirm "Do you want to proceed with the rollback?"; then
    echo "Rollback cancelled"
    exit 0
fi

###############################################################################
# Step 1: Create Backup
###############################################################################

if [ "$SKIP_BACKUP" = false ]; then
    print_header "Step 1: Creating Database Backup"
    
    mkdir -p "$BACKUP_DIR"
    
    echo "Creating database backup..."
    php artisan db:backup --path="$BACKUP_DIR/db_backup_$TIMESTAMP.sql" 2>/dev/null || {
        print_warning "db:backup command not available, using mysqldump"
        
        # Extract database credentials from .env
        DB_DATABASE=$(grep DB_DATABASE .env | cut -d '=' -f2)
        DB_USERNAME=$(grep DB_USERNAME .env | cut -d '=' -f2)
        DB_PASSWORD=$(grep DB_PASSWORD .env | cut -d '=' -f2)
        
        mysqldump -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" > "$BACKUP_DIR/db_backup_$TIMESTAMP.sql"
    }
    
    print_success "Database backup created: $BACKUP_DIR/db_backup_$TIMESTAMP.sql"
else
    print_warning "Skipping database backup (--skip-backup flag used)"
fi

###############################################################################
# Step 2: Export Admin Group Data
###############################################################################

print_header "Step 2: Exporting Admin Group Data"

echo "Exporting admin group data for reference..."
php artisan tinker --execute="
    \$groups = \App\Models\AdminGroup::with('admin', 'members')->get();
    file_put_contents('$BACKUP_DIR/admin_groups_export_$TIMESTAMP.json', \$groups->toJson(JSON_PRETTY_PRINT));
    echo 'Exported ' . \$groups->count() . ' admin groups';
" 2>/dev/null || print_warning "Could not export admin group data (table may not exist)"

print_success "Admin group data exported"

###############################################################################
# Step 3: Create Git Tag
###############################################################################

print_header "Step 3: Creating Git Backup"

if git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Creating Git tag..."
    git tag -a "rollback-point-$TIMESTAMP" -m "Backup before admin group rollback" 2>/dev/null || true
    print_success "Git tag created: rollback-point-$TIMESTAMP"
else
    print_warning "Not a Git repository, skipping Git backup"
fi

###############################################################################
# Step 4: Put Application in Maintenance Mode
###############################################################################

print_header "Step 4: Enabling Maintenance Mode"

php artisan down --message="System maintenance in progress" --retry=60
print_success "Application is now in maintenance mode"

###############################################################################
# Step 5: Rollback Migrations
###############################################################################

print_header "Step 5: Rolling Back Migrations"

echo "Current migration status:"
php artisan migrate:status | grep -E "(admin_group|2025_11_01)"

echo ""
if confirm "Proceed with rolling back 2 migrations?"; then
    php artisan migrate:rollback --step=2
    print_success "Migrations rolled back successfully"
else
    print_error "Migration rollback cancelled"
    php artisan up
    exit 1
fi

###############################################################################
# Step 6: Clear Caches
###############################################################################

print_header "Step 6: Clearing Application Caches"

php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

print_success "Caches cleared"

###############################################################################
# Step 7: Regenerate Optimized Files
###############################################################################

print_header "Step 7: Regenerating Optimized Files"

php artisan config:cache
php artisan route:cache

print_success "Optimized files regenerated"

###############################################################################
# Step 8: Bring Application Back Online
###############################################################################

print_header "Step 8: Disabling Maintenance Mode"

php artisan up
print_success "Application is now online"

###############################################################################
# Post-Rollback Verification
###############################################################################

print_header "Post-Rollback Verification"

echo "Checking database structure..."
php artisan tinker --execute="
    \$tables = DB::select('SHOW TABLES');
    \$hasAdminGroups = false;
    foreach (\$tables as \$table) {
        \$tableName = array_values((array)\$table)[0];
        if (\$tableName === 'admin_groups') {
            \$hasAdminGroups = true;
            break;
        }
    }
    if (\$hasAdminGroups) {
        echo '❌ ERROR: admin_groups table still exists!';
        exit(1);
    } else {
        echo '✅ admin_groups table successfully removed';
    }
"

echo ""
echo "Checking users table structure..."
php artisan tinker --execute="
    \$columns = DB::select('DESCRIBE users');
    \$hasGroupFields = false;
    foreach (\$columns as \$column) {
        if (in_array(\$column->Field, ['admin_group_id', 'organization_name', 'department_name'])) {
            \$hasGroupFields = true;
            break;
        }
    }
    if (\$hasGroupFields) {
        echo '❌ ERROR: Group-related fields still exist in users table!';
        exit(1);
    } else {
        echo '✅ Group-related fields successfully removed from users table';
    }
"

###############################################################################
# Summary
###############################################################################

echo ""
print_header "Rollback Complete!"

echo ""
echo "Summary:"
echo "  - Database backup: $BACKUP_DIR/db_backup_$TIMESTAMP.sql"
echo "  - Admin group export: $BACKUP_DIR/admin_groups_export_$TIMESTAMP.json"
echo "  - Git tag: rollback-point-$TIMESTAMP"
echo ""
print_warning "Next Steps:"
echo "  1. Review docs/ADMIN_GROUP_ROLLBACK_GUIDE.md for post-rollback tasks"
echo "  2. Manually remove admin group code files (models, services, controllers)"
echo "  3. Update API routes to remove admin group endpoints"
echo "  4. Run test suite: php artisan test"
echo "  5. Verify application functionality"
echo "  6. Consider running restore_organization_department_constraints migration"
echo ""
print_success "Rollback script completed successfully"
