/*
 * This is a Declarative Jenkinsfile for a .NET application.
 *
 * It is designed to run on Pull Requests targeting the 'develop' branch.
 *
 * It will:
 * 1. Restore .NET dependencies.
 * 2. Build the project.
 * 3. Run unit tests.
 * 4. Declare the PR 'HEALTHY' or 'FAULTY' based on the outcome.
 */

pipeline {
    // 1. Agent Configuration
    // Use any available agent. You can change this to a specific label
    // like 'windows' or 'dotnet-agent' if required.
    agent any

    // 2. Environment
    // We define a variable to hold the final status of our PR.
    environment {
        PR_STATUS = 'PENDING'
    }

    // 3. Trigger/When
    // This 'when' directive ensures this pipeline ONLY runs for
    // Pull Requests that are targeting the 'develop' branch.
    when {
        changeRequest target: 'develop'
    }

    // 4. Stages
    // We wrap the build and test logic in a single stage with
    // try/catch blocks to get the specific failure reason.
    stages {
        stage('Build & Test') {
            steps {
                // We need a 'script' block to use try/catch
                script {
                    try {
                        // === BUILD STAGE ===
                        echo "--- 1. Restoring .NET Dependencies ---"
                        sh "dotnet restore"

                        echo "--- 2. Building Project ---"
                        // --no-restore to speed up the build
                        sh "dotnet build --no-restore"
                        echo "--- Build Succeeded ---"

                        // === TEST STAGE ===
                        // This 'try' block runs only if the build was successful.
                        try {
                            echo "--- 3. Running Tests ---"
                            // --no-build as the project is already built
                            sh "dotnet test --no-build"
                            echo "--- Tests Succeeded ---"

                            // If we get here, both build and tests passed.
                            PR_STATUS = 'HEALTHY'

                        } catch (e) {
                            // This block catches TEST failures.
                            echo "--- Tests Failed ---"
                            PR_STATUS = 'FAULTY (Testing Failed)'
                            // Manually fail the pipeline
                            currentBuild.result = 'FAILURE'
                            echo "Error: ${e.message}"
                        }

                    } catch (e) {
                        // This block catches BUILD failures.
                        echo "--- Build Failed ---"
                        PR_STATUS = 'FAULTY (Build Failed)'
                        // Manually fail the pipeline (though it's already failed)
                        currentBuild.result = 'FAILURE'
                        echo "Error: ${e.message}"
                    }
                }
            }
        }
    }

    // 5. Post-Build Actions
    // This 'post' block runs after all stages are complete.
    post {
        // 'always' runs regardless of whether the pipeline succeeded or failed.
        always {
            script {
                echo "--- Final PR Status: ${PR_STATUS} ---"

                // In a real-world setup, you would use a plugin here
                // to post this status back to GitHub, GitLab, or Bitbucket.
                // For example (using GitHub plugin - pseudo-code):
                //
                if (PR_STATUS == 'HEALTHY') {
                  githubNotify context: 'Jenkins CI', message: 'Build and Tests passed!', status: 'SUCCESS'
                } else {
                  githubNotify context: 'Jenkins CI', message: "PR is ${PR_STATUS}", status: 'FAILURE'
                }

                echo "This PR has been declared: ${PR_STATUS}"
            }
        }
    }
}