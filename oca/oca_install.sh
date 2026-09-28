#!/usr/bin/env bash
set -x

mkdir /home/mariano/PycharmProjects/solvoerp14/oca/source
mkdir /home/mariano/PycharmProjects/solvoerp14/oca/addons

cd /home/mariano/PycharmProjects/solvoerp14/oca/source
git clone -b 14.0 --depth 1 https://github.com/OCA/account-analytic
git clone -b 14.0 --depth 1 https://github.com/OCA/partner-contact
git clone -b 14.0 --depth 1 https://github.com/OCA/account-closing
git clone -b 14.0 --depth 1 https://github.com/OCA/connector-interfaces
git clone -b 14.0 --depth 1 https://github.com/OCA/account-financial-tools
git clone -b 14.0 --depth 1 https://github.com/OCA/account-financial-reporting
git clone -b 14.0 --depth 1 https://github.com/OCA/account-invoicing
git clone -b 14.0 --depth 1 https://github.com/OCA/account-invoice-reporting
git clone -b 14.0 --depth 1 https://github.com/OCA/account-payment

git clone -b 14.0 --depth 1 https://github.com/OCA/bank-statement-reconcile
git clone -b 14.0 --depth 1 https://github.com/OCA/bank-statement-import
git clone -b 14.0 --depth 1 https://github.com/OCA/bank-payment

git clone -b 14.0 --depth 1 https://github.com/OCA/calendar
git clone -b 14.0 --depth 1 https://github.com/OCA/crm
git clone -b 14.0 --depth 1 https://github.com/OCA/contract
git clone -b 14.0 --depth 1 https://github.com/OCA/connector
git clone -b 14.0 --depth 1 https://github.com/OCA/connector-cmis
git clone -b 14.0 --depth 1 https://github.com/OCA/connector-telephony
git clone -b 14.0 --depth 1 https://github.com/OCA/commission
git clone -b 14.0 --depth 1 https://github.com/OCA/currency
git clone -b 14.0 --depth 1 https://github.com/OCA/credit-control
git clone -b 14.0 --depth 1 https://github.com/OCA/community-data-files

git clone -b 14.0 --depth 1 https://github.com/OCA/delivery-carrier
git clone -b 14.0 --depth 1 https://github.com/OCA/data-protection

git clone -b 14.0 --depth 1 https://github.com/OCA/e-commerce
git clone -b 14.0 --depth 1 https://github.com/OCA/event

git clone -b 14.0 --depth 1 https://github.com/OCA/hr
git clone -b 14.0 --depth 1 https://github.com/OCA/hr-attendance
git clone -b 14.0 --depth 1 https://github.com/OCA/hr-expense
git clone -b 14.0 --depth 1 https://github.com/OCA/hr-timesheet

git clone -b 14.0 --depth 1 https://github.com/OCA/geospatial

git clone -b 14.0 --depth 1 https://github.com/OCA/knowledge

git clone -b 14.0 --depth 1 https://github.com/OCA/manufacture

git clone -b 14.0 --depth 1 https://github.com/OCA/product-attribute
git clone -b 14.0 --depth 1 https://github.com/OCA/brand
git clone -b 14.0 --depth 1 https://github.com/OCA/purchase-workflow
git clone -b 14.0 --depth 1 https://github.com/OCA/project
git clone -b 14.0 --depth 1 https://github.com/OCA/pos
git clone -b 14.0 --depth 1 https://github.com/OCA/purchase-reporting

git clone -b 14.0 --depth 1 https://github.com/OCA/margin-analysis
git clone -b 14.0 --depth 1 https://github.com/OCA/manufacture-reporting
git clone -b 14.0 --depth 1 https://github.com/OCA/multi-company
git clone -b 14.0 --depth 1 https://github.com/OCA/mis-builder.git

git clone -b 14.0 --depth 1 https://github.com/OCA/report-print-send
git clone -b 14.0 --depth 1 https://github.com/OCA/reporting-engine oca-reporting-engine

