def src = 'https://github.com/cloudhotspot/pypackage-docker.git'

node {
    git url: src

    // stage 'Build Base Images'
    // sh 'make image docker/base'
    // sh 'make image docker/dev'
    // sh 'make image docker/agent'

    try {
        stage 'Run Unit/Integration Tests'
        sh 'make test'
    } catch(all) {
        step([$class: 'JUnitResultArchiver', testResults: '**/src/*.xml'])
        error 'Test Failure'
    }
    
    stage 'Build Application Artefacts'
    sh 'make build'

    stage 'Build Runtime Artefacts'
    sh 'make release'

    step([$class: 'JUnitResultArchiver', testResults: '**/src/*.xml'])
}