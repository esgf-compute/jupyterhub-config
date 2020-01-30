pipeline {
  agent {
    node {
      label 'jenkins-buildkit'
    }

  }
  stages {
    stage('Build Conda') {
      parallel {
        stage('Build') {
          when {
            anyOf {
              expression {
                return params.FORCE_BUILD_CONDA
              }

              branch 'devel'
              changeset '**/esgf_search/**'
            }

          }
          environment {
            CONDA_TOKEN = credentials('conda-token')
          }
          steps {
            container(name: 'buildkit', shell: '/bin/sh') {
              sh '''#! /bin/sh

make build-search TARGET=build'''
            }

          }
        }

        stage('Publish') {
          when {
            anyOf {
              expression {
                return params.FORCE_BUILD_CONDA_PUBLISH
              }

              branch 'master'
              changeset '**/esgf_search/**'
            }

          }
          environment {
            CONDA_TOKEN = credentials('conda-token')
          }
          steps {
            container(name: 'buildkit', shell: '/bin/sh') {
              sh '''#! /bin/sh

make build-search TARGET=publish'''
            }

          }
        }

      }
    }

    stage('Build Container') {
      when {
        anyOf {
          expression {
            return params.FORCE_BUILD_JUPYTER
          }

          branch 'master'
          changeset 'Dockerfile'
          changeset '**/esgf_search/**'
        }

      }
      steps {
        container(name: 'buildkit', shell: '/bin/sh') {
          sh '''#! /bin/sh

make build-jupyterhub'''
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