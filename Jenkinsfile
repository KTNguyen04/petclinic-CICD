pipeline {
    agent {
        label 'development-server'
    }

    environment {
        PROJECT_NAME = 'spring-petclinic-microservices'
        PROJECT_PATH = "${WORKSPACE}"
        USERNAME = '22120207'
    }

    stages {

        stage('Run Unit Test') {
            steps {
                jacoco classPattern: '**/spring-petclinic-visits-service/target/classes', 
                       execPattern: '**/spring-petclinic-vets-service/target/coverage-reports/jacoco.exec',
                       runAlways: true, 
                       sourcePattern: '**/spring-petclinic-visits-service/src/main/java'
            }
        }

        stage('Build') {
            steps {
                script {
                    sh 'echo "Building..."'
                }
            }
        }
    }
}