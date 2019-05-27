# CI/CD - Pipelines
This is the configuration directory for pipelines apps

# Procedure of pipeline deploy

1. Copy from directory defined templates according to your app architecture:
  * Maven
  * NodeJS
  * lib archives

```
# Copy the content from maven template to your new app
cp -Rpvf templates/template-maven NEW_APP
```

2. Replace the field  "@app@" by the app name
```
# sed 's /@app/NEW_APP/g app-pipeline.yaml
```

3. Replace the field "@git@" by the git repository (in the next future i update with a app test)
```
# sed 's /@git@/http://github.com/app.git/g' app-pipeline.yaml
```

4. Deploy pipeline
```
cd NEW_APP
./deploy.sh
```

## COMENT:

To project who follows the default libs archive, confirm if a configuration of repository is:

```
 <distributionManagement>
                <repository>
                        <id>nexus</id>
                        <url>http://nexus.yourdomain.com:8081/repository/maven-releases</url>
                </repository>
                <snapshotRepository>
                        <id>nexus</id>
                        <url>http://nexus.yourdomain.com:8081/repository/maven-snapshots</url>
                </snapshotRepository>
</distributionManagement>
```
