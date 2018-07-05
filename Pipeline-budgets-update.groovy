email = "popu-servers+jenkins@populate.tools "
pipeline {
    agent any
    environment {
        PATH = "/home/ubuntu/.rbenv/shims:$PATH"
        RAILS_ENV="staging"
        ELASTICSEARCH_URL = "http://localhost:9200"
        BUDGETS_COMPARATOR_GENCAT = "/var/www/gobierto-budgets-comparator-gencat-staging/current/"
        POPULATE_DATA_SCRIPTS = "/var/www/populate-data-indicators/private_data/gobierto_budgets_comparator/gencat/"
        GOBIERTO_ETL_UTILS = "/var/www/gobierto-etl-utils/current/"
    }
    stages {
        stage("Update budgets forecast since 31/12/2017") {
            steps {
                sh "cd ${BUDGETS_COMPARATOR_GENCAT}; bin/rails runner ${POPULATE_DATA_SCRIPTS}budgets_forecast/update.rb 2017-12-31"
            }
        }
        stage("Update budgets execution since 31/12/2017") {
            steps {
                sh "cd ${BUDGETS_COMPARATOR_GENCAT}; bin/rails runner ${POPULATE_DATA_SCRIPTS}budgets_execution/update.rb 2017-12-31"
            }
        }
        stage("Update total budgets for 2017-2018 forecast data") {
            steps {
                sh "cd ${GOBIERTO_ETL_UTILS}operations/gobierto_budgets/update_total_budget/; ./run.rb "2017 2018" ${BUDGETS_COMPARATOR_GENCAT}scanned_organizations_ids.update.txt"
            }
        }
        stage("Update total budgets for 2017-2018 execution data") {
            steps {
                sh "cd ${GOBIERTO_ETL_UTILS}operations/gobierto_budgets/update_total_budget; ./run.rb "2017 2018" ${BUDGETS_COMPARATOR_GENCAT}scanned_organizations_ids.update_execution.txt"
            }
        }
    }
    post {
        failure {
            echo 'This will run only if failed'
            mail body: "Project: ${env.JOB_NAME} - Build Number: ${env.BUILD_NUMBER} - URL de build: ${env.BUILD_URL}",
                charset: 'UTF-8',
                subject: "ERROR CI: Project name -> ${env.JOB_NAME}",
                to: email

        }
    }
}
