pipeline {
    agent any
    tools {
        nodejs "Nodejs-22-6-0"
    }
    options {
       disableConcurrentBuilds abortPrevious: true
    }
    environment {
        AWS_REGION = credentials ('AWS-REGION')
        ECR_REPO_NAME = 'counter-project'
        AWS_ACCOUNT_ID = credentials ('AWS-account-id')
        IMAGE_TAG = "${ECR_REPO_NAME}:${GIT_COMMIT}"
        DOCKER_IMAGE_NAME = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE_TAG}"
        
        
        // IMAGE_NAME = "teejay4125/counter-project"
        // IMAGE_TAG = "${IMAGE_NAME}:${GIT_COMMIT}"
        
        // EC2_IP_ADDRESS = credentials ('EC2-IP-ADDRESS')
        // SONAR_SCANNER_HOME = tool 'sonarqube-scanner-6.1.0.477'
        // This is for username:password joined together
        // MY_CREDENTIALS = credentials ('env_credentials')
    }
    
    stages {
        // Dependencies installation
        stage("Install node dependencies") {
            steps {
                // Install Node.js dependencies without auditing vulnerabilities
                sh "npm install --no-audit"
                sh "docker version"
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
                        sh 'mkdir -p ${WORKSPACE}/OWASP-security-reports'
                        // Run OWASP Dependency Check scan with specific arguments
                        withCredentials([string(credentialsId: 'NVD-API-KEY', variable: 'NVD_API_KEY')]) {
                                dependencyCheck additionalArguments: """
                                    --scan "${WORKSPACE}" \
                                    --out "${WORKSPACE}/OWASP-security-reports" \
                                    --disableYarnAudit \
                                    --format "HTML,XML,JSON" \
                                    --prettyPrint \
                                    --nvdApiKey "${NVD_API_KEY}" \
                                    --suppressionFile "${WORKSPACE}/dependency-check-suppressions.xml"
                                """, odcInstallation: 'OWAPS-Depend-check'
                         }
                        
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
        // stage("Static Testing and Analysis with SonarQube") {
        //     environment {
        //             SONAR_SCANNER_HOME = tool 'sonarqube-scanner-6.1.0.477'
        //         }
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

        // build docker image
        // stage("Build docker image") {
        //   steps {
        //     sh 'printenv'
        //     sh 'docker build -t ${IMAGE_TAG} .' 
        //   }
        // }

        // login to ECR
        stage("AWS ECR login") {
              // authenticate with ECR so docker has Docker has permission to push images to AWS ECR
              steps {
                  withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'AWS access and secrete Keys', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                     script {
                        // Get ECR login token and execute Docker login. AWSCLI is already configured with both the secret and access keys on the jankins agent 
                        // this command retrieves a temporary authentication password for AWS ECR, and its passed as a stdin to docker 
                        // this allows docker Logs into your AWS ECR repository using the temporary password.
                        sh """
                            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                        """
                     }
                  }
                  
              }
        }

        // Build Docker image
        stage("Build docker image") {
              steps {
                  script {
                        // Build the Docker image
                        sh """
                            docker build -t ${IMAGE_TAG} .
                        """
                  } 
              }
        }

       // Tag Docker Image
        stage("Tag Docker Image") {
            //creates another name (tag) for the image so it matches the AWS ECR format.
              steps {
                  script {
                      sh "docker tag ${IMAGE_TAG} ${DOCKER_IMAGE_NAME}"
                  }
              }
        }

         // scan the image for vulnerabilities before pushing to resgistry
        stage("Trivy Vulnerability scan") {
            steps {
              sh '''
                trivy image ${DOCKER_IMAGE_NAME} \
                --severity LOW,MEDIUM \
                --exit-code 0 \
                --quiet \
                --format json -o trivy-image-MEDIUM-results.json

                 trivy image ${DOCKER_IMAGE_NAME} \
                --severity CRITICAL \
                --exit-code 1 \
                --quiet \
                --format json -o trivy-image-CRITICAL-results.json
              '''
            }
            post {
              always {
                //converting the json report format to html and junit so it can be published
                sh '''
                 trivy convert \
                    --format template --template "@/usr/local/share/trivy/templates/html.tpl" \
                    --output trivy-image-MEDIUM-results.html trivy-image-MEDIUM-results.json  
                
                 trivy convert \
                    --format template --template "@/usr/local/share/trivy/templates/html.tpl" \
                    --output trivy-image-CRITICAL-results.html trivy-image-CRITICAL-results.json

                trivy convert \
                    --format template --template "@/usr/local/share/trivy/templates/xml.tpl" \
                    --output trivy-image-MEDIUM-results.xml trivy-image-MEDIUM-results.json  

                trivy convert \
                    --format template --template "@/usr/local/share/trivy/templates/xml.tpl" \
                    --output trivy-image-CRITICAL-results.xml trivy-image-CRITICAL-results.json    
                 '''
              }
            }
        }

        // Push image to AWS ECR
        stage("Push to AWS ECR") {
            steps {
               script {
                    sh """
                        docker push ${DOCKER_IMAGE_NAME}
                    """
                }
            }
        }

        // push image to registry
        // stage("Push to registry") {
        //   steps {
        //     withDockerRegistry(credentialsId: 'Docker-details', url: "") {
        //       sh 'docker push ${IMAGE_TAG}'
        //     }
        //   }
        // }

         // deploy to AWS EC2
        // stage("Deploy to AWS EC2") {
        // // only deploy when branch is from feature
        //  when {
        //     branch 'feature/*'
        //  }
        //  steps { 
        //     script {
        //       def GIT_COMMIT = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
        //         sshagent(['SSH-Private-Key']) {
        //             sh """
        //                 ssh -o StrictHostKeyChecking=no ubuntu@${EC2_IP_ADDRESS} '
        //                 # Log Docker into AWS ECR
        //                 echo "Logging into AWS ECR..."
        //                 aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
        //                     if docker ps -a | grep -i "counter-project"; then
        //                         echo "Container found. Stopping and removing..."
        //                         sudo docker stop "counter-project" && sudo docker rm "counter-project"
        //                         echo "Container stopped and removed."
        //                     fi
        //                     echo "Pulling and running new container..."
        //                     echo "Using GIT_COMMIT: ${GIT_COMMIT}"
        //                     sudo docker pull ${DOCKER_IMAGE_NAME}
        //                     sudo docker run -d --name counter-project -p 3000:3000 ${DOCKER_IMAGE_NAME}
        //                     sudo docker ps
        //                 '
        //             """
        //         }
        //      }
        //   }
        // }
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
              publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: '${WORKSPACE}/OWASP-security-reports', reportFiles: 'dependency-check-report.html', reportName: 'Dependency check HTML Report', reportTitles: '', useWrapperFileDirectly: true])
              // Publish the Code Coverage HTML report
              publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'coverage/Icon-report', reportFiles: 'index.html', reportName: 'Code Coverage HTML Report', reportTitles: '', useWrapperFileDirectly: true])

              publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'CRITICAL-results.html', reportName: 'Trivy scan Image critical vul report', reportTitles: '', useWrapperFileDirectly: true])

              publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'MEDIUM-results.html', reportName: 'Trivy scan Image medium vul report', reportTitles: '', useWrapperFileDirectly: true])
          }
       }
}
