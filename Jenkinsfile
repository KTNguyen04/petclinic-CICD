pipeline {
    agent none
    options { skipDefaultCheckout() }
    environment {
        DOCKER_REGISTRY = "devops22clc"
        REPO_URL = "https://github.com/devops22clc/spring-petclinic-microservices.git"
        REPO_NAME = "spring-petclinic-microservices"
        SERVICE_AS = "spring-petclinic"
    }
    stages {
        stage('Initialize Variables') {
            agent { label 'controller-node' }
            steps {
                script {
                    def SERVICES = [
                            "spring-petclinic-config-server",
                            "spring-petclinic-discovery-server",
                            "spring-petclinic-api-gateway",
                            "spring-petclinic-customers-service",
                            "spring-petclinic-vets-service",
                            "spring-petclinic-visits-service",
                            "spring-petclinic-admin-server",
                            "spring-petclinic-genai-service"
                    ]
                    env.SERVICES = SERVICES.join(",")
                }
            }
        }
        stage("Detect changes") {
            agent { label 'controller-node' }
            steps {
                dir("${WORKSPACE}"){
                    script {
                        sh(script: "git init && git branch -m ${BRANCH_NAME} && git fetch --no-tags --force --progress -- ${REPO_URL} refs/heads/${BRANCH_NAME}:refs/remotes/origin/${BRANCH_NAME}")
                        def changedFiles = sh(script: "git diff --name-only origin/${BRANCH_NAME}", returnStdout: true).trim().split("\n")
                        def changedServices = [] as Set
                        def rootChanged = false

                        for (file in changedFiles) {
                            echo "file: ${file} || service_as: ${SERVICE_AS}"

                            if (!file.startsWith("${SERVICE_AS}")) {
                                rootChanged = true
                                echo "Changed Root"
                                break
                            } else {
                                    def service = file.split("/")[0]
                                changedServices.add(service)
                            }
                        }

                        env.CHANGED_SERVICES = changedServices.join(',')
                        env.IS_CHANGED_ROOT = rootChanged.toString()
                        echo "Changed Services: ${env.CHANGED_SERVICES}"

                        sh "git merge origin/${BRANCH_NAME}"
                    }
                }
            }
        }
        stage("Build & TEST") {
            parallel {
                stage("Build") {
                    agent { label 'maven-node' }
                    steps {
                        checkout scm
                        sh "cat ~/docker-registry-passwd.txt | docker login --username ${DOCKER_REGISTRY} --password-stdin"
                        script {
                            env.GIT_COMMIT_SHA = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                            env.STAGE = env.BRANCH_NAME == "main" ? "prod" : "dev" //@fixme
                            if (env.IS_CHANGED_ROOT == "true")  env.CHANGED_SERVICES = env.SERVICES

                            def changedServices = env.CHANGED_SERVICES.split(',')
                            for (service in changedServices) {
                                sh """
                                cd ${service}
                                echo "run build for ${service}"
                                mvn clean package -DskipTests
                                cd ..
                                docker build --build-arg SERVICE=${service} --build-arg STAGE=${env.STAGE} -f docker/Dockerfile.${service} -t ${DOCKER_REGISTRY}/${env.STAGE}-${service}:${env.GIT_COMMIT_SHA} .
                                docker push ${DOCKER_REGISTRY}/${service}:${env.GIT_COMMIT_SHA}
                             """
                            }
                            sh "echo y | docker image prune -a"
                        }
                    }
                }
                stage("TEST") {
                    agent { label 'maven-node' }
                    steps {
                        checkout scm
                        script {
                            if (env.IS_CHANGED_ROOT == "true")  env.CHANGED_SERVICES = env.SERVICES

                            def changedServices = env.CHANGED_SERVICES.split(',')
                            for (service in changedServices) {
                                echo "Running tests for service: ${service}"
                                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                                    sh """
                                    cd ${service}
                                    mvn test
                                """
                                }
                            }
                        }
                    }
                    post {
                        always {
                            echo "Cleaning up workspace on maven-node..."
                            cleanWs()
                        }
                    }
                }
            }
        }
        //stage('Deploy') {
        //    when {
        //        expression { return env.STAGE == "prod" || env.STAGE = "dev" || env.STAGE = "uat" }
        //    }
        //    agent { label 'kubernetes-node' }
        //    steps {
        //                script {
        //            if (env.IS_CHANGED_ROOT == 'true') {
        //                        echo "Deploying all services"
        //                sh """
        //
        //                """
        //            } else if (env.CHANGED_SERVICES?.trim()) {
        //                def changedServices = env.CHANGED_SERVICES.split(',')
        //                for (service in changedServices) {
        //                    echo "Deploying service: ${service}"
        //                }
        //            }
        //        }
        //    }
        //}
    }
}
