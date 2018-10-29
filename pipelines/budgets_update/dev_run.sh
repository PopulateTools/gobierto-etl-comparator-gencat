#!/bin/bash

RAILS_ENV="development"
GOBIERTO_ETL_UTILS=$DEV_DIR/gobierto-etl-utils
COMPARATOR_GENCAT_ETL=$DEV_DIR/gobierto-etl-comparator-gencat
ELASTICSEARCH_URL="http://localhost:9200"
BUDGETS_COMPARATOR_GENCAT=$DEV_DIR/gobierto-budgets-comparator-gen-cat
STORAGE_DIR=$COMPARATOR_GENCAT_ETL/tmp
FAST_RUN=false
BUCKET_NAME="gobierto-budgets-comparator-dev"

# Extract > Download last start query date
s3cmd get s3://$BUCKET_NAME/gencat/last_excecution_date.txt $STORAGE_DIR/last_excecution_date.txt --force

# Extract/Load > Update budgets forecast since 31/12/2016
cd $BUDGETS_COMPARATOR_GENCAT; FAST_RUN=$FAST_RUN bin/rails runner $COMPARATOR_GENCAT_ETL/operations/gobierto-budgets/budgets_forecast/update.rb "$(< $STORAGE_DIR/last_excecution_date.txt)" $STORAGE_DIR

# Extract/Load > Update budgets execution since 31/12/2016
cd $BUDGETS_COMPARATOR_GENCAT; bin/rails runner $COMPARATOR_GENCAT_ETL/operations/gobierto-budgets/budgets_execution/update.rb "$(< $STORAGE_DIR/last_excecution_date.txt)" $STORAGE_DIR

# Extract > Generate year arguments for updating total budgets
echo "$(($(date +%Y)-1)) $(date +%Y)" > $STORAGE_DIR/total_budgets_years.txt

# Transform/Load > Update total budgets for 2016-2018 forecast data
cd $GOBIERTO_ETL_UTILS/operations/gobierto_budgets/update_total_budget/; ./run.rb "$(< $STORAGE_DIR/total_budgets_years.txt)" $STORAGE_DIR/scanned_organizations_ids.update.txt

# Transform/Load > Update total budgets for 2016-2018 execution data
cd $GOBIERTO_ETL_UTILS/operations/gobierto_budgets/update_total_budget; ./run.rb '"$(< $STORAGE_DIR/total_budgets_years.txt)"' $STORAGE_DIR/scanned_organizations_ids.update_execution.txt

# Load > Re-calculate bubbles
cd $BUDGETS_COMPARATOR_GENCAT; bin/rails runner $COMPARATOR_GENCAT_ETL/operations/gobierto-budgets/generate_organizations_ids/run.rb $STORAGE_DIR
cd $GOBIERTO_ETL_UTILS; ruby operations/gobierto_budgets/bubbles/run.rb $STORAGE_DIR/organization_ids.txt
cd $GOBIERTO_ETL_UTILS; ruby operations/gobierto_budgets/bubbles/run.rb $STORAGE_DIR/entity_ids.txt

# Documentation > Upload last execution date
echo `date +%Y-%m-%d` > $STORAGE_DIR/last_excecution_date.txt
s3cmd put $STORAGE_DIR/last_excecution_date.txt s3://$BUCKET_NAME/gencat/last_excecution_date.txt
