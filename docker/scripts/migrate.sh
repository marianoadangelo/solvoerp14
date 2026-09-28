#!/bin/bash
# OpenUpgrade Migration Script
# This script handles the migration process from Odoo 13 to Odoo 14

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DB_NAME="${DB_NAME:-solvo}"
DB_SOURCE="${DB_SOURCE:-}"
COPY_DB="${COPY_DB:-false}"
CONFIG_FILE="${CONFIG_FILE:-/opt/odoo/server-migrate.conf}"

# Log file in mounted volume (persistent)
LOG_DIR="${LOG_DIR:-/opt/odoo/migration_logs}"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/migration_$(date +%Y%m%d_%H%M%S).log"

PRE_MIGRATION_SQL="${PRE_MIGRATION_SQL:-/opt/odoo/migration_tools/pre_migration.sql}"

# Source database connection (for copying from another container/server)
SOURCE_HOST="${SOURCE_HOST:-}"
SOURCE_USER="${SOURCE_USER:-odoo}"
SOURCE_PASSWORD="${SOURCE_PASSWORD:-odoo}"
SOURCE_PORT="${SOURCE_PORT:-5432}"

# Temporary dump file location
DUMP_DIR="${DUMP_DIR:-/opt/odoo/migration_dumps}"
mkdir -p "$DUMP_DIR"

# Filestore locations
FILESTORE_DIR="/var/lib/odoo/filestore"
SOURCE_FILESTORE_CONTAINER="${SOURCE_FILESTORE_CONTAINER:-solvoerp13_odoo-13_1}"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   OpenUpgrade Migration Process${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "${YELLOW}Database Target:${NC} $DB_NAME"
echo -e "${YELLOW}Database Source:${NC} ${DB_SOURCE:-N/A}"
echo -e "${YELLOW}Copy DB:${NC} $COPY_DB"
if [ -n "$SOURCE_HOST" ]; then
    echo -e "${YELLOW}Source Host:${NC} $SOURCE_HOST:$SOURCE_PORT (external)"
else
    echo -e "${YELLOW}Source Host:${NC} $HOST (same server)"
fi
echo -e "${YELLOW}Config File:${NC} $CONFIG_FILE"
echo -e "${YELLOW}Log File:${NC} $LOG_FILE"
echo ""

# Function to log messages
log_message() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case $level in
        "INFO")
            echo -e "${GREEN}[INFO]${NC} $message" | tee -a "$LOG_FILE"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message" | tee -a "$LOG_FILE"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message" | tee -a "$LOG_FILE"
            ;;
        *)
            echo -e "$message" | tee -a "$LOG_FILE"
            ;;
    esac
}

# Function to check if database exists
db_exists() {
    local db_name=$1
    PGPASSWORD=$PASSWORD psql -h "$HOST" -U "$USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$db_name'" 2>/dev/null | grep -q 1
}

# Function to check if database exists on source server
source_db_exists() {
    local db_name=$1
    local src_host="${SOURCE_HOST:-$HOST}"
    local src_user="${SOURCE_USER:-$USER}"
    local src_pass="${SOURCE_PASSWORD:-$PASSWORD}"
    local src_port="${SOURCE_PORT:-5432}"
    PGPASSWORD=$src_pass psql -h "$src_host" -p "$src_port" -U "$src_user" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$db_name'" 2>/dev/null | grep -q 1
}

# Function to copy database (same server)
copy_database() {
    local source=$1
    local target=$2
    log_message "INFO" "Copying database from '$source' to '$target'..."

    # Terminate connections to source database
    PGPASSWORD=$PASSWORD psql -h "$HOST" -U "$USER" -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$source' AND pid <> pg_backend_pid();" 2>/dev/null || true

    # Create database copy
    if PGPASSWORD=$PASSWORD createdb -h "$HOST" -U "$USER" -T "$source" "$target" 2>/dev/null; then
        log_message "INFO" "Database copied successfully!"
        return 0
    else
        log_message "ERROR" "Failed to copy database"
        return 1
    fi
}

