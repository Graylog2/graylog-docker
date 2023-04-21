pipeline
{
   agent { label 'linux' }

   options
   {
      buildDiscarder logRotator(artifactDaysToKeepStr: '90', artifactNumToKeepStr: '100', daysToKeepStr: '90', numToKeepStr: '100')
      timestamps()
      timeout(time: 1, unit: 'HOURS')

      // The test exposes some hardcoded ports, so the tests can't be executed
      // at the same time on the same machine.
      lock('docker-integrations-test')
   }

   stages
   {
      stage('Build Docker Image')
      {
         when
         {
           not
           {
            buildingTag()
           }
         }
         steps
         {
            sh 'make docker_build'
         }
      }
      stage('Linter and Integration Test')
      {
         when
         {
           not
           {
            buildingTag()
           }
         }
         steps
         {
            sh 'make test'
         }
      }
      stage('Deploy image')
      {
        when
        {
          buildingTag()
        }

        steps
        {
          echo "TAG_NAME: ${TAG_NAME}"

          script
          {
            // Building Graylog (no tag suffix)
            if (TAG_NAME =~ /^(?:[4-9]|\\d{2,}).[0-9]+.[0-9]+-(?:[0-9]+|alpha|beta|rc).*/)
            {
              PARSED_VERSION = parse_version(TAG_NAME)
              MAJOR = PARSED_VERSION[0]
              MINOR = PARSED_VERSION[1]
              PATCH = PARSED_VERSION[2]
              echo "MAJOR: ${MAJOR}"
              echo "MINOR: ${MINOR}"
              echo "PATCH: ${PATCH}"

              MAJOR_INT = MAJOR as Integer
              MINOR_INT = MINOR as Integer

              //Is the revision suffix just a number?
              if (TAG_NAME =~ /^([4-9]|\d{2,}).([0-9]+).([0-9]+)-([0-9]+)$/)
              {
                TAG_ARGS                  = """--tag graylog/graylog:${env.TAG_NAME} \
                                            --tag graylog/graylog:${MAJOR}.${MINOR}.${PATCH} \
                                            --tag graylog/graylog:${MAJOR}.${MINOR}"""

                TAG_ARGS_DATANODE         = """--tag graylog/graylog-datanode:${env.TAG_NAME} \
                                            --tag graylog/graylog-datanode:${MAJOR}.${MINOR}.${PATCH} \
                                            --tag graylog/graylog-datanode:${MAJOR}.${MINOR}"""

                TAG_ARGS_ENTERPRISE       = """--tag graylog/graylog-enterprise:${env.TAG_NAME} \
                                             --tag graylog/graylog-enterprise:${MAJOR}.${MINOR}.${PATCH} \
                                             --tag graylog/graylog-enterprise:${MAJOR}.${MINOR}"""

              }
              else
              {
                //This is an alpha/beta/rc release, so don't update the version tags
                TAG_ARGS                  = "--tag graylog/graylog:${env.TAG_NAME}"
                TAG_ARGS_DATANODE         = "--tag graylog/graylog-datanode:${env.TAG_NAME}"
                TAG_ARGS_ENTERPRISE       = "--tag graylog/graylog-enterprise:${env.TAG_NAME}"
              }

              docker.withRegistry('', 'docker-hub')
              {
                sh 'docker run --rm --privileged multiarch/qemu-user-static --reset -p yes'
                sh 'docker buildx create --name multiarch --driver docker-container --use | true'
                sh 'docker buildx inspect --bootstrap'

                sh """
                    docker buildx build \
                      --platform linux/amd64,linux/arm64/v8 \
                      --no-cache \
                      --build-arg GRAYLOG_VERSION=\$(./release.py --get-graylog-version) \
                      --build-arg BUILD_DATE=\$(date -u +\"%Y-%m-%dT%H:%M:%SZ\") \
                      --build-arg VCS_REF=\$(git rev-parse HEAD) \
                      ${TAG_ARGS} \
                      --file docker/oss/Dockerfile \
                      --pull \
                      --push \
                      .
                """

/* Disabled until the datanode permission problems are fixed.
                sh """
                    docker buildx build \
                      --platform linux/amd64,linux/arm64/v8 \
                      --no-cache \
                      --build-arg GRAYLOG_VERSION=\$(./release.py --get-graylog-version) \
                      --build-arg BUILD_DATE=\$(date -u +\"%Y-%m-%dT%H:%M:%SZ\") \
                      --build-arg VCS_REF=\$(git rev-parse HEAD) \
                      ${TAG_ARGS_DATANODE} \
                      --file docker/datanode/Dockerfile \
                      --pull \
                      --push \
                      .
                """
*/

                sh """
                    docker buildx build \
                      --platform linux/amd64,linux/arm64/v8 \
                      --no-cache \
                      --build-arg GRAYLOG_VERSION=\$(./release.py --get-graylog-version) \
                      --build-arg BUILD_DATE=\$(date -u +\"%Y-%m-%dT%H:%M:%SZ\") \
                      --build-arg VCS_REF=\$(git rev-parse HEAD) \
                      ${TAG_ARGS_ENTERPRISE} \
                      --file docker/enterprise/Dockerfile \
                      --pull \
                      --push \
                      .
                """
              }
            }

            // Building the Forwarder (always a "forwarder-" tag suffix)
            if (TAG_NAME =~ /forwarder-.*/)
            {
              PARSED_VERSION = parse_forwarder_version(TAG_NAME)
              MAJOR = PARSED_VERSION[0]
              MINOR = PARSED_VERSION[1]
              CLEAN_TAG = TAG_NAME.replaceFirst("^forwarder-", "")
              echo "MAJOR: ${MAJOR}"
              echo "MINOR: ${MINOR}"

              IMAGE_NAME = "graylog/graylog-forwarder"

              TAG_ARGS = "--tag ${IMAGE_NAME}:${CLEAN_TAG}"

              if (TAG_NAME =~ /^forwarder-\d+.\d+-\d+$/)
              {
                // If we build a GA release (no alpha/beta/rc), we also add
                // the simple version tag.
                TAG_ARGS += " --tag ${IMAGE_NAME}:${MAJOR}.${MINOR}"
              }

              docker.withRegistry('', 'docker-hub')
              {
                sh 'docker run --rm --privileged multiarch/qemu-user-static --reset -p yes'
                sh 'docker buildx create --name multiarch --driver docker-container --use | true'
                sh 'docker buildx inspect --bootstrap'
                sh """
                  docker buildx build \
                    --platform linux/amd64,linux/arm64/v8 \
                    --no-cache \
                    --build-arg GRAYLOG_FORWARDER_VERSION=\$(./release.py --get-forwarder-version) \
                    --build-arg GRAYLOG_FORWARDER_IMAGE_VERSION=\$(./release.py --get-forwarder-image-version) \
                    --build-arg BUILD_DATE=\$(date -u +\"%Y-%m-%dT%H:%M:%SZ\") \
                    --build-arg VCS_REF=\$(git rev-parse HEAD) \
                    ${TAG_ARGS} \
                    --file docker/forwarder/Dockerfile \
                    --pull \
                    --push \
                    .
                """
              }
            }
          }
        }
      }
   }

   post
   {
       always
       {
           cleanWs()
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
    // Matches the following version patterns:
    //
    //   forwarder-4.8-1
    //   forwarder-4.8-rc.1-1
    def pattern = /^forwarder-([0-9]+).([0-9]+)-?(?:[^-]+)?-([0-9]+)$/
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
