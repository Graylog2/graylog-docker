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
      stage('Linter and Integration Test')
      {
         steps
         {
            sh 'make test'
         }
      }
      stage('Deploy image')
      {
        when
        {
          tag pattern: "/^(?:[4-9]|\d{2,}).[0-9]+.[0-9]+-(?:[0-9]+|alpha|beta|rc).*/", comparator: "REGEXP"
        }

        sh 'docker run --rm --privileged multiarch/qemu-user-static --reset -p yes'
        sh 'docker buildx create --name multiarch --driver docker-container --use'
        sh 'docker buildx inspect --bootstrap'
        sh "docker buildx build --platform linux/arm64/v8 --no-cache --build-arg GRAYLOG_VERSION=$(cat VERSION) --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") --tag graylog-multiarch-test:latest --file /tmp/graylog-docker/docker/oss/Dockerfile ."
      }
   }
}