git clone -b 14.0 --depth 1 https://github.com/OCA/sale-financial
git clone -b 14.0 --depth 1 https://github.com/OCA/sale-reporting
git clone -b 14.0 --depth 1 https://github.com/OCA/sale-workflow
git clone -b 14.0 --depth 1 https://github.com/OCA/server-backend
git clone -b 14.0 --depth 1 https://github.com/OCA/server-tools
git clone -b 14.0 --depth 1 https://github.com/OCA/server-ux
git clone -b 14.0 --depth 1 https://github.com/OCA/social

git clone -b 14.0 --depth 1 https://github.com/OCA/stock-logistics-reporting
git clone -b 14.0 --depth 1 https://github.com/OCA/stock-logistics-warehouse
git clone -b 14.0 --depth 1 https://github.com/OCA/stock-logistics-tracking
git clone -b 14.0 --depth 1 https://github.com/OCA/stock-logistics-workflow
git clone -b 14.0 --depth 1 https://github.com/OCA/stock-logistics-barcode

git clone -b 14.0 --depth 1 https://github.com/OCA/queue.git

git clone -b 14.0 --depth 1 https://github.com/OCA/vertical-medical
git clone -b 14.0 --depth 1 https://github.com/OCA/vertical-community

git clone -b 14.0 --depth 1 https://github.com/OCA/web
git clone -b 14.0 --depth 1 https://github.com/OCA/website
git clone -b 14.0 --depth 1 https://github.com/OCA/website-cms
git clone -b 14.0 --depth 1 https://github.com/OCA/website-themes

#-----------------------------------------------------------------------------------------------------------------------
#argentina 13.0
#-----------------------------------------------------------------------------------------------------------------------
git clone -b 14.0 --depth 1 https://github.com/ingadhoc/account-analytic adhoc-account-analytic
git clone -b 14.0 --depth 1 https://github.com/ingadhoc/account-financial-tools adhoc-account-financial-tools
git clone -b 14.0 --depth 1 https://github.com/ingadhoc/account-invoicing adhoc-account-invoicing
git clone -b 14.0 --depth 1 https://github.com/ingadhoc/account-payment adhoc-account-payment
git clone -b 14.0 --depth 1 https://github.com/ingadhoc/aeroo_reports.git
git clone -b 14.0 --depth 1 https://github.com/ingadhoc/argentina-reporting adhoc-argentina-reporting
git clone -b 14.0 --depth 1 https://github.com/ingadhoc/argentina-sale adhoc-argentina-sale
git clone -b 14.0 --depth 1 https://github.com/ingadhoc/miscellaneous adhoc-miscellaneous
git clone -b 14.0 --depth 1 https://github.com/ingadhoc/odoo-argentina adhoc-odoo-argentina
git clone -b 14.0 --depth 1 https://github.com/ingadhoc/odoo-argentina-ee adhoc-odoo-argentina-ee
git clone -b 14.0 --depth 1 https://github.com/ingadhoc/patches.git adhoc-patches
git clone -b 14.0 --depth 1 https://github.com/ingadhoc/product adhoc-product
git clone -b 14.0 --depth 1 https://github.com/ingadhoc/partner adhoc-partner
git clone -b 14.0 --depth 1 https://github.com/ingadhoc/purchase adhoc-purchase
git clone -b 14.0 --depth 1 https://github.com/ingadhoc/reporting-engine adhoc-reporting-engine
git clone -b 14.0 --depth 1 https://github.com/ingadhoc/sale adhoc-sale
git clone -b 14.0 --depth 1 https://github.com/ingadhoc/stock adhoc-stock
git clone -b 14.0 --depth 1 https://github.com/ingadhoc/website adhoc-website


sudo rm -R /home/mariano/PycharmProjects/solvoerp14/oca/addons/
mkdir /home/mariano/PycharmProjects/solvoerp14/oca/addons/
for d in /home/mariano/PycharmProjects/solvoerp14/oca/source/* ; do
    cd "$d"
    cp -Rf * /home/mariano/PycharmProjects/solvoerp14/oca/addons
done