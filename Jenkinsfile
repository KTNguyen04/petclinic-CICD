pipeline {
    agent any

    tools {
        maven 'maven3.9.9' // Tên Maven trong Global Tool Configuration
    }

    options {
        skipDefaultCheckout()
    }

    environment {
        BUILD_VETS = "false"
        BUILD_VISITS = "false"
        BUILD_CUSTOMERS = "false"
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    checkout scm
                }
            }
        }
        stage('Detect Changes') {
            steps {
                script {
                    def changedFiles = sh(script: "git diff --name-only HEAD~1", returnStdout: true).trim()
                    echo "Changed files:\n${changedFiles}"

                    if (changedFiles.contains("spring-petclinic-vets-service/")) {
                        env.BUILD_VETS = "true"
                    }
                    if (changedFiles.contains("spring-petclinic-visits-service/")) {
                        env.BUILD_VISITS = "true"
                    }
                    if (changedFiles.contains("spring-petclinic-customers-service/")) {
                        env.BUILD_CUSTOMERS = "true"
                    }
                }
            }
        }

        stage('Build & Test Services') {
            matrix {
                axes {
                    axis {
                        name 'SERVICE'
                        values 'spring-petclinic-vets-service', 
                               'spring-petclinic-visits-service', 
                               'spring-petclinic-customers-service'
                    }
                }
                when {
                    expression { env.get("BUILD_" + SERVICE.toUpperCase().replace("-", "_")) == "true" }
                }

                stages {
                    stage('Build') {
                        steps {
                            dir("${SERVICE}") {
                                sh "mvn clean package -DskipTests"
                            }
                        }
                    }
                    stage('Test & Coverage') {
                        steps {
                            dir("${SERVICE}") {
                                sh "mvn test"
                                junit '**/target/surefire-reports/*.xml'
                            }
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline completed!"
        }
    }
}
