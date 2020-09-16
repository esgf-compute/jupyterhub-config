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

    stage('Containers') {
      when {
        anyOf {
          branch 'master'
          branch 'devel'
        }
      }
      stage('nimbus-base') {
        agent {
          node {
            label 'jenkins-buildkit'
          }
        } 
        when {
          changeset 'dockerfiles/nimbus_base/*'
        }
        steps {
          container(name: 'buildkit', shell: '/bin/sh') {
            sh 'cp /ssl/*.crt .'

            sh '''#! /bin/sh
make build-base
            '''
        }
      }
      stage('nimbus-cdat') {
        agent {
          node {
            label 'jenkins-buildkit'
          }
        }
        when {
          anyOf {
            changeset 'dockerfiles/nimbus_base/*'
            changeset 'dockerfiles/nimbus_cdat/*'
          }
        }
        steps {
          container(name: 'buildkit', shell: '/bin/sh') {
            sh 'cp /ssl/*.crt .'

            sh '''#! /bin/sh
make build-cat
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
        when {
          anyOf {
            changeset 'dockerfiles/nimbus_base/*'
            changeset 'dockerfiles/nimbus_dev/*'
          }
        }
        steps {
          container(name: 'buildkit', shell: '/bin/sh') {
            sh 'cp /ssl/*.crt .'

            sh '''#! /bin/sh
make build-dev
            '''
          }
        }
      }
    }
  }
}
