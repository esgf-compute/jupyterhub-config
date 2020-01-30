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
            branch 'devel'
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

make build-search TARGET=build'''
            }

          }
        }

        stage('Publish') {
          when {
            branch 'master'
            anyOf {
              expression {
                return params.FORCE_BUILD_CONDA_PUBLISH
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

make build-search TARGET=publish'''
            }

          }
        }

      }
    }

    stage('Build Container') {
      parallel {
        stage('Development') {
          when {
            branch 'devel'
            anyOf {
              expression {
                return params.FORCE_BUILD_JUPYTER
              }

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

        stage('Latest') {
          when {
            branch 'master'
            anyOf {
              expression {
                return params.FORCE_BUILD_JUPYTER
              }

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
    }

  }
  parameters {
    booleanParam(name: 'FORCE_BUILD_JUPYTER', defaultValue: false, description: 'Force building container')
    booleanParam(name: 'FORCE_BUILD_CONDA', defaultValue: false, description: 'Force building conda package')
    booleanParam(name: 'FORCE_BUILD_CONDA_PUBLISH', defaultValue: false, description: 'Force building conda package and publish')
  }
}