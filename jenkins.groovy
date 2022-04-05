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
                      --push \
                      .
                """

                if (MAJOR_INT >= 4 && MINOR_INT >= 3)
                {
                  // Since 4.3 we build multi-platform images for Enterprise
                  sh """
                      docker buildx build \
                        --platform linux/amd64,linux/arm64/v8 \
                        --no-cache \
                        --build-arg GRAYLOG_VERSION=\$(./release.py --get-graylog-version) \
                        --build-arg BUILD_DATE=\$(date -u +\"%Y-%m-%dT%H:%M:%SZ\") \
                        ${TAG_ARGS_ENTERPRISE} \
                        --file docker/enterprise/Dockerfile \
                        --push \
                        .
                  """
                }
                else
                {
                  // Using buildx for a single platform always threw a
                  // HTTP 401 error during upload so we use build instead.
                  sh """
                      docker build \
                        --platform linux/amd64 \
                        --no-cache \
                        --build-arg GRAYLOG_VERSION=\$(./release.py --get-graylog-version) \
                        --build-arg BUILD_DATE=\$(date -u +\"%Y-%m-%dT%H:%M:%SZ\") \
                        ${TAG_ARGS_ENTERPRISE} \
                        --file docker/enterprise/Dockerfile \
                        .
                        docker push graylog/graylog-enterprise:${env.TAG_NAME}
                        docker push graylog/graylog-enterprise:${MAJOR}.${MINOR}.${PATCH}
                        docker push graylog/graylog-enterprise:${MAJOR}.${MINOR}
                  """
                }

                sh """
                    docker buildx build \
                      --platform linux/amd64,linux/arm64/v8 \
                      --no-cache \
                      --build-arg GRAYLOG_VERSION=\$(./release.py --get-graylog-version) \
                      --build-arg JAVA_VERSION_MAJOR=11 \
                      --build-arg BUILD_DATE=\$(date -u +\"%Y-%m-%dT%H:%M:%SZ\") \
                      ${TAG_ARGS_JRE11} \
                      --file docker/oss/Dockerfile \
                      --push \
                      .
                """

                if (MAJOR_INT >= 4 && MINOR_INT >= 3)
                {
                  // Since 4.3 we build multi-platform images for Enterprise
                  sh """
                    docker buildx build \
                      --platform linux/amd64,linux/arm64/v8 \
                      --no-cache \
                      --build-arg GRAYLOG_VERSION=\$(./release.py --get-graylog-version) \
                      --build-arg JAVA_VERSION_MAJOR=11 \
                      --build-arg BUILD_DATE=\$(date -u +\"%Y-%m-%dT%H:%M:%SZ\") \
                      ${TAG_ARGS_JRE11_ENTERPRISE} \
                      --file docker/enterprise/Dockerfile \
                      --push \
                      .
                  """
                }
                else
                {
                  // Using buildx for a single platform always threw a
                  // HTTP 401 error during upload so we use build instead.
                  sh """
                    docker build \
                      --platform linux/amd64 \
                      --no-cache \
                      --build-arg GRAYLOG_VERSION=\$(./release.py --get-graylog-version) \
                      --build-arg JAVA_VERSION_MAJOR=11 \
                      --build-arg BUILD_DATE=\$(date -u +\"%Y-%m-%dT%H:%M:%SZ\") \
                      ${TAG_ARGS_JRE11_ENTERPRISE} \
                      --file docker/enterprise/Dockerfile \
                      .
                      docker push graylog/graylog-enterprise:${env.TAG_NAME}-jre11
                      docker push graylog/graylog-enterprise:${MAJOR}.${MINOR}.${PATCH}-jre11
                      docker push graylog/graylog-enterprise:${MAJOR}.${MINOR}-jre11
                  """
                }
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
                    --build-arg GRAYLOG_FORWARDER_PACKAGE_VERSION=\$(./release.py --get-forwarder-version) \
                    --build-arg BUILD_DATE=\$(date -u +\"%Y-%m-%dT%H:%M:%SZ\") \
                    ${TAG_ARGS} \
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
