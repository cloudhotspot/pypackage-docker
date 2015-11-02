def src = 'https://github.com/cloudhotspot/pypackage-docker.git'

node {
    try {
        git url: src

        stage 'Build Base Images'
        sh 'make image docker/base'
        sh 'make image docker/dev'
        sh 'make image docker/agent'

        stage 'Run Unit/Integration Tests'
        sh 'make test'

        stage 'Build Application Artefacts'
        sh 'make build'

        stage 'Build Runtime Artefacts'
        sh 'make release'
    } catch {
        step([$class: 'JUnitResultArchiver', testResults: '**/src/*.xml'])
    } finally {
        step([$class: 'JUnitResultArchiver', testResults: '**/src/*.xml'])
    }

}