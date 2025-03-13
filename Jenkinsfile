pipeline {
    agent any

    environment {
        GIT_REPO = 'https://github.com/nghiaz160904/DevOps_Project1.git'
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo 'Starting Checkout stage'
                git branch: 'main',
                    url: "${GIT_REPO}",
                    credentialsId: 'github-pat-global'
                echo 'Checkout completed'
            }
        }

        stage('Detect Changes') {
            steps {
                script {
                    def changedFiles = []
                    def hasPreviousCommit = sh(script: "git rev-parse --verify HEAD~1", returnStatus: true) == 0

                    if (hasPreviousCommit) {
                        changedFiles = sh(script: "git diff --name-only HEAD~1", returnStdout: true).trim().split("\n")
                    } else {
                        echo "No previous commit found, running full build."
                        changedFiles = ["FULL_BUILD"]
                    }

                    env.SHOULD_BUILD_CUSTOMERS = changedFiles.any { it.startsWith("customers-service/") || it == "FULL_BUILD" } ? "true" : "false"
                    env.SHOULD_BUILD_VETS = changedFiles.any { it.startsWith("vets-service/") || it == "FULL_BUILD" } ? "true" : "false"
                    env.SHOULD_BUILD_VISIT = changedFiles.any { it.startsWith("visit-service/") || it == "FULL_BUILD" } ? "true" : "false"

                    echo "Changes detected:"
                    echo "SHOULD_BUILD_CUSTOMERS = ${env.SHOULD_BUILD_CUSTOMERS}"
                    echo "SHOULD_BUILD_VETS = ${env.SHOULD_BUILD_VETS}"
                    echo "SHOULD_BUILD_VISIT = ${env.SHOULD_BUILD_VISIT}"
                }
            }
        }

        stage('Test Services') {
            parallel {
                stage('Test Customers Service') {
                    when { expression { env.SHOULD_BUILD_CUSTOMERS == "true" } }
                    steps {
                        sh './mvnw test -pl customers-service'
                    }
                }

                stage('Test Vets Service') {
                    when { expression { env.SHOULD_BUILD_VETS == "true" } }
                    steps {
                        sh './mvnw test -pl vets-service'
                    }
                }

                stage('Test Visit Service') {
                    when { expression { env.SHOULD_BUILD_VISIT == "true" } }
                    steps {
                        sh './mvnw test -pl visit-service'
                    }
                }
            }
        }

        stage('Build Services') {
            parallel {
                stage('Build Customers Service') {
                    when { expression { env.SHOULD_BUILD_CUSTOMERS == "true" } }
                    steps {
                        sh './mvnw clean package -pl customers-service -DskipTests'
                    }
                }

                stage('Build Vets Service') {
                    when { expression { env.SHOULD_BUILD_VETS == "true" } }
                    steps {
                        sh './mvnw clean package -pl vets-service -DskipTests'
                    }
                }

                stage('Build Visit Service') {
                    when { expression { env.SHOULD_BUILD_VISIT == "true" } }
                    steps {
                        sh './mvnw clean package -pl visit-service -DskipTests'
                    }
                }
            }
        }
    }
}
