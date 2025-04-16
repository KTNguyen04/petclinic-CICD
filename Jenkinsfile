pipeline {
    agent any
	
	tools {
        maven 'MAVEN3.9'
        jdk 'JDK17'
        git 'GIT'
    }

    environment {
        AFFECTED_SERVICES = ""
    }

    stages {

        stage('Check Commit Message') {
            steps {
                script {
                    def commitMessage = sh(script: "git log -1 --pretty=%B", returnStdout: true).trim()
                    echo "Commit message: ${commitMessage}"

                    if (commitMessage.contains('[skip ci]')) {
                        echo "Skipping build because commit message contains [skip ci]"
                        currentBuild.result = 'SUCCESS'
                        // Exit pipeline early
                        error("Build skipped due to [skip ci] in commit message")
                    }
                }
            }
        }


        stage('Detect Branch') {
            steps {
                script {
                    echo "Current Branch: ${env.BRANCH_NAME}"
                    echo "Current git Branch: ${env.GIT_BRANCH}"
                }
            }
        }

        stage('Detect Affected Services') {
            when {
                expression { return env.BRANCH_NAME != 'main' }
            }
            steps {
                script {
                    def services = sh(script: "ls -d spring-petclinic*/ | cut -f1 -d'/'", returnStdout: true).trim().split("\n")
                    def changedFiles = sh(script: "git diff --name-only HEAD^ HEAD", returnStdout: true).trim().split("\n")
                    def affectedServices = []

                    for (file in changedFiles) {
                        for (service in services) {
                            if (file.startsWith("${service}/")) {
                                affectedServices << service
                            }
                        }
                    }

                    AFFECTED_SERVICES = affectedServices.unique().join(',')
                    echo "Affected Services: ${AFFECTED_SERVICES}"
                }
            }
        }

        stage('Build and Test') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'main') {
                        echo "Building all services after merge..."
                        sh "mvn clean verify org.jacoco:jacoco-maven-plugin:0.8.8:prepare-agent org.jacoco:jacoco-maven-plugin:0.8.8:report"
                    } else if (AFFECTED_SERVICES?.trim()) {
                        def affectedServices = AFFECTED_SERVICES.split(',')
                        for (service in affectedServices) {
                            echo "Building ${service}..."
                            sh """
                                cd ${service}
                                mvn clean verify org.jacoco:jacoco-maven-plugin:0.8.8:prepare-agent org.jacoco:jacoco-maven-plugin:0.8.8:report
                            """
                        }
                    } else {
                        echo "No affected services, skipping build."
                    }
                }
            }
        }

        stage('Publish Test Results & Coverage') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'main' || AFFECTED_SERVICES?.trim()) {
                        def affectedServices = env.BRANCH_NAME == 'main' ? 
                            sh(script: "ls -d spring-petclinic*/ | cut -f1 -d'/'", returnStdout: true).trim().split("\n") 
                            : AFFECTED_SERVICES.split(',')

                        for (service in affectedServices) {
                            echo "Publishing test results and coverage for ${service}..."
                            
                            def testResultPath = "${service}/target/surefire-reports/*.xml"
                            def coveragePath = "${service}/target/jacoco.exec"
                            
                        
                            def testResults = findFiles(glob: testResultPath)
                            if (testResults.length > 0) {
                                junit testResults[0].path
                            } else {
                                echo "No test results found for ${service}, skipping JUnit report."
                            }

                            if (fileExists(coveragePath)) {
                                jacoco execPattern: coveragePath,
                                    classPattern: "${service}/target/classes", 
                                    sourcePattern: "${service}/src/main/java"
                            } else {
                                echo "No JaCoCo coverage report found for ${service}, skipping coverage report."
                            }
                        }
                    } else {
                        echo "No affected services, skipping test result publishing."
                    }
                }
            }
        }


        stage('Build and Push Docker Image') {
            environment {
                // DOCKERHUB_CREDENTIALS = credentials('dockerhub-cre')
                DOCKERHUB_USERNAME = 'championvi12'
            }
            steps {
                script {
                    def COMMIT_ID = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    def IMAGE_TAG = COMMIT_ID
                    def services = []

                    if (env.BRANCH_NAME == 'main') {
                        // If current commit has git tag
                        def TAG_NAME = sh(script: "git describe --exact-match --tags || true", returnStdout: true).trim()
                        IMAGE_TAG = TAG_NAME ? TAG_NAME : 'latest'

                        sh './mvnw clean install -P buildDocker'
                        services = sh(script: "ls -d spring-petclinic*/ | cut -f1 -d'/'", returnStdout: true).trim().split("\n")
                    } else if (AFFECTED_SERVICES?.trim()) {
                        services = AFFECTED_SERVICES.split(',')

                        for (service in services) {
                            def dir = service.trim()
                            sh "cd ${dir} && ../mvnw clean install -P buildDocker"
                        }
                    }
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-cre') {
                        if (services) {
                            for (service in services) {
                                def serviceName = service.trim().replace("/", "")
                                def sourceImage = "${DOCKERHUB_USERNAME}/${serviceName}:latest"
                                def targetImage = "${DOCKERHUB_USERNAME}/${serviceName}:${IMAGE_TAG}"

                                echo "Tagging image ${sourceImage} as ${targetImage}..."

                                // Retag
                                sh "docker tag ${sourceImage} ${targetImage}"
                                echo "Pushing image ${targetImage}..."

                                docker.image(targetImage).push()
                            }
                        } else {
                            echo "No services to build image for."
                        }
                    }
                }
            }
        }


        stage('Update Config Repo') {
            when {
                branch 'main'
            }
            steps {
                script {
                    def TAG_NAME = sh(script: "git describe --exact-match --tags || true", returnStdout: true).trim()
                    def CONFIG_REPO_URL = "https://github.com/your-org/config-repo.git"
                    def CONFIG_REPO_PATH = "${env.WORKSPACE}/petclinic-CICD-config"


                    echo "Preparing config repo at ${CONFIG_REPO_PATH}"

                    // Clone nếu thư mục chưa tồn tại hoặc chưa phải repo Git
                    if (!fileExists("${CONFIG_REPO_PATH}/.git")) {
                        withCredentials([string(credentialsId: 'github-app-token-id', variable: 'GITHUB_TOKEN')]) {
                            sh """
                                git clone https://x-access-token:${GITHUB_TOKEN}@github.com/your-org/config-repo.git ${CONFIG_REPO_PATH}
                            """
                        }
                    }

                    // Bắt đầu cập nhật tag nếu có
                    dir(CONFIG_REPO_PATH) {
                        sh "git pull origin master"

                        if (TAG_NAME) {
                            echo "Git tag detected: ${TAG_NAME} - Updating Helm staging values.yaml files"
                            def SERVICES_DIR = "helm/staging/values"
                            def SERVICE_NAMES = sh(
                                script: "ls ${SERVICES_DIR}",
                                returnStdout: true
                            ).trim().split('\n')

                            SERVICE_NAMES.each { service ->
                                def filePath = "${SERVICES_DIR}/${service}/values.yaml"
                                echo "Updating tag in ${filePath}"
                                sh """sed -i 's/\\(tag:\\s*\\).*/\\1"${TAG_NAME}"/' ${filePath}"""
                            }

                            // Commit và push   
                            withCredentials([string(credentialsId: 'github-app-token-id', variable: 'GITHUB_TOKEN')]) {
                                sh """
                                    git config user.name "KTNguyen04"
                                    git config user.email "championvi12@gmail.com"
                                    git remote set-url origin https://x-access-token:${GITHUB_TOKEN}@github.com/your-org/config-repo.git
                                    git add .
                                    git commit -m 'Update config from ${env.JOB_NAME} build ${env.BUILD_NUMBER} ${TAG_NAME ? "for tag ${TAG_NAME}" : ""}' || echo "No changes to commit"
                                    git push origin master
                                """
                            }
                        }

                    }
                }
            }
        }




    }
}

