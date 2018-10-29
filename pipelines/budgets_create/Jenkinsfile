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
        stage("Extract/Load > Create budgets forecast for 2010") {
            steps {
                sh "cd ${BUDGETS_COMPARATOR_GENCAT}; bin/rails runner ${COMPARATOR_GENCAT_ETL_OPERATIONS}budgets_forecast/create.rb 2010"
            }
        }
        stage("Extract/Load > Create budgets forecast for 2011") {
            steps {
                sh "cd ${BUDGETS_COMPARATOR_GENCAT}; bin/rails runner ${COMPARATOR_GENCAT_ETL_OPERATIONS}budgets_forecast/create.rb 2011"
            }
        }
        stage("Extract/Load > Create budgets forecast for 2012") {
            steps {
                sh "cd ${BUDGETS_COMPARATOR_GENCAT}; bin/rails runner ${COMPARATOR_GENCAT_ETL_OPERATIONS}budgets_forecast/create.rb 2012"
            }
        }
        stage("Extract/Load > Create budgets forecast for 2013") {
            steps {
                sh "cd ${BUDGETS_COMPARATOR_GENCAT}; bin/rails runner ${COMPARATOR_GENCAT_ETL_OPERATIONS}budgets_forecast/create.rb 2013"
            }
        }
        stage("Extract/Load > Create budgets forecast for 2014") {
            steps {
                sh "cd ${BUDGETS_COMPARATOR_GENCAT}; bin/rails runner ${COMPARATOR_GENCAT_ETL_OPERATIONS}budgets_forecast/create.rb 2014"
            }
        }
        stage("Extract/Load > Create budgets forecast for 2015") {
            steps {
                sh "cd ${BUDGETS_COMPARATOR_GENCAT}; bin/rails runner ${COMPARATOR_GENCAT_ETL_OPERATIONS}budgets_forecast/create.rb 2015"
            }
        }
        stage("Extract/Load > Create budgets forecast for 2016") {
            steps {
                sh "cd ${BUDGETS_COMPARATOR_GENCAT}; bin/rails runner ${COMPARATOR_GENCAT_ETL_OPERATIONS}budgets_forecast/create.rb 2016"
            }
        }
        stage("Extract/Load > Create budgets forecast for 2017") {
            steps {
                sh "cd ${BUDGETS_COMPARATOR_GENCAT}; bin/rails runner ${COMPARATOR_GENCAT_ETL_OPERATIONS}budgets_forecast/create.rb 2017"
            }
        }
        stage("Extract/Load > Create budgets forecast for 2018") {
            steps {
                sh "cd ${BUDGETS_COMPARATOR_GENCAT}; bin/rails runner ${COMPARATOR_GENCAT_ETL_OPERATIONS}budgets_forecast/create.rb 2018"
            }
        }
        // Create budgets execution by invoking the update scripts
        stage("Extract/Load > Create budgets execution for 2009 - 2018") {
            steps {
                sh "cd ${BUDGETS_COMPARATOR_GENCAT}; bin/rails runner ${COMPARATOR_GENCAT_ETL_OPERATIONS}budgets_execution/update.rb 2009-01-01"
            }
        }
        stage("Transform/Load > Update budgets forecast totals for 2010 - 2018") {
            steps {
                sh "cd ${GOBIERTO_ETL_UTILS}operations/gobierto_budgets/update_total_budget/; ./run.rb '2010 2011 2012 2013 2014 2015 2016 2017 2018' ${BUDGETS_COMPARATOR_GENCAT}scanned_organizations_ids.create.txt"
            }
        }
        stage("Transform/Load > Update budgets execution totals for 2010-2018") {
            steps {
                sh "cd ${GOBIERTO_ETL_UTILS}operations/gobierto_budgets/update_total_budget; ./run.rb '2010 2011 2012 2013 2014 2015 2016 2017 2018' ${BUDGETS_COMPARATOR_GENCAT}scanned_organizations_ids.update_execution.txt"
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
