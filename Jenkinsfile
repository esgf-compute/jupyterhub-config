pipeline {
  agent none
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

make build-search'''
        }

      }
    }

    stage('Build Container') {
      parallel {
        stage('Development') {
          agent {
            node {
              label 'jenkins-buildkit'
            }

          }
          when {
            branch 'devel'
            anyOf {
              expression {
                return params.FORCE_BUILD_JUPYTER
              }

              changeset 'dockerfiles/nimbus_jupyterlab/Dockerfile'
              changeset '**/esgf_search/**'
            }

          }
          steps {
            container(name: 'buildkit', shell: '/bin/sh') {
              sh '''#! /bin/sh

make build-jupyterlab TAG_PREFIX=-dev REGISTRY=${OUTPUT_REGISTRY}'''
            }

          }
        }

        stage('Latest') {
          agent {
            node {
              label 'jenkins-buildkit'
            }

          }
          when {
            branch 'master'
            anyOf {
              expression {
                return params.FORCE_BUILD_JUPYTER
              }

              changeset 'dockerfiles/nimbus_jupyterlab/Dockerfile'
              changeset '**/esgf_search/**'
            }

          }
          steps {
            container(name: 'buildkit', shell: '/bin/sh') {
              sh '''#! /bin/sh

make build-jupyterlab REGISTRY=${OUTPUT_REGISTRY}

make build-jupyterlab VERSION=latest REGISTRY=${OUTPUT_REGISTRY}'''
            }

          }
        }

      }
    }

  }
  parameters {
    booleanParam(name: 'FORCE_BUILD_JUPYTER', defaultValue: false, description: 'Force building container')
    booleanParam(name: 'FORCE_BUILD_CONDA', defaultValue: false, description: 'Force building conda package')
    booleanParam(name: 'FORCE_BUILD_CONDA_PUBLISH', defaultValue: false, description: 'Force building conda package and publish')
  }
}