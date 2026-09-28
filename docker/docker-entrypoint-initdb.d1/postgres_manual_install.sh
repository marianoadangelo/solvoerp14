#INSTALL AND CONFIGURE POSTGRES
echo 'local   all             postgres                                trust
local   all             all                                     md5
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5' | tee $(ls /etc/postgresql/*/main/pg_hba.conf)
/etc/init.d/postgresql restart
psql -U postgres -c "CREATE ROLE odoo WITH LOGIN PASSWORD 'odoo' SUPERUSER CREATEDB CREATEROLE;"
