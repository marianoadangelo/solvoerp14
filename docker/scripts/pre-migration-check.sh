#!/bin/bash
# Pre-Migration Check Script
# Validates that the environment is ready for OpenUpgrade migration

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   Pre-Migration Checks${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

ERRORS=0

# Check 1: OpenUpgrade framework exists
echo -n "Checking OpenUpgrade framework... "
if [ -d "/opt/odoo/OpenUpgrade/openupgrade_framework" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo -e "${RED}ERROR: OpenUpgrade framework not found${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check 2: OpenUpgrade scripts exist
echo -n "Checking OpenUpgrade scripts... "
if [ -d "/opt/odoo/OpenUpgrade/openupgrade_scripts" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo -e "${RED}ERROR: OpenUpgrade scripts not found${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check 3: Configuration file exists
echo -n "Checking configuration file... "
if [ -f "/opt/odoo/server-migrate.conf" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo -e "${RED}ERROR: Configuration file not found${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check 4: upgrade_path is set in config
echo -n "Checking upgrade_path in config... "
if grep -q "upgrade_path" /opt/odoo/server-migrate.conf 2>/dev/null; then
    UPGRADE_PATH=$(grep "upgrade_path" /opt/odoo/server-migrate.conf | cut -d'=' -f2 | tr -d ' ')
    echo -e "${GREEN}✓${NC} ($UPGRADE_PATH)"
else
    echo -e "${RED}✗${NC}"
    echo -e "${RED}ERROR: upgrade_path not set in configuration${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check 5: server_wide_modules includes openupgrade_framework
echo -n "Checking server_wide_modules... "
if grep -q "server_wide_modules.*openupgrade_framework" /opt/odoo/server-migrate.conf 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
    echo -e "${YELLOW}WARNING: openupgrade_framework not in server_wide_modules${NC}"
fi

# Check 6: Target database connection
echo -n "Checking target database connection (${HOST:-db-odoo-14})... "
if PGPASSWORD=${PASSWORD:-odoo} psql -h ${HOST:-db-odoo-14} -U ${USER:-odoo} -d postgres -c '\q' 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo -e "${RED}ERROR: Cannot connect to target database${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check 7: Source database connection (if COPY_DB is enabled)
if [ "${COPY_DB:-false}" = "true" ] && [ -n "${SOURCE_HOST}" ]; then
    echo -n "Checking source database connection (${SOURCE_HOST})... "
    if PGPASSWORD=${SOURCE_PASSWORD:-odoo} psql -h ${SOURCE_HOST} -p ${SOURCE_PORT:-5432} -U ${SOURCE_USER:-odoo} -d postgres -c '\q' 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"

        # Also check if source database exists
        if [ -n "${DB_SOURCE}" ]; then
            echo -n "Checking source database '${DB_SOURCE}' exists... "
            if PGPASSWORD=${SOURCE_PASSWORD:-odoo} psql -h ${SOURCE_HOST} -p ${SOURCE_PORT:-5432} -U ${SOURCE_USER:-odoo} -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_SOURCE}'" 2>/dev/null | grep -q 1; then
                echo -e "${GREEN}✓${NC}"
            else
                echo -e "${RED}✗${NC}"
                echo -e "${RED}ERROR: Source database '${DB_SOURCE}' does not exist on ${SOURCE_HOST}${NC}"
                ERRORS=$((ERRORS + 1))
            fi
        fi
    else
        echo -e "${RED}✗${NC}"
        echo -e "${RED}ERROR: Cannot connect to source database (${SOURCE_HOST})${NC}"
        ERRORS=$((ERRORS + 1))
    fi
fi

# Check 8: Available disk space
echo -n "Checking disk space... "
AVAILABLE_SPACE=$(df -h /var/lib/odoo | awk 'NR==2 {print $4}')
echo -e "${GREEN}✓${NC} ($AVAILABLE_SPACE available)"

echo ""
echo -e "${BLUE}============================================${NC}"

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}All checks passed! Ready for migration.${NC}"
    echo -e "${BLUE}============================================${NC}"
    exit 0
else
    echo -e "${RED}Found $ERRORS error(s). Please fix before migration.${NC}"
    echo -e "${BLUE}============================================${NC}"
    exit 1
fi
