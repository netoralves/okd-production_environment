# CI/CD OKD 3.10
This repository include pipelines to continuous delivery use Jenkins, Nexus(external) and SonarQube on OKD 3.10...

# Pipeline Maven and NodeJS
![](images/workflow-default.png?raw=true)

# Pipeline Commons library
![](images/workflow-archive.png?raw=true)

  ```
# Create a Projects
  oc new-project stage --display-name="Stage"
  oc new-project prod --display-name="Production"
  oc new-project cicd --display-name="CI/CD"

 # Grants privilegies to access jenkins on projects
  oc policy add-role-to-user edit system:serviceaccount:cicd:jenkins -n stage
  oc policy add-role-to-user edit system:serviceaccount:cicd:jenkins -n prod
  ```
