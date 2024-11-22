# Microservice-Based-Password-Manager-with-a-Secure-CI-CD-Pipeline

* `docker compose up --build`: build + run app
* `docker compose up`: run app without rebuilding
* `docker ps`: list running docker containers
* `docker exec -it DOCKER_CONTAINER_ID /bin/bash`: access container shell (for debugging)
    * (web) `python manage.py migrate`: create tables (after each database schema change)
    * (db) `mysql -u MYSQL_USER -p MYSQL_PASSWORD`: access mysql shell
        * `mysql> show databases;`: list databases
        * `mysql> use password_manager;`: select database
        * `mysql> show tables;`: list tables in selected database   
        * `mysql> describe TABLE_NAME;`: show table structure
        * `select * from TABLE_NAME;`: show table content

> the application can be accessible from [localhost:8000](http://localhost:8000/)

## Configuration service SonarQube sur AWS EC2
Ce guide explique comment héberger le service SonarQube sur une instance AWS EC2.

### Spécifications Minimales
- `OS` : Ubuntu 22.04 / 20.04 LTS  
- `Type d'instance` : t2.medium
- `Security Group` : Ports requis 9000 pour SonarQube, 22 pour SSH et 80 pou HTTP.

**Note** : Les spécifications ci-dessus sont les minima recommandés. Vous pouvez les augmenter selon vos besoins.

---

### Étape 1 : Connexion à une Instance Ubuntu EC2
1. Connectez-vous à votre serveur AWS EC2 en SSH en utiisant PUTTY:
   `citer adresse ip public` , `connection >> data >> auto-login username >> ubuntu` , `connection >> SSH >> AUTH >> credentials >> entrer private key for file configuration`

2. Mettez à jour et améliorez les paquets :
``` bash
sudo apt update
sudo apt upgrade -y
```
### Étape 2 : Installation de Java et PostgreSQL
1.  Installation de Java OpenJDK 17
``` bash
sudo apt install -y openjdk-17-jdk
java -version
```
2. Installation et Configuration de PostgreSQL
- Ajoutez le dépôt PostgreSQL :

``` bash
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

```
- Ajoutez la clé de signature PostgreSQL :


``` bash
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -

```
- Installez PostgreSQL et l'initialiser :

``` bash
sudo apt install postgresql postgresql-contrib -y
sudo systemctl enable postgresql
sudo systemctl start postgresql
sudo systemctl status postgresql

```
- Vérifiez la version :


``` bash
psql --version

```
### Étape 3 :Configuration de la Base de Données
1. Connectez-vous à PostgreSQL :
``` bash
sudo -i -u postgres
psql
```
2. Créez un utilisateur et un mot de passe sécurisés :
``` sql
CREATE USER <nom_user> WITH ENCRYPTED PASSWORD 'mdp';
```
3. Créez une base de données et assignez-lui cet utilisateur :
``` sql

CREATE DATABASE sqube OWNER sona;
GRANT ALL PRIVILEGES ON DATABASE sqube TO <nom_user>;
```
4. Vérifiez les utilisateurs et bases créés :
``` sql
\du
\l
\q
exit
```
### Étape 4 : Installation de SonarQube
1. Installez zip et téléchargez les fichiers SonarQube :
``` bash
sudo apt install zip -y
sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.4.1.88267.zip
sudo unzip sonarqube-10.4.1.88267.zip
sudo mv sonarqube-10.4.1.88267 /opt/sonarqube
```
2. Créez un utilisateur dédié :
``` bash

sudo groupadd <nom_user>
sudo useradd -d /opt/sonarqube -g <nom_user> <nom_user>
sudo chown -R <nom_user>:<nom_user> /opt/sonarqube
```
### Étape 5 : Configuration de SonarQube
1. Modifiez le fichier sonar.properties :
``` bash
sudo nano /opt/sonarqube/conf/sonar.properties
```
2. Ajoutez les lignes suivantes :

``` bash

sonar.jdbc.username=<nom_user>
sonar.jdbc.password=<mdp>
sonar.jdbc.url=jdbc:postgresql://localhost:5432/sqube
```
3. Modifiez le script sonar.sh pour exécuter SonarQube avec l’utilisateur dédié :

``` bash
sudo nano /opt/sonarqube/bin/linux-x86-64/sonar.sh
``` 
Ajoutez :


``` bash
RUN_AS_USER=<nom_user>
```
### Étape 6 : Configuration en tant que Service systemd
1. Créez un fichier service :

``` bash
sudo nano /etc/systemd/system/sonar.service
```
Contenu :

``` bash

[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sona
Group=sona
Restart=always
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
Rechargez les services systemd et démarrez SonarQube :
```

``` bash
sudo systemctl enable sonar
sudo systemctl start sonar
sudo systemctl status sonar
```

### Étape 7 : Optimisation des Limites Système
1. Modifiez les paramètres du noyau pour Elasticsearch :
``` bash
sudo nano /etc/sysctl.conf
```

Ajoutez :

``` bash
vm.max_map_count=262144
fs.file-max=65536
ulimit -n 65536
ulimit -u 4096
```

2. Redémarrez le système :
``` bash
sudo reboot
```

### Étape 8 : Accès à l’Interface Web
1. Accédez à SonarQube via : http://<IP_public>:9000
Identifiants par défaut :
Nom d’utilisateur : `admin`
Mot de passe : `admin`

Félicitations !
Vous avez installé SonarQube avec succès sur une instance EC2 Ubuntu. 🎉
## Intégration de SonarQube sur AWS EC2 via GitHub Actions Workflow

Ce guide explique comment intégrer le service SonarQube hébergé sur une instance AWS EC2 dans un pipeline GitHub Actions pour l'analyse continue du code.
## Pré-requis

- Une instance AWS EC2 configurée avec Ubuntu 22.04/20.04 LTS et SonarQube installé (référez-vous au guide précédent pour l'installation de SonarQube).
- Une clé SSH pour accéder à l'instance EC2.
- Un dépôt GitHub contenant le code source à analyser.
- Une configuration correcte du projet token projectKey unique pour chaque projet.

---

## Étapes d'Intégration

### 1. Configurer SonarQube sur AWS EC2

1. Assurez-vous que SonarQube est installé et accessible via l'URL `http://<IP-EC2>:9000`.
2. Générez un token d'authentification SonarQube :
   - Connectez-vous à l'interface web de SonarQube.
   - Allez dans **Mon Compte** > **Tokens** > **Générer un Token**.
   - Notez le token généré.



### 2. Ajouter des Secrets GitHub

Dans votre dépôt GitHub, configurez les secrets suivants :
1. **`SONAR_HOST_URL`** : L'URL de votre serveur SonarQube (`http://<IP-EC2>:9000`).
2. **`SONAR_TOKEN`** : Le token généré depuis SonarQube.
3. **`SONAR_PROJECT_KEY`** : La clé du projet dans Sonarqube.


---
### 3. modifier le fichier de configuration de sonar systemd service en /opt/sonarqube/conf/sonar.properties

``` bash
sonar.branch.name=main
sonar.sources=.
sonar.sourceEncoding=UTF-8
sonar.language=py
sonar.exclusions=**/migrations/**, **/__pycache__/**, **/*.pyc, **/node_modules/**, **/venv/**
```
``` bash
sudo systemctl restart sonar.service
```
### 3. Ajouter le job dans Workflow GitHub Actions

dans fichier workflow dans `.github/workflows` ajoutez ce job qui commence par tester la connectivité puis réalise le scan:

```yaml
jobs:
  sonarq-integration:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2
      with:
        fetch-depth: 0
    - name: Test SonarQube connectivity
      run: |
        curl -v ${{ secrets.SONAR_HOST_URL }}/api/system/status
    - name: SonarQube Scan
      uses: sonarsource/sonarqube-scan-action@v2
      env:
        SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }} 
        SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }} 
        SONAR_PROJECT_KEY: ${{ secrets.SONAR_PROJECT_KEY }} 
        SONAR_PROJECT_NAME: "Microservice-Based-Password-Manager-with-a-Secure-CI-CD-Pipeline"
```
### 4. Exécuter le Workflow
Poussez votre code sur la branche main (dans mon cas) ou ouvrez une Pull Request.
Accédez à l'onglet Actions de votre dépôt GitHub.
Suivez l'exécution du workflow et vérifiez les résultats dans SonarQube.

<p align="center">
  <img src="high-level diagram.png" alt="high-level diagram"/>
</p>
