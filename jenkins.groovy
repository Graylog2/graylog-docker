pipeline
{
   agent { label 'linux' }

   options
   {
      buildDiscarder logRotator(artifactDaysToKeepStr: '90', artifactNumToKeepStr: '100', daysToKeepStr: '90', numToKeepStr: '100')
      timestamps()
      timeout(time: 1, unit: 'HOURS')
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
            if (TAG_NAME =~ /^(?:[4-9]|\\d{2,}).[0-9]+.[0-9]+-(?:[0-9]+|alpha|beta|rc).*/)
            {
              PARSED_VERSION = parse_version(TAG_NAME)
              MAJOR = PARSED_VERSION[0]
              MINOR = PARSED_VERSION[1]
              PATCH = PARSED_VERSION[2]
              echo "MAJOR: ${MAJOR}"
              echo "MINOR: ${MINOR}"
              echo "PATCH: ${PATCH}"

              //Is the revision suffix just a number?
              if (TAG_NAME =~ /^([4-9]|\d{2,}).([0-9]+).([0-9]+)-([0-9]+)$/)
              {
                TAG_ARGS                  = """--tag graylog/graylog:${env.TAG_NAME} \
                                            --tag graylog/graylog:${MAJOR}.${MINOR}.${PATCH} \
                                            --tag graylog/graylog:${MAJOR}.${MINOR}"""

                TAG_ARGS_ENTERPRISE       = """--tag graylog/graylog-enterprise:${env.TAG_NAME} \
                                             --tag graylog/graylog-enterprise:${MAJOR}.${MINOR}.${PATCH} \
                                             --tag graylog/graylog-enterprise:${MAJOR}.${MINOR}"""
                TAG_ARGS_JRE11            = """--tag graylog/graylog:${env.TAG_NAME}-jre11 \
                                             --tag graylog/graylog:${MAJOR}.${MINOR}.${PATCH}-jre11 \
                                             --tag graylog/graylog:${MAJOR}.${MINOR}-jre11"""
                TAG_ARGS_JRE11_ENTERPRISE = """--tag graylog/graylog-enterprise:${env.TAG_NAME}-jre11 \
                                               --tag graylog/graylog-enterprise:${MAJOR}.${MINOR}.${PATCH}-jre11 \
                                               --tag graylog/graylog-enterprise:${MAJOR}.${MINOR}-jre11"""

              }
              else
              {
                //This is an alpha/beta/rc release, so don't update the version tags
                TAG_ARGS                  = "--tag graylog/graylog:${env.TAG_NAME}"
                TAG_ARGS_ENTERPRISE       = "--tag graylog/graylog-enterprise:${env.TAG_NAME}"
                TAG_ARGS_JRE11            = "--tag graylog/graylog:${env.TAG_NAME}-jre11"
                TAG_ARGS_JRE11_ENTERPRISE = "--tag graylog/graylog-enterprise:${env.TAG_NAME}-jre11"
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
                      ${TAG_ARGS} \
                      --file docker/oss/Dockerfile \
                      --pull \
                      --push \
                      .
                """

                sh """
                    docker build \
                      --platform linux/amd64 \
                      --no-cache \
                      --build-arg GRAYLOG_VERSION=\$(./release.py --get-graylog-version) \
                      --build-arg BUILD_DATE=\$(date -u +\"%Y-%m-%dT%H:%M:%SZ\") \
                      ${TAG_ARGS_ENTERPRISE} \
                      --file docker/enterprise/Dockerfile \
                      --pull \
                      .
                      docker push graylog/graylog-enterprise:${env.TAG_NAME}
                      docker push graylog/graylog-enterprise:${MAJOR}.${MINOR}.${PATCH}
                      docker push graylog/graylog-enterprise:${MAJOR}.${MINOR}
                """

                sh """
                    docker buildx build \
                      --platform linux/amd64,linux/arm64/v8 \
                      --no-cache \
                      --build-arg GRAYLOG_VERSION=\$(./release.py --get-graylog-version) \
                      --build-arg JAVA_VERSION_MAJOR=11 \
                      --build-arg BUILD_DATE=\$(date -u +\"%Y-%m-%dT%H:%M:%SZ\") \
                      ${TAG_ARGS_JRE11} \
                      --file docker/oss/Dockerfile \
                      --pull \
                      --push \
                      .
                """

                sh """
                  docker build \
                    --platform linux/amd64 \
                    --no-cache \
                    --build-arg GRAYLOG_VERSION=\$(./release.py --get-graylog-version) \
                    --build-arg JAVA_VERSION_MAJOR=11 \
                    --build-arg BUILD_DATE=\$(date -u +\"%Y-%m-%dT%H:%M:%SZ\") \
                    ${TAG_ARGS_JRE11_ENTERPRISE} \
                    --file docker/enterprise/Dockerfile \
                    --pull \
                    .
                    docker push graylog/graylog-enterprise:${env.TAG_NAME}-jre11
                    docker push graylog/graylog-enterprise:${MAJOR}.${MINOR}.${PATCH}-jre11
                    docker push graylog/graylog-enterprise:${MAJOR}.${MINOR}-jre11
                """
              }
            }

            if (TAG_NAME =~ /forwarder-.*/)
            {
              PARSED_VERSION = parse_forwarder_version(TAG_NAME)
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
                    --platform linux/amd64,linux/arm64/v8 \
                    --no-cache \
                    --build-arg GRAYLOG_FORWARDER_PACKAGE_VERSION=\$(./release.py --get-forwarder-version) \
                    --build-arg BUILD_DATE=\$(date -u +\"%Y-%m-%dT%H:%M:%SZ\") \
                    --tag graylog/graylog-forwarder:${env.TAG_NAME}-arm64 \
                    --tag graylog/graylog-forwarder:${MAJOR}.${MINOR}-arm64 \
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
