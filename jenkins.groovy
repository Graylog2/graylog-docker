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
         steps
         {
            sh 'make docker_build'
         }
      }

      stage('Linter and Integration Test')
      {
         steps
         {
            sh 'make test'
         }
      }
   }
}