# Function to copy database from remote server (different container)
copy_database_remote() {
    local source=$1
    local target=$2
    local src_host="${SOURCE_HOST}"
    local src_user="${SOURCE_USER:-odoo}"
    local src_pass="${SOURCE_PASSWORD:-odoo}"
    local src_port="${SOURCE_PORT:-5432}"

    log_message "INFO" "Copying database from remote server..."
    log_message "INFO" "Source: $src_host:$src_port/$source -> Target: $HOST/$target"

    # Use file-based dump/restore (more reliable than pipe)
    local DUMP_FILE="${DUMP_DIR}/source_dump_${source}_$(date +%Y%m%d_%H%M%S).dump"
    
    # Step 1: Dump source database to file
    log_message "INFO" "Step 1/3: Dumping source database to file..."
    log_message "INFO" "Dump file: $DUMP_FILE"
    
    if ! PGPASSWORD=$src_pass pg_dump -h "$src_host" -p "$src_port" -U "$src_user" -d "$source" -Fc -f "$DUMP_FILE" 2>&1 | tee -a "$LOG_FILE"; then
        log_message "ERROR" "Failed to dump source database"
        return 1
    fi
    
    # Check dump file was created and has content
    if [ ! -f "$DUMP_FILE" ] || [ ! -s "$DUMP_FILE" ]; then
        log_message "ERROR" "Dump file not created or is empty"
        return 1
    fi
    
    local DUMP_SIZE=$(du -h "$DUMP_FILE" | cut -f1)
    log_message "INFO" "Dump completed. File size: $DUMP_SIZE"

    # Step 2: Drop target database if it exists
    if db_exists "$target"; then
        log_message "INFO" "Step 2/3: Dropping existing target database '$target'..."
        # Terminate all connections to the target database
        PGPASSWORD=$PASSWORD psql -h "$HOST" -U "$USER" -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$target' AND pid <> pg_backend_pid();" 2>/dev/null || true
        PGPASSWORD=$PASSWORD dropdb -h "$HOST" -U "$USER" "$target" 2>&1 | tee -a "$LOG_FILE" || {
            log_message "ERROR" "Failed to drop existing target database"
            return 1
        }
    else
        log_message "INFO" "Step 2/3: Target database doesn't exist, skipping drop..."
    fi

    # Step 3: Create new database and restore
    log_message "INFO" "Step 3/3: Creating target database and restoring..."
    PGPASSWORD=$PASSWORD createdb -h "$HOST" -U "$USER" "$target" 2>&1 | tee -a "$LOG_FILE" || {
        log_message "ERROR" "Failed to create target database"
        return 1
    }
    
    log_message "INFO" "Restoring database (this may take a while)..."
    if PGPASSWORD=$PASSWORD pg_restore -h "$HOST" -U "$USER" -d "$target" --no-owner --no-privileges -v "$DUMP_FILE" 2>&1 | tee -a "$LOG_FILE"; then
        log_message "INFO" "Database restored successfully!"
    else
        # pg_restore often returns non-zero even on success due to warnings
        log_message "WARN" "pg_restore completed with warnings (this is often normal for migrations)"
    fi
    
    # Verify the database has tables
    local TABLE_COUNT=$(PGPASSWORD=$PASSWORD psql -h "$HOST" -U "$USER" -d "$target" -tAc "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null)
    
    if [ -n "$TABLE_COUNT" ] && [ "$TABLE_COUNT" -gt 0 ]; then
        log_message "INFO" "Database copied successfully! Found $TABLE_COUNT tables in target database."
        # Optionally keep dump file for reference, or remove it
        # rm -f "$DUMP_FILE"
        log_message "INFO" "Dump file kept at: $DUMP_FILE"
        return 0
    else
        log_message "ERROR" "Database appears to be empty after restore!"
        return 1
    fi
}

# Function to copy filestore from source container
# NOTE: This function is called from within a Docker container
# Since docker CLI is not available inside, we need an alternative approach
copy_filestore() {
    local source_db=$1
    local target_db=$2

    log_message "INFO" "Copying filestore..."
    log_message "INFO" "Source DB: $source_db"
    log_message "INFO" "Target DB: $target_db"

    # Check if source filestore path is mounted/accessible
    # When running via docker-compose, the host should mount the source filestore
    local SOURCE_FILESTORE_PATH="${SOURCE_FILESTORE_PATH:-/mnt/source_filestore}"

    if [ -d "$SOURCE_FILESTORE_PATH/$source_db" ]; then
        log_message "INFO" "Source filestore found at: $SOURCE_FILESTORE_PATH/$source_db"

        # Remove existing target filestore if exists
        if [ -d "$FILESTORE_DIR/$target_db" ]; then
            log_message "INFO" "Removing existing target filestore..."
            rm -rf "$FILESTORE_DIR/$target_db"
        fi

        # Copy filestore
        mkdir -p "$FILESTORE_DIR"
        cp -r "$SOURCE_FILESTORE_PATH/$source_db" "$FILESTORE_DIR/$target_db"

        # Fix permissions
        chown -R odoo:odoo "$FILESTORE_DIR/$target_db" 2>/dev/null || true
        chmod -R 755 "$FILESTORE_DIR/$target_db" 2>/dev/null || true

        local FILE_COUNT=$(find "$FILESTORE_DIR/$target_db" -type f 2>/dev/null | wc -l)
        local DIR_SIZE=$(du -sh "$FILESTORE_DIR/$target_db" 2>/dev/null | cut -f1)
        log_message "INFO" "Filestore copied successfully!"
        log_message "INFO" "Files: $FILE_COUNT, Size: $DIR_SIZE"
        return 0
    else
        log_message "WARN" "Source filestore not found at: $SOURCE_FILESTORE_PATH/$source_db"
        log_message "WARN" "To copy filestore automatically, you need to:"
        log_message "WARN" "  1. Find the source filestore volume:"
        log_message "WARN" "     docker volume inspect solvoerp13_odoo-data-13"
        log_message "WARN" "  2. Add it to docker-compose-migrate.yml volumes section:"
        log_message "WARN" "     - solvoerp13_odoo-data-13:/mnt/source_filestore:ro"
        log_message "WARN" ""
        log_message "WARN" "OR manually copy filestore after migration:"
        log_message "WARN" "  docker cp ${SOURCE_FILESTORE_CONTAINER}:/var/lib/odoo/filestore/$source_db \\"
        log_message "WARN" "    /tmp/filestore_$source_db"
        log_message "WARN" "  docker cp /tmp/filestore_$source_db \\"
        log_message "WARN" "    solvoerp14_db-odoo-14_1:/var/lib/odoo/filestore/$target_db"
        log_message "WARN" ""
        log_message "WARN" "Continuing without filestore (attachments may be missing)"
        return 0
    fi
}

# Wait for PostgreSQL to be ready
log_message "INFO" "Checking database connection..."
until PGPASSWORD=$PASSWORD psql -h "$HOST" -U "$USER" -d postgres -c '\q' 2>/dev/null; do
    log_message "WARN" "PostgreSQL is unavailable - sleeping"
    sleep 2
done

log_message "INFO" "PostgreSQL is ready!"

# Check if target database exists
if db_exists "$DB_NAME"; then
    log_message "INFO" "Target database '$DB_NAME' already exists"
else
    log_message "WARN" "Target database '$DB_NAME' does not exist"

    # Check if we should copy from source
    if [ "$COPY_DB" = "true" ] && [ -n "$DB_SOURCE" ]; then
        # Check if copying from remote server or same server
        if [ -n "$SOURCE_HOST" ]; then
            # Remote copy (from another container/server)
            log_message "INFO" "Checking source database on remote server $SOURCE_HOST..."
            if source_db_exists "$DB_SOURCE"; then
                copy_database_remote "$DB_SOURCE" "$DB_NAME"
                # Copy filestore after database copy
                log_message "INFO" "Now copying filestore..."
                copy_filestore "$DB_SOURCE" "$DB_NAME"
            else
                log_message "ERROR" "Source database '$DB_SOURCE' does not exist on $SOURCE_HOST!"
                exit 1
            fi
        else
            # Same server copy
            if db_exists "$DB_SOURCE"; then
                copy_database "$DB_SOURCE" "$DB_NAME"
                # Copy filestore for same server (local copy)
                log_message "INFO" "Copying filestore locally..."
                if [ -d "$FILESTORE_DIR/$DB_SOURCE" ]; then
                    rm -rf "$FILESTORE_DIR/$DB_NAME"
                    cp -r "$FILESTORE_DIR/$DB_SOURCE" "$FILESTORE_DIR/$DB_NAME"
                    chown -R odoo:odoo "$FILESTORE_DIR/$DB_NAME" 2>/dev/null || true
                    local FILE_COUNT=$(find "$FILESTORE_DIR/$DB_NAME" -type f | wc -l)
                    log_message "INFO" "Filestore copied locally! Found $FILE_COUNT files."
                else
                    log_message "WARN" "Source filestore not found at $FILESTORE_DIR/$DB_SOURCE"
                fi
            else
                log_message "ERROR" "Source database '$DB_SOURCE' does not exist!"
                exit 1
            fi
        fi
    else
        log_message "ERROR" "Target database does not exist and COPY_DB is not enabled"
        log_message "ERROR" "Set COPY_DB=true and DB_SOURCE=<source_db> to copy from an existing database"
        log_message "ERROR" "For remote copy, also set SOURCE_HOST, SOURCE_USER, SOURCE_PASSWORD"
        exit 1
    fi
fi

# Create backup before migration
log_message "INFO" "Creating backup before migration..."
BACKUP_FILE="/var/lib/odoo/backup_before_migration_${DB_NAME}_$(date +%Y%m%d_%H%M%S).sql"
if PGPASSWORD=$PASSWORD pg_dump -h "$HOST" -U "$USER" -d "$DB_NAME" -F c -f "$BACKUP_FILE" 2>/dev/null; then
    log_message "INFO" "Backup created successfully: $BACKUP_FILE"
else
    log_message "WARN" "Could not create backup"
fi

# Execute pre-migration SQL scripts if they exist
if [ -f "$PRE_MIGRATION_SQL" ]; then
    log_message "INFO" "Executing pre-migration SQL scripts..."
    if PGPASSWORD=$PASSWORD psql -h "$HOST" -U "$USER" -d "$DB_NAME" -f "$PRE_MIGRATION_SQL" 2>&1 | tee -a "$LOG_FILE"; then
        log_message "INFO" "Pre-migration SQL executed successfully"
    else
        log_message "WARN" "Some pre-migration SQL statements may have failed (this might be expected)"
    fi
else
    log_message "INFO" "No pre-migration SQL file found at $PRE_MIGRATION_SQL (skipping)"
fi

# Check for additional SQL scripts in migration_tools directory
if [ -d "/opt/odoo/migration_tools" ]; then
    for sql_file in /opt/odoo/migration_tools/pre_*.sql; do
        if [ -f "$sql_file" ] && [ "$sql_file" != "$PRE_MIGRATION_SQL" ]; then
            log_message "INFO" "Executing additional SQL script: $sql_file"
            PGPASSWORD=$PASSWORD psql -h "$HOST" -U "$USER" -d "$DB_NAME" -f "$sql_file" 2>&1 | tee -a "$LOG_FILE" || true
        fi
    done
fi

# Run migration
log_message "INFO" "Starting OpenUpgrade migration..."
log_message "INFO" "This process may take several minutes depending on database size..."

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   Running Odoo with OpenUpgrade${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Execute Odoo with OpenUpgrade
python3 /opt/odoo/server/odoo-bin \
    -c "$CONFIG_FILE" \
    -d "$DB_NAME" \
    --update=all \
    --stop-after-init \
    --log-level=info 2>&1 | tee -a "$LOG_FILE"

MIGRATION_RESULT=${PIPESTATUS[0]}

echo ""
if [ $MIGRATION_RESULT -eq 0 ]; then
    log_message "INFO" "============================================"
    log_message "INFO" "   Migration completed successfully!"
    log_message "INFO" "============================================"
    log_message "INFO" "Backup location: $BACKUP_FILE"
    log_message "INFO" "Log file: $LOG_FILE"
    exit 0
else
    log_message "ERROR" "============================================"
    log_message "ERROR" "   Migration failed!"
    log_message "ERROR" "============================================"
    log_message "ERROR" "Check the log file for details: $LOG_FILE"
    log_message "ERROR" "You can restore from backup: $BACKUP_FILE"
    exit 1
fi
