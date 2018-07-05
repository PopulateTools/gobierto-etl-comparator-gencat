email = "popu-servers+jenkins@populate.tools "
pipeline {
    agent any
    environment {
        PATH = "/home/ubuntu/.rbenv/shims:$PATH"
        BUDGETS_COMPARATOR_GENCAT = "/var/www/gobierto-budgets-comparator-gencat-staging/current/"
        POPULATE_DATA_SCRIPTS = "/var/www/populate-data-indicators/private_data/gobierto_budgets_comparator/gencat/budgets_forecast/"
        GOBIERTO_ETL_UTILS = "/var/www/gobierto-etl-utils/current/"
        ELASTICSEARCH_URL = "http://localhost:9200"
    }
    stages {
        stage('Create budgets forecast for 2010') {
            steps {
                sh "cd ${BUDGETS_COMPARATOR_GENCAT}; bin/rails runner ${POPULATE_DATA_SCRIPTS}create.rb 2010"
            }
        }
        stage('Create budgets forecast for 2011') {
            steps {
                sh "cd ${BUDGETS_COMPARATOR_GENCAT}; bin/rails runner ${POPULATE_DATA_SCRIPTS}create.rb 2011"
            }
        }
        stage('Create budgets forecast for 2012') {
            steps {
                sh "cd ${BUDGETS_COMPARATOR_GENCAT}; bin/rails runner ${POPULATE_DATA_SCRIPTS}create.rb 2012"
            }
        }
        stage('Create budgets forecast for 2013') {
            steps {
                sh "cd ${BUDGETS_COMPARATOR_GENCAT}; bin/rails runner ${POPULATE_DATA_SCRIPTS}create.rb 2013"
            }
        }
        stage('Create budgets forecast for 2014') {
            steps {
                sh "cd ${BUDGETS_COMPARATOR_GENCAT}; bin/rails runner ${POPULATE_DATA_SCRIPTS}create.rb 2014"
            }
        }
        stage('Create budgets forecast for 2015') {
            steps {
                sh "cd ${BUDGETS_COMPARATOR_GENCAT}; bin/rails runner ${POPULATE_DATA_SCRIPTS}create.rb 2015"
            }
        }
        stage('Create budgets forecast for 2016') {
            steps {
                sh "cd ${BUDGETS_COMPARATOR_GENCAT}; bin/rails runner ${POPULATE_DATA_SCRIPTS}create.rb 2016"
            }
        }
        stage('Create budgets forecast for 2017') {
            steps {
                sh "cd ${BUDGETS_COMPARATOR_GENCAT}; bin/rails runner ${POPULATE_DATA_SCRIPTS}create.rb 2017"
            }
        }
        stage('Create budgets forecast for 2018') {
            steps {
                sh "cd ${BUDGETS_COMPARATOR_GENCAT}; bin/rails runner ${POPULATE_DATA_SCRIPTS}create.rb 2018"
            }
        }
        stage('Update total budgets for 2010 - 2018') {
            steps {
                sh "cd ${GOBIERTO_ETL_UTILS}operations/gobierto_budgets/update_total_budget/; ./run.rb '2010 2011 2012 2013 2014 2015 2016 2017 2018' ${BUDGETS_COMPARATOR_GENCAT}scanned_organizations_ids.create.txt"
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
