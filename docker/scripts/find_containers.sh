#!/bin/bash
# Script de ayuda para identificar los contenedores correctos para la migración
# Uso: ./docker/scripts/find_containers.sh [version_origen]

set -e

VERSION="${1:-13}"
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}   Identificador de Contenedores${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo -e "${YELLOW}Buscando contenedores de Odoo ${VERSION}...${NC}"
echo ""

# Buscar contenedores PostgreSQL
echo -e "${GREEN}📦 Contenedores de PostgreSQL encontrados:${NC}"
POSTGRES_CONTAINERS=$(docker ps -a --filter "name=db" --filter "name=postgres" --format "{{.Names}}\t{{.Status}}\t{{.Image}}" | grep -i "${VERSION}" || true)

if [ -z "$POSTGRES_CONTAINERS" ]; then
    echo "  ⚠️  No se encontraron contenedores PostgreSQL v${VERSION}"
    echo "  Mostrando todos los contenedores de PostgreSQL:"
    docker ps -a --filter "name=db" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
else
    echo "$POSTGRES_CONTAINERS" | while IFS=$'\t' read -r name status image; do
        echo -e "  ${GREEN}✓${NC} ${name}"
        echo -e "    Estado: ${status}"
        echo -e "    Imagen: ${image}"
        echo ""
    done
fi

echo ""
echo -e "${GREEN}📦 Contenedores de Odoo encontrados:${NC}"
ODOO_CONTAINERS=$(docker ps -a --filter "name=odoo" --format "{{.Names}}\t{{.Status}}\t{{.Image}}" | grep -E "odoo-${VERSION}|odoo_${VERSION}" || true)

if [ -z "$ODOO_CONTAINERS" ]; then
    echo "  ⚠️  No se encontraron contenedores Odoo v${VERSION}"
    echo "  Mostrando todos los contenedores de Odoo:"
    docker ps -a --filter "name=odoo" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
else
    echo "$ODOO_CONTAINERS" | while IFS=$'\t' read -r name status image; do
        echo -e "  ${GREEN}✓${NC} ${name}"
        echo -e "    Estado: ${status}"
        echo -e "    Imagen: ${image}"
        echo ""
    done
fi

echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${YELLOW}💡 Comando sugerido para migración:${NC}"
echo ""

# Obtener el primer contenedor de cada tipo
POSTGRES_NAME=$(echo "$POSTGRES_CONTAINERS" | head -n1 | cut -f1)
ODOO_NAME=$(echo "$ODOO_CONTAINERS" | head -n1 | cut -f1)

if [ -n "$POSTGRES_NAME" ] && [ -n "$ODOO_NAME" ]; then
    echo -e "${GREEN}SOURCE_HOST=${POSTGRES_NAME} \\${NC}"
    echo -e "${GREEN}DB_SOURCE=<nombre_db> \\${NC}"
    echo -e "${GREEN}DB_NAME=<nombre_db> \\${NC}"
    echo -e "${GREEN}COPY_DB=true \\${NC}"
    echo -e "${GREEN}SOURCE_FILESTORE_CONTAINER=${ODOO_NAME} \\${NC}"
    echo -e "${GREEN}docker-compose -f docker-compose-migrate.yml run --rm odoo-14-migrate${NC}"
    echo ""
    echo -e "${YELLOW}📝 Reemplaza <nombre_db> con el nombre de tu base de datos${NC}"
else
    echo -e "${YELLOW}⚠️  No se pudieron identificar todos los contenedores necesarios${NC}"
    echo -e "${YELLOW}Verifica manualmente con: docker ps -a${NC}"
fi

echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${YELLOW}🔍 Para listar bases de datos en PostgreSQL:${NC}"
if [ -n "$POSTGRES_NAME" ]; then
    echo -e "${GREEN}docker exec -it ${POSTGRES_NAME} psql -U odoo -l${NC}"
fi
echo ""
