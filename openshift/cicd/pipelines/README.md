# CI/CD - Pipelines
Este é o diretório com as configurações das aplicações com Pipelines definidos.


# Procedimento de implantação do Pipeline

1. Copie da pasta templates um dos 2 templates configurados, de acordo com a arquitetura do seu aplicativo:
  * Maven
  * NodeJS

```
# Copiar o conteudo do template maven para uma nova aplicação
cp -Rpvf templates/template-maven NOME_APP
```

2. Substitua os campos "app" pelo nome da aplicação
```
# sed 's /app/NOME_APP/g app-pipeline.yaml
```

3. Implante o pipeline
```
cd NOME_APP
./deploy.sh
```

## Observações:

Para projetos que seguem o padrão archive de bibliotecas, confirmar se a configuração de repositório esta da seguinte forma:

```
 <distributionManagement>
                <repository>
                        <id>nexus</id>
                        <url>http://nexus.somoscooperativismo.coop.br:8081/repository/maven-releases</url>
                </repository>
                <snapshotRepository>
                        <id>nexus</id>
                        <url>http://nexus.somoscooperativismo.coop.br:8081/repository/maven-snapshots</url>
                </snapshotRepository>
</distributionManagement>
```
