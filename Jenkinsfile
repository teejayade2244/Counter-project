    pipeline {
        agent any
        tools {
          nodejs "Nodejs-22-6-0"
        }
        // environment {
        //    this is for username:password joined together
        //   MY_CREDENTIALS = credentials ('env_credentials')
        // }
      stages {
 //dependencies installation
        stage ("Install node-js dependencies") {
          steps {
            sh "npm install --no-audit"
            
          }
        }

//dependencies scanning
        stage ("Dependency Check scanning") {
          parallel {
            stage ("NPM dependencies audit") {
                    steps {
                      sh '''
                        npm audit --audit-level=critical
                        echo $?
                      '''
                    }
                }
            stage ("OWASP Dependency Check") { 
                    steps {
                      dependencyCheck additionalArguments: '''
                        --scan \'./\'
                        --out \'./\'
                        --format \'ALL\'
                        --prettyPrint''', odcInstallation: 'OWAPS-Depend-check'
                        dependencyCheckPublisher failedTotalCritical: 1, pattern: 'dependency-check-report.xml', stopBuild: true
                    }
                }
            }
        }

//unit testing
        stage ("Unit Testing stage") {
            steps {
              // option { retry (2) }
              // sh 'echo MY_USERNAME - $MY_CREDENTIALS_USR'
              // sh 'echo MY_PASSWORD - $MY_CREDENTIALS_PSW'
              withCredentials([usernamePassword(credentialsId: 'env_credentials', passwordVariable: 'MY_PASSWORD', usernameVariable: 'MY_USERNAME')]) {
              sh "npm test"
            }
          } 
       }

        // stage ("Code coverage") {
        //     steps {
        //       catchError(buildResult: 'SUCCESS', message: 'opps There is an error it will be fixed in the next release', stageResult: 'UNSTABLE') {
        //       sh '''
        //           npm run coverage
        //           echo $?
        //       '''
        //      }
        //       publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'coverage/Icon-report', reportFiles: 'index.html', reportName: 'Code Coverage HTML Report', reportTitles: '', useWrapperFileDirectly: true])
        //     }
        // }
// this archive all reports always regardless of the outcome of the pipeline build
     
  }
      post {
          always {
              junit allowEmptyResults: true, stdioRetention: '', testResults: 'test-results.xml'
              junit allowEmptyResults: true, stdioRetention: '', testResults: 'dependency-check-junit.xml'
              publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'dependency-check-report.html', reportName: 'Dependency check HTML Report', reportTitles: '', useWrapperFileDirectly: true])
          }
      }
}
  
   // scan the package.json file which is at the root level
      // --scan \'./\'
  // print the output in all format 
  // --format \'ALL\'
  // pretty print the output to the console
  // --prettyPrint

//   stage ("OWASP Dependency Check") { 
//     steps {
//         1. Run the OWASP Dependency-Check tool
//         dependencyCheck additionalArguments: '''
//             --scan \'./\'           // Scan the current working directory
//             --out \'./\'            // Output reports in the current working directory
//             --format \'ALL\'        // Generate all possible report formats (XML, HTML, JSON, etc.)
//             --prettyPrint''',       // Generate human-readable reports
//             odcInstallation: 'OWAPS-Depend-check' // Reference the Dependency-Check tool installation in Jenkins

//         2. Publish the Dependency-Check results and stop the build if critical issues are found
//         dependencyCheckPublisher failedTotalCritical: 1, 
//                                  pattern: 'dependency-check-report.xml', // Scan the XML report file
//                                  stopBuild: true // Stop the build if the critical threshold is exceeded

//         3. Publish JUnit-style results to display test outcomes
//         junit allowEmptyResults: true, 
//               testResults: 'dependency-check-junit.xml'

//         4. Publish HTML reports to Jenkins for visibility
//         publishHTML([
//             allowMissing: true, 
//             alwaysLinkToLastBuild: true, 
//             keepAll: true, 
//             reportDir: './', // Location of the generated report
//             reportFiles: 'dependency-check-report.html', // HTML report to publish
//             reportName: 'Dependency check HTML Report', // Name displayed in Jenkins
//             useWrapperFileDirectly: true
//         ])
//     }
// }
