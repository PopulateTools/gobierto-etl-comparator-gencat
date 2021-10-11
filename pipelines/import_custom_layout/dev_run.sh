#!/bin/bash

set -e

LAYOUT_LOCATION="https://www.transparenciacatalunya.cat/templates?mode=html&code=TCAT0001"
COMPARATOR_GENCAT_ETL=$DEV_DIR/gobierto-etl-comparator-gencat
STORAGE_DIR=$DEV_DIR/gobierto-etl-comparator-gencat/tmp
RAILS_ENV=development
LOCALES="ca es en" # change per "ca es en" when they are available

# Extract > Download layout file
cd $COMPARATOR_GENCAT_ETL; ruby operations/import_custom_layout/download_layout.rb $STORAGE_DIR $LAYOUT_LOCATION $LOCALES

# Transform > Insert custom tags and split files
cd $COMPARATOR_GENCAT_ETL; ruby operations/import_custom_layout/generate_templates.rb $STORAGE_DIR

# Load > Upload templates to S3
cd $COMPARATOR_GENCAT_ETL; ruby operations/import_custom_layout/upload_templates.rb $RAILS_ENV $STORAGE_DIR
