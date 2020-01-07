pipeline {
  agent {
    node {
      label 'jenkins-buildkit'
    }

  }
  stages {
    stage('Build') {
      when {
        anyOf {
          expression {
            return params.FORCE_CONTAINER_BUILD
          }

          changeset 'Dockerfile'
        }

      }
      steps {
        container(name: 'buildkit', shell: '/bin/sh') {
          sh '''buildctl-daemonless.sh build \\
	--frontend dockerfile.v0 \\
	--local context=. \\
	--local dockerfile=. \\
	--output type=image,name=${OUTPUT_REGISTRY}/nimbus-basic:${GIT_COMMIT:0:8},push=true \\
	--export-cache type=registry,ref=${OUTPUT_REGISTRY}/nimbus-basic:cache \\
	--import-cache type=registry,ref=${OUTPUT_REGISTRY}/nimbus-basic:cache'''
        }

      }
    }

    stage('Tag Latest') {
      when {
        branch 'master'
      }
      steps {
        container(name: 'buildkit', shell: '/bin/sh') {
          sh '''buildctl-daemonless.sh build \\
	--frontend dockerfile.v0 \\
	--local context=. \\
	--local dockerfile=. \\
	--output type=image,name=${OUTPUT_REGISTRY}/nimbus-basic:latest,push=true \\
	--import-cache type=registry,ref=${OUTPUT_REGISTRY}/nimbus-basic:cache'''
        }

      }
    }

  }
  parameters {
    booleanParam(name: 'FORCE_CONTAINER_BUILD', defaultValue: false, description: 'Force container build')
  }
}