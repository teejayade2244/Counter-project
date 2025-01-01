pipeline {
    agent any
    tools {
        nodejs "Nodejs-22-6-0"
    }
    environment {
        SONAR_SCANNER_HOME = tool 'sonarqube-scanner-6.1.0.477'
        // This is for username:password joined together
        // MY_CREDENTIALS = credentials ('env_credentials')
    }
    stages {
        // dependencies installation
        stage("Install node dependencies") {
            steps {
                // Install Node.js dependencies without auditing vulnerabilities
                sh "npm install --no-audit"
            }
        }

        // dependencies scanning
        stage("Dependency Check scanning") {
            parallel {
                stage("NPM dependencies audit") {
                    steps {
                        // Run npm audit to check for critical vulnerabilities
                        sh '''
                            npm audit --audit-level=critical
                            echo $?
                        '''
                    }
                }

                stage("OWASP Dependency Check") { 
                    steps {
                        // Run OWASP Dependency Check scan with specific arguments
                        dependencyCheck additionalArguments: '''
                            --scan \'./\' \
                            --out \'./\' \
                            --disableYarnAudit \
                            --format \'ALL\' \
                            --prettyPrint
                        ''', odcInstallation: 'OWAPS-Depend-check'
                        // Publish the Dependency Check report and fail the build if critical issues are found
                        dependencyCheckPublisher failedTotalCritical: 1, pattern: 'dependency-check-report.xml', stopBuild: true
                    }
                }
            }
        }

        // unit testing
        stage("Unit Testing stage") {
            steps {
              // option { retry (2) }
              // sh 'echo MY_USERNAME - $MY_CREDENTIALS_USR'
              // sh 'echo MY_PASSWORD - $MY_CREDENTIALS_PSW'
            //   withCredentials([usernamePassword(credentialsId: 'env_credentials', passwordVariable: 'MY_PASSWORD', usernameVariable: 'MY_USERNAME')]) {
            // }
                // Run unit tests with npm
                sh "npm test"
            } 
        }

        // code coverage
        stage("Code coverage") {
            // In this stage jest will generate a coverage report which will be used by SonarQube
            // The -Dsonar.javascript.lcov.reportPaths=./coverage/lcov.info assumes a coverage file exists at the specified path. Ensure your build process generates this file beforehand. Otherwise, SonarQube will raise an error.
            steps {
                catchError(buildResult: 'SUCCESS', message: 'opps There is an error it will be fixed in the next release', stageResult: 'UNSTABLE') {
                    script {
                        // Run coverage script and check the result status
                        def coverageResult = sh(script: 'npm run coverage', returnStatus: true)
                        echo "Coverage script exited with code: ${coverageResult}"

                        // If the coverage generation fails, mark the build as failed
                        if (coverageResult != 0) {
                            error("Coverage report generation failed.")
                        }
                    }
                }
            }
        }

        // static testing and analysis with SonarQube
        stage("Static Testing and Analysis with SonarQube") {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    withSonarQubeEnv('sonarqube-server') {
                        // Run SonarQube scanner with specific parameters
                        sh '''
                            ${SONAR_SCANNER_HOME}/bin/sonar-scanner \
                            -Dsonar.projectKey=Counter-project \
                            -Dsonar.sources=src \
                            -Dsonar.inclusions=src/App.js \
                            -Dsonar.javascript.lcov.reportPaths=./coverage/lcov.info     
                        '''
                    }
                }
                // Wait for SonarQube quality gate and fail the pipeline if it's not OK
                waitForQualityGate abortPipeline: true
            }
        }
    }

    // post actions
    post {
        always {
            // Publish JUnit test results, even if they are empty
            junit allowEmptyResults: true, stdioRetention: '', testResults: 'test-results.xml'
            junit allowEmptyResults: true, stdioRetention: '', testResults: 'dependency-check-junit.xml'
            // Publish the Dependency Check HTML report
            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'dependency-check-report.html', reportName: 'Dependency check HTML Report', reportTitles: '', useWrapperFileDirectly: true])
            // Publish the Code Coverage HTML report
            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'coverage/Icon-report', reportFiles: 'index.html', reportName: 'Code Coverage HTML Report', reportTitles: '', useWrapperFileDirectly: true])
        }
    }
}
