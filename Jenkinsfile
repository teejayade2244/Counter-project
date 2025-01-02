pipeline {
    agent any
    tools {
        nodejs "Nodejs-22-6-0"
    }
    options {
       disableConcurrentBuilds abortPrevious: true
    }
    environment {
        SONAR_SCANNER_HOME = tool 'sonarqube-scanner-6.1.0.477'
        // This is for username:password joined together
        // MY_CREDENTIALS = credentials ('env_credentials')
    }
    stages {
        // dependencies installation
        stage("Install node-js dependencies") {
            steps {
                // Install Node.js dependencies without auditing vulnerabilities
                sh "npm install --no-audit"
            }
        }

        // dependencies scanning
        // stage("Dependency Check scanning") {
        //     parallel {
        //         stage("NPM dependencies audit") {
        //             steps {
        //                 // Run npm audit to check for critical vulnerabilities
        //                 sh '''
        //                     npm audit --audit-level=critical
        //                     echo $?
        //                 '''
        //             }
        //         }

        //         stage("OWASP Dependency Check") { 
        //             steps {
        //                 // Run OWASP Dependency Check scan with specific arguments
        //                 dependencyCheck additionalArguments: '''
        //                     --scan \'./\' \
        //                     --out \'./\' \
        //                     --disableYarnAudit \
        //                     --format \'ALL\' \
        //                     --prettyPrint
        //                 ''', odcInstallation: 'OWAPS-Depend-check'
        //                 // Publish the Dependency Check report and fail the build if critical issues are found
        //                 dependencyCheckPublisher failedTotalCritical: 1, pattern: 'dependency-check-report.xml', stopBuild: true
        //             }
        //         }
        //     }
        // }

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
        // stage("Static Testing and Analysis with SonarQube") {
        //     steps {
        //         timeout(time: 5, unit: 'MINUTES') {
        //             withSonarQubeEnv('sonarqube-server') {
        //                 // Run SonarQube scanner with specific parameters
        //                 sh '''
        //                     ${SONAR_SCANNER_HOME}/bin/sonar-scanner \
        //                     -Dsonar.projectKey=Counter-project \
        //                     -Dsonar.sources=src \
        //                     -Dsonar.inclusions=src/App.js \
        //                     -Dsonar.javascript.lcov.reportPaths=./coverage/lcov.info     
        //                 '''
        //             }
        //         }
        //         // Wait for SonarQube quality gate and fail the pipeline if it's not OK
        //         waitForQualityGate abortPipeline: true
        //     }
        // }

        //build docker image
        stage("Build docker image") {
          steps {
            sh 'printenv'
            sh 'docker build -t teejay4125/counter-project:$GIT_COMMIT .' 
          }
        }

        // scan the image for vulnerabilities before pushing to resgistry
        // stage("Trivy Vulnerability scan") {
        //     steps {
        //       sh '''
        //         trivy image teejay4125/counter-project:$GIT_COMMIT \
        //         --severity LOW,MEDIUM \
        //         --exit-code 0 \
        //         --quiet \
        //         --format json -o trivy-image-MEDIUM-results.json

        //          trivy image teejay4125/counter-project:$GIT_COMMIT \
        //         --severity CRITICAL \
        //         --exit-code 1 \
        //         --quiet \
        //         --format json -o trivy-image-CRITICAL-results.json
        //       '''
        //     }
        //     post {
        //       always {
        //         //converting the json report format to html and junit so it can be published
        //         sh '''
        //          trivy convert \
        //             --format template --template "@/usr/local/share/trivy/templates/html.tpl" \
        //             --output trivy-image-MEDIUM-results.html trivy-image-MEDIUM-results.json  
                
        //          trivy convert \
        //             --format template --template "@/usr/local/share/trivy/templates/html.tpl" \
        //             --output trivy-image-CRITICAL-results.html trivy-image-CRITICAL-results.json

        //         trivy convert \
        //             --format template --template "@/usr/local/share/trivy/templates/xml.tpl" \
        //             --output trivy-image-MEDIUM-results.xml trivy-image-MEDIUM-results.json  

        //         trivy convert \
        //             --format template --template "@/usr/local/share/trivy/templates/xml.tpl" \
        //             --output trivy-image-CRITICAL-results.xml trivy-image-CRITICAL-results.json    
        //          '''
        //       }
        //     }
        // }

        // push image to registry
        stage("Push to registry") {
          steps {
            withDockerRegistry(credentialsId: 'Docker-details', url: "") {
              sh 'docker push teejay4125/counter-project:$GIT_COMMIT'
            }
          }
        }

        // deploy to AWS EC2
        stage("Deploy to AWS EC2") {
        // only deploy when branch is from feature
         when {
            branch 'feature/*'
         }
         steps { 
            script {
                sshagent(['aws-ec2-instance-deploy']) {
              def GIT_COMMIT = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
            sh '''
                ssh -o StrictHostKeyChecking=no ubuntu@ec2-3-208-24-225.compute-1.amazonaws.com '\
                    if docker ps -a | grep -i "counter-project"; then \
                        echo "Container found. Stopping and removing..." && \
                        sudo docker stop "counter-project" && sudo docker rm "counter-project" && \
                        echo "Container stopped and removed." \
                    fi && \
                    echo "Pulling and running new container..." && \
                    sudo docker run -d --name counter-project -p 3000:3000 teejay4125/counter-project:${GIT_COMMIT}'
            '''
                }
             }
           }
        }
  }
    // post actions
        post {
          always {
              // Publish JUnit test results, even if they are empty
              junit allowEmptyResults: true, stdioRetention: '', testResults: 'test-results.xml'
              junit allowEmptyResults: true, stdioRetention: '', testResults: 'dependency-check-junit.xml'
              junit allowEmptyResults: true, stdioRetention: '', testResults: 'trivy-image-CRITICAL-results.xml'
              junit allowEmptyResults: true, stdioRetention: '', testResults: 'trivy-image-MEDIUM-results.xml'   
              
              // Publish the Dependency Check HTML report
              publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'dependency-check-report.html', reportName: 'Dependency check HTML Report', reportTitles: '', useWrapperFileDirectly: true])
              // Publish the Code Coverage HTML report
              publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'coverage/Icon-report', reportFiles: 'index.html', reportName: 'Code Coverage HTML Report', reportTitles: '', useWrapperFileDirectly: true])

              publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'CRITICAL-results.html', reportName: 'Trivy scan Image critical vul report', reportTitles: '', useWrapperFileDirectly: true])

              publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'MEDIUM-results.html', reportName: 'Trivy scan Image medium vul report', reportTitles: '', useWrapperFileDirectly: true])
          }
       }
}
