def bob = new BobCommand().toString()

pipeline {
    agent {
        node {
            label params.SLAVE
        }
    }

    parameters {
        string(name: 'SETTINGS_CONFIG_FILE_NAME', defaultValue: 'maven.settings.eso')
        string(name: 'NEXUS3_ONAP_CONFIG_FILE_NAME', defaultValue: 'nexus3.onap.login.config')
    }

    environment {
        CHART_REPO = 'https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-so-gs-all-helm'
        CHART_NAME = 'eric-oss-pf-drools'

    }

    stages {
        stage('Inject Settings.xml File') {
            steps {
                configFileProvider([configFile(fileId: "${env.SETTINGS_CONFIG_FILE_NAME}", targetLocation: "${env.WORKSPACE}")]) {
                }
            }
        }

        stage('Clean') {
            steps {
                sh "${bob} clean"
                sh 'git clean -xdff --exclude=.m2 --exclude=.sonar --exclude=settings.xml --exclude=.docker --exclude=.kube'
            }
        }

        stage('Init') {
            steps {
                sh "${bob} init"
                archiveArtifacts 'artifact.properties'
            }
        }

        stage('Lint') {
            steps {
                sh "${bob} lint"
            }
        }
        stage('Build package and execute tests') {
            steps {
                sh "${bob} build"
            }
        }
        stage('ADP Helm Design Rule Check') {
            steps {
                sh "${bob} adp-helm-dr-check"
                archiveArtifacts 'design-rule-check-report.*'
            }
        }
        stage('Build image and chart') {
            steps {
                sh "${bob} image"
            }
        }
        /*
        stage('SonarQube full analysis') {
            steps {
                sh "${bob} sonar"
            }
        }
        */
        stage('Push image and chart (Using bob)') {
            when {
                expression { params.RELEASE == "true" }
            }
            steps {
                sh "${bob} package"
                echo "bob package was successful"
                sh "${bob} publish"
                echo "bob publish was successful"
            }
        }
    }
    //post {
    //    always {
    //        archiveArtifacts "**/target/surefire-reports/*"
    //        junit '**/target/surefire-reports/*.xml'
    //        step([$class: 'JacocoPublisher'])
    //    }
    //}
}

// More about @Builder: http://mrhaki.blogspot.com/2014/05/groovy-goodness-use-builder-ast.html
import groovy.transform.builder.Builder
import groovy.transform.builder.SimpleStrategy
@Builder(builderStrategy = SimpleStrategy, prefix = '')
class BobCommand {
    def bobImage = 'armdocker.rnd.ericsson.se/sandbox/adp-staging/adp-cicd/bob.2.0:1.7.0-20'
    def envVars = [:]
    def additionalVolumes = []
    def needDockerSocket = true
    // executes bob with --quiet parameter to reduce noise. Set to false if you need to get more details.
    def quiet = true
    String toString() {
        def env = envVars
                .collect({ entry -> "-e ${entry.key}=\"${entry.value}\"" })
                .join(' ')
        def volumes = additionalVolumes
                .collect({ line -> "-v \"${line}\"" })
                .join(' ')
        def cmd = """\
            |docker run
            |--init
            |--rm
            |--workdir \${PWD}
            |--user \$(set +x; id -u):\$(set +x; id -g)
            |-v \${PWD}:\${PWD}
            |-v /etc/group:/etc/group:ro
            |-v /etc/passwd:/etc/passwd:ro
            |-v \${HOME}/.docker:\${HOME}/.docker
            |${needDockerSocket ? '-v /var/run/docker.sock:/var/run/docker.sock' : ''}
            |${env}
            |${volumes}
            |\$(set +x; for group in \$(id -G); do printf ' --group-add %s' "\$group"; done)
            |${bobImage}
            |${quiet ? '--quiet' : ''}
            |"""
        return cmd
                .stripMargin()           // remove indentation
                .replace('\n', ' ')      // join lines
                .replaceAll(/[ ]+/, ' ') // replace multiple spaces by one
    }
}