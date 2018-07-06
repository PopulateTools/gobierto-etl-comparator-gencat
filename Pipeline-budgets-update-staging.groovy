email = "popu-servers+jenkins@populate.tools "
pipeline {
    agent any
    environment {
        PATH = "/home/ubuntu/.rbenv/shims:$PATH"
        RAILS_ENV="staging"
        ELASTICSEARCH_URL = "http://localhost:9200"
        BUDGETS_COMPARATOR_GENCAT = "/var/www/gobierto-budgets-comparator-gencat-staging/current/"
        COMPARATOR_GENCAT_ETL_OPERATIONS = "/var/www/gobierto-etl-comparator-gencat/current/operations/gobierto-budgets/"
        GOBIERTO_ETL_UTILS = "/var/www/gobierto-etl-utils/current/"
    }
    stages {
        stage("Extract/Load > Update budgets forecast since 31/12/2016") {
            steps {
                sh "cd ${BUDGETS_COMPARATOR_GENCAT}; bin/rails runner ${COMPARATOR_GENCAT_ETL_OPERATIONS}budgets_forecast/update.rb 2016-12-31"
            }
        }
        stage("Extract/Load > Update budgets execution since 31/12/2016") {
            steps {
                sh "cd ${BUDGETS_COMPARATOR_GENCAT}; bin/rails runner ${COMPARATOR_GENCAT_ETL_OPERATIONS}budgets_execution/update.rb 2016-12-31"
            }
        }
        stage("Transform/Load > Update total budgets for 2016-2018 forecast data") {
            steps {
                sh "cd ${GOBIERTO_ETL_UTILS}operations/gobierto_budgets/update_total_budget/; ./run.rb '2016 2017 2018' ${BUDGETS_COMPARATOR_GENCAT}scanned_organizations_ids.update.txt"
            }
        }
        stage("Transform/Load > Update total budgets for 2016-2018 execution data") {
            steps {
                sh "cd ${GOBIERTO_ETL_UTILS}operations/gobierto_budgets/update_total_budget; ./run.rb '2016 2017 2018' ${BUDGETS_COMPARATOR_GENCAT}scanned_organizations_ids.update_execution.txt"
            }
        }
    }
    post {
        failure {
            echo "This will run only if failed"
            mail body: "Project: ${env.JOB_NAME} - Build Number: ${env.BUILD_NUMBER} - URL de build: ${env.BUILD_URL}",
                charset: "UTF-8",
                subject: "ERROR CI: Project name -> ${env.JOB_NAME}",
                to: email

        }
    }
}
