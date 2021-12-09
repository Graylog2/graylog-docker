pipeline
{
   agent { label 'linux' }

   options
   {
      buildDiscarder logRotator(artifactDaysToKeepStr: '90', artifactNumToKeepStr: '100', daysToKeepStr: '90', numToKeepStr: '100')
      skipDefaultCheckout(true)
      timestamps()
   }

   parameters
   {
     string(name: 'TAG_NAME', description: 'The git tag to add to the graylog-docker repo (4.2.2-1, 4.3.0-1, etc).')
     gitParameter branchFilter: 'origin/(.*)', defaultValue: '4.2', selectedValue: 'DEFAULT', name: 'BRANCH', type: 'PT_BRANCH', sortMode: 'DESCENDING_SMART', description: 'The branch of graylog-docker that should be checked out (4.1, 4.2, master, etc).'
   }

   stages
   {
      stage('Pre-release Stage')
      {
         steps
         {
           script
           {
             checkout([$class: 'GitSCM', branches: [[name: "refs/heads/${params.BRANCH}"]], extensions: [[$class: 'WipeWorkspace']], userRemoteConfigs: [[url: 'https://github.com/Graylog2/graylog-docker.git']]])
           }

            //update version.yml
            //sh './release.py --update-major-version 4 --update-minor-version 2 --update-patch-version 2'

            env.GRAYLOG_VERSION = sh returnStdout: true, script: './release.py --get-graylog-version'
            env.FORWARDER_VERSION = sh returnStdout: true, script: './release.py --get-forwarder-version'

            sh './release.py --generate-readme'

            //commit changes

            //add new git tag

            //push git changes

         }
      }

      stage('Deploy Image')
      {
        steps
        {
          script
          {
            checkout([$class: 'GitSCM', branches: [[name: "refs/heads/${params.TAG_NAME}"]], extensions: [[$class: 'WipeWorkspace']], userRemoteConfigs: [[url: 'https://github.com/Graylog2/graylog-docker.git']]])
          }

          script
          {
            if (${params.TAG_NAME} =~ /^(?:[4-9]|\\d{2,}).[0-9]+.[0-9]+-(?:[0-9]+|alpha|beta|rc).*/)
            {
              PARSED_VERSION = parse_version(${params.TAG_NAME})
              MAJOR = PARSED_VERSION[0]
              MINOR = PARSED_VERSION[1]
              PATCH = PARSED_VERSION[2]
              echo "MAJOR: ${MAJOR}"
              echo "MINOR: ${MINOR}"
              echo "PATCH: ${PATCH}"

              //Is the revision suffix just a number?
              if (${params.TAG_NAME} =~ /^([4-9]|\d{2,}).([0-9]+).([0-9]+)-([0-9]+)$/)
              {
                TAG_ARGS_ARM              = """--tag graylog/graylog:${params.TAG_NAME}-arm64 \
                                            --tag graylog/graylog:${MAJOR}.${MINOR}.${PATCH}-arm64 \
                                            --tag graylog/graylog:${MAJOR}.${MINOR}-arm64"""

                TAG_ARGS_ARM_ENTERPRISE   = """--tag graylog/graylog-enterprise:${params.TAG_NAME}-arm64 \
                                             --tag graylog/graylog-enterprise:${MAJOR}.${MINOR}.${PATCH}-arm64 \
                                             --tag graylog/graylog-enterprise:${MAJOR}.${MINOR}-arm64"""
                TAG_ARGS_JRE11            = """--tag graylog/graylog:${params.TAG_NAME}-jre11 \
                                             --tag graylog/graylog:${MAJOR}.${MINOR}.${PATCH}-jre11 \
                                             --tag graylog/graylog:${MAJOR}.${MINOR}-jre11"""
                TAG_ARGS_JRE11_ENTERPRISE = """--tag graylog/graylog-enterprise:${params.TAG_NAME}-jre11 \
                                               --tag graylog/graylog-enterprise:${MAJOR}.${MINOR}.${PATCH}-jre11 \
                                               --tag graylog/graylog-enterprise:${MAJOR}.${MINOR}-jre11"""

              }
              else
              {
                //This is an alpha/beta/rc release, so don't update the version tags
                TAG_ARGS_ARM              = "--tag graylog/graylog:${params.TAG_NAME}-arm64"
                TAG_ARGS_ARM_ENTERPRISE   = "--tag graylog/graylog-enterprise:${env.TAG_NAME}-arm64"
                TAG_ARGS_JRE11            = "--tag graylog/graylog:${params.TAG_NAME}-jre11"
                TAG_ARGS_JRE11_ENTERPRISE = "--tag graylog/graylog-enterprise:${env.TAG_NAME}-jre11"
              }

              docker.withRegistry('', 'docker-hub')
              {
                sh 'docker run --rm --privileged multiarch/qemu-user-static --reset -p yes'
                sh 'docker buildx create --name multiarch --driver docker-container --use | true'
                sh 'docker buildx inspect --bootstrap'
                sh """
                    docker buildx build \
                      --platform linux/arm64/v8 \
                      --no-cache \
                      --build-arg GRAYLOG_VERSION=${env.GRAYLOG_VERSION} \
                      --build-arg BUILD_DATE=\$(date -u +\"%Y-%m-%dT%H:%M:%SZ\") \
                      ${TAG_ARGS_ARM} \
                      --file docker/oss/Dockerfile \
                      --push \
                      .
                """

                sh """
                    docker buildx build \
                      --platform linux/arm64/v8 \
                      --no-cache \
                      --build-arg GRAYLOG_VERSION=${env.GRAYLOG_VERSION} \
                      --build-arg BUILD_DATE=\$(date -u +\"%Y-%m-%dT%H:%M:%SZ\") \
                      ${TAG_ARGS_ARM_ENTERPRISE} \
                      --file docker/enterprise/Dockerfile \
                      --push \
                      .
                """

                sh """
                    docker buildx build \
                      --platform linux/amd64,linux/arm64/v8 \
                      --no-cache \
                      --build-arg GRAYLOG_VERSION=${env.GRAYLOG_VERSION} \
                      --build-arg JAVA_VERSION_MAJOR=11 \
                      --build-arg BUILD_DATE=\$(date -u +\"%Y-%m-%dT%H:%M:%SZ\") \
                      ${TAG_ARGS_JRE11} \
                      --file docker/oss/Dockerfile \
                      --push \
                      .
                """

                sh """
                  docker buildx build \
                    --platform linux/amd64,linux/arm64/v8 \
                    --no-cache \
                    --build-arg GRAYLOG_VERSION=${env.GRAYLOG_VERSION} \
                    --build-arg JAVA_VERSION_MAJOR=11 \
                    --build-arg BUILD_DATE=\$(date -u +\"%Y-%m-%dT%H:%M:%SZ\") \
                    ${TAG_ARGS_JRE11_ENTERPRISE} \
                    --file docker/enterprise/Dockerfile \
                    --push \
                    .
                """
              }
            }

            if (${params.TAG_NAME} =~ /forwarder-.*/)
            {
              PARSED_VERSION = parse_forwarder_version(${params.TAG_NAME})
              MAJOR = PARSED_VERSION[0]
              MINOR = PARSED_VERSION[1]
              PATCH = PARSED_VERSION[2]
              echo "MAJOR: ${MAJOR}"
              echo "MINOR: ${MINOR}"
              echo "PATCH: ${PATCH}"

              docker.withRegistry('', 'docker-hub')
              {
                sh """
                  docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
                  docker buildx create --name multiarch --driver docker-container --use | true
                  docker buildx inspect --bootstrap
                  docker buildx build \
                    --platform linux/arm64/v8 \
                    --no-cache \
                    --build-arg GRAYLOG_FORWARDER_PACKAGE_VERSION=${env.FORWARDER_VERSION} \
                    --build-arg BUILD_DATE=\$(date -u +\"%Y-%m-%dT%H:%M:%SZ\") \
                    --tag graylog/graylog-forwarder:${params.TAG_NAME}-arm64 \
                    --tag graylog/graylog-forwarder:${MAJOR}.${MINOR}-arm64 \
                    --file docker/forwarder/Dockerfile \
                    --push \
                    .
                """
              }

            }
          }
        }
      }

   }
}

// Parse a string containing a semantic version
def parse_version(version)
{
  if (version)
  {
    def pattern = /^([4-9]|\d\{2,\}+).([0-9]+).([0-9]+)-?.*$/
    def matcher = java.util.regex.Pattern.compile(pattern).matcher(version)

    if (matcher.find()) {
      return [matcher.group(1), matcher.group(2), matcher.group(3)]
    } else {
      return null
    }
  }
  else
  {
    return null
  }
}

// Parse a string containing the forwarder version
def parse_forwarder_version(version)
{
  if (version)
  {
    def pattern = /^forwarder-([0-9]+).([0-9]+)-([0-9]+)$/
    def matcher = java.util.regex.Pattern.compile(pattern).matcher(version)

    if (matcher.find()) {
      return [matcher.group(1), matcher.group(2), matcher.group(3)]
    } else {
      return null
    }
  }
  else
  {
    return null
  }
}
