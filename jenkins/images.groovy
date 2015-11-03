def src = 'https://github.com/cloudhotspot/pypackage-docker.git'

node {
    git url: src

    stage 'Build Base Images'
    sh 'make image docker/base'
    sh 'make image docker/dev'
    sh 'make image docker/agent'
}