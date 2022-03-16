stage('push') {
    withCredentials([usernamePassword(credentialsId: 'genericCreds', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USER')]) {
    sh "git fetch --prune origin 'refs/tags/*:refs/tags/*' '+refs/heads/*:refs/remotes/origin/*'"
    sh "git add -A"
    sh "git -c user.name='generic' -c user.email='my@email.org' commit -m 'Synchronization with HIERADATA'"
    sh "git push 'https://${GIT_USER}:${GIT_PASSWORD}@${gitRepo}' HEAD:master"
}

stage('Bump version and push') {
                    withCredentials([usernamePassword(credentialsId: 'genericCreds', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USER')]) {
                        sh "git fetch --prune origin 'refs/tags/*:refs/tags/*' '+refs/heads/*:refs/remotes/origin/*'"
                        sh "su automation -c \"bumpversion ${release_type} --allow-dirty\""
                        
                        // push version update and clean pipeline var
                        sh """sed -i 's/^run_pipeline[" "]*=[" "]*true/run_pipeline=false/I' jenkins/job.properties"""

                        sh "git add VERSION setup.cfg jenkins/job.properties setup.py"
                        sh 'git commit -m "Version "`cat VERSION`'
                        sh "git push 'https://${GIT_USER}:${GIT_PASSWORD}@${gitRepo}' HEAD:master"

                        // tag creation
                        if (!release_type.startsWith('dev')) {
                            sh "su automation -c \"bumpversion release --tag --tag-name=`cat VERSION` --allow-dirty\""
                            sh "git push 'https://${GIT_USER}:${GIT_PASSWORD}@${gitRepo}' `cat VERSION`"
                        }
