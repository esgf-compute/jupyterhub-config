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

make build-search CONDA_TOKEN=${CONDA_TOKEN}'''
        }

      }
    }

    stage('Development Container') {
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
TAG="$(cat dockerfiles/nimbus_jupyterlab/VERSION)_dev"

make build-jupyterlab REGISTRY=${REGISTRY_PRIVATE} VERSION=${TAG}'''
        }

      }
    }

    stage('Release Container') {
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
TAG="$(cat dockerfiles/nimbus_jupyterlab/VERSION)

make build-jupyterlab REGISTRY=${REGISTRY_PRIVATE} VERSION=${TAG}'''
        }

      }
    }

  }
  parameters {
    booleanParam(name: 'FORCE_BUILD_JUPYTER', defaultValue: false, description: 'Force building container')
    booleanParam(name: 'FORCE_BUILD_CONDA', defaultValue: false, description: 'Force building conda package')
  }
}
