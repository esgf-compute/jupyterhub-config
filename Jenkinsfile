pipeline {
  agent {
    node {
      label 'jenkins-buildkit'
    }

  }
  stages {
    stage('Build Conda') {
      when {
        anyOf {
          expression {
            return params.FORCE_BUILD_CONDA
          }

          changeset '**/src/esgf_search/**'
        }

      }
      environment {
        CONDA = credentials('conda')
      }
      steps {
        container(name: 'buildkit', shell: '/bin/sh') {
          sh '''#! /bin/sh

make'''
        }

      }
    }

    stage('Build Container') {
      when {
        anyOf {
          expression {
            return params.FORCE_BUILD_JUPYTER
          }

          changeset 'Dockerfile'
          changeset '**/src/esgf_search/**'
        }

      }
      steps {
        container(name: 'buildkit', shell: '/bin/sh') {
          sh '''#! /bin/sh

make build-container'''
        }

      }
    }

  }
  parameters {
    booleanParam(name: 'FORCE_BUILD_JUPYTER', defaultValue: false, description: 'Force building container')
    booleanParam(name: 'FORCE_BUILD_CONDA', defaultValue: false, description: 'Force building conda package')
  }
}