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
          sh 'docker run --rm --privileged multiarch/qemu-user-static --reset -p yes'
          sh 'docker buildx create --name multiarch --driver docker-container --use | true'
          sh 'docker buildx inspect --bootstrap'
          sh "docker buildx build --platform linux/arm64/v8 --no-cache --build-arg GRAYLOG_VERSION=\$(cat VERSION) --build-arg BUILD_DATE=\$(date -u +\"%Y-%m-%dT%H:%M:%SZ\") --tag graylog-multiarch-test:latest --file docker/oss/Dockerfile ."
        }
      }
   }
}
