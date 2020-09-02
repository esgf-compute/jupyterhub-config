pipeline {
  agent none
  environment {
    REGISTRY = "${env.REGISTRY_PRIVATE}"
  }
  stages {
    stage('Publish Search') {
      agent {
        node {
          label 'jenkins-buildkit'
        }

      }
      when {
        branch 'master'
        anyOf {
          expression {
            return params.FORCE_BUILD_CONDA
          }

          changeset '**/esgf_search/**'
        }

      }
      environment {
        CONDA_TOKEN = credentials('conda-token')
      }
      steps {
        container(name: 'buildkit', shell: '/bin/sh') {
          sh '''#! /bin/sh
make build-search CONDA_TOKEN=${CONDA_TOKEN}
          '''
        }

      }
    }

    stage('Development Containers') {
      when {
        branch 'devel'
      }
      parallel {
        stage('nimbus-jupyter') {
          agent {
            node {
              label 'jenkins-buildkit'
            }
          }
          steps {
            container(name: 'buildkit', shell: '/bin/sh') {
              sh '''#! /bin/sh
make build-jupyterlab VERSION=$(cat dockerfiles/nimbus_jupyterlab/VERSION)-dev
              '''
            }
          }
        }
        stage('nimbus-dev') {
          agent {
            node {
              label 'jenkins-buildkit'
            }
          }
          steps {
            container(name: 'buildkit', shell: '/bin/sh') {
              sh '''#! /bin/sh
cp /ssl/*.crt .
make build-dev
              '''
            }
          }
        }
      }
    }

    stage('Release Containers') {
      agent {
        node {
          label 'jenkins-buildkit'
        }

      }
      when {
        branch 'master'
        anyOf {
          changeset 'dockerfiles/nimbus_jupyterlab/Dockerfile'
          changeset '**/esgf_search/**'
        }

      }
      steps {
        container(name: 'buildkit', shell: '/bin/sh') {
          sh '''#! /bin/sh
make build-jupyterlab
          '''
        }

      }
    }

  }
}
