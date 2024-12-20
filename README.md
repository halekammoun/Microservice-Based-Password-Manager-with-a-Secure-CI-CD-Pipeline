# Microservice-Based-Password-Manager-with-a-Secure-CI-CD-Pipeline

- `docker compose up --build`: build + run app
- `docker compose up`: run app without rebuilding
- `docker ps`: list running docker containers
- `docker exec -it DOCKER_CONTAINER_ID /bin/bash`: access container shell (for debugging)
  - (web) `python manage.py migrate`: create tables (after each database schema change)
  - (db) `mysql -u MYSQL_USER -p MYSQL_PASSWORD`: access mysql shell
    - `mysql> show databases;`: list databases
    - `mysql> use password_manager;`: select database
    - `mysql> show tables;`: list tables in selected database
    - `mysql> describe TABLE_NAME;`: show table structure
    - `select * from TABLE_NAME;`: show table content

> the application can be accessible from [localhost:8000](http://localhost:8000/)

<p align="center">
  <img src="images/high-level diagram.png" alt="high-level diagram"/>
</p>

**example of a valid .env file**  
(do not use such vulnerable passwords in production! this is for development purposes only)

```
MYSQL_DATABASE=password_manager_db
MYSQL_USER=user
MYSQL_PASSWORD=s3cret!
MYSQL_ROOT_PASSWORD=toor
DATABASE_URL=mysql://user:s3cret!@db:3306/password_manager_db
```

---

## Configuration service SonarQube sur AWS EC2

Ce guide explique comment héberger le service SonarQube sur une instance AWS EC2.

### Spécifications Minimales

- `OS` : Ubuntu 22.04 / 20.04 LTS
- `Type d'instance` : t2.medium
- `Security Group` : Ports requis 9000 pour SonarQube, 22 pour SSH et 80 pou HTTP.

<p align="center">
  <img src="images/ec2.JPG" alt="ec2"/>
</p>
<p align="center">
  <img src="images/sg.JPG" alt="sg"/>
</p>

**Note** : Les spécifications ci-dessus sont les min recommandés. Vous pouvez les augmenter selon vos besoins.

### Étape 1 : Connexion à une Instance Ubuntu EC2

1. Connectez-vous à votre serveur AWS EC2 en SSH en utiisant PUTTY:
   `citer adresse ip public` , `connection >> data >> auto-login username >> ubuntu` , `connection >> SSH >> AUTH >> credentials >> entrer private key for file configuration`

2. Mettez à jour et améliorez les paquets :

```bash
sudo apt update
sudo apt upgrade -y
```

### Étape 2 : Installation de Java et PostgreSQL

1.  Installation de Java OpenJDK 17

```bash
sudo apt install -y openjdk-17-jdk
java -version
```

2. Installation et Configuration de PostgreSQL

- Ajoutez le dépôt PostgreSQL :

```bash
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
```

- Ajoutez la clé de signature PostgreSQL :

```bash
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -
```

- Installez PostgreSQL et l'initialiser :

```bash
sudo apt install postgresql postgresql-contrib -y
sudo systemctl enable postgresql
sudo systemctl start postgresql
sudo systemctl status postgresql
```

- Vérifiez la version :

```bash
psql --version
```

### Étape 3 :Configuration de la Base de Données

1. Connectez-vous à PostgreSQL :

```bash
sudo -i -u postgres
psql
```

2. Créez un utilisateur et un mot de passe sécurisés :

```sql
CREATE USER <nom_user> WITH ENCRYPTED PASSWORD 'mdp';
```

3. Créez une base de données et assignez-lui cet utilisateur :

```sql
CREATE DATABASE sqube OWNER sona;
GRANT ALL PRIVILEGES ON DATABASE sqube TO <nom_user>;
```

4. Vérifiez les utilisateurs et bases créés :

```sql
\du
\l
\q
exit
```

### Étape 4 : Installation de SonarQube

1. Installez zip et téléchargez les fichiers SonarQube :

```bash
sudo apt install zip -y
sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.4.1.88267.zip
sudo unzip sonarqube-10.4.1.88267.zip
sudo mv sonarqube-10.4.1.88267 /opt/sonarqube
```

2. Créez un utilisateur dédié :

```bash
sudo groupadd <nom_user>
sudo useradd -d /opt/sonarqube -g <nom_user> <nom_user>
sudo chown -R <nom_user>:<nom_user> /opt/sonarqube
```

### Étape 5 : Configuration de SonarQube

1. Modifiez le fichier sonar.properties :

```bash
sudo nano /opt/sonarqube/conf/sonar.properties
```

2. Ajoutez les lignes suivantes :

```bash
sonar.jdbc.username=<nom_user>
sonar.jdbc.password=<mdp>
sonar.jdbc.url=jdbc:postgresql://localhost:5432/sqube
```

3. Modifiez le script sonar.sh pour exécuter SonarQube avec l’utilisateur dédié :

```bash
sudo nano /opt/sonarqube/bin/linux-x86-64/sonar.sh
```

Ajoutez :

```bash
RUN_AS_USER=<nom_user>
```

### Étape 6 : Configuration en tant que Service systemd

1. Créez un fichier service :

```bash
sudo nano /etc/systemd/system/sonar.service
```

Contenu :

```bash
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=<nom_user>
Group=<nom_user>
Restart=always
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
Rechargez les services systemd et démarrez SonarQube :
```

```bash
sudo systemctl enable sonar
sudo systemctl start sonar
sudo systemctl status sonar
```

<p align="center">
  <img src="images/sonar.JPG" alt="sonar"/>
</p>

### Étape 7 : Optimisation des Limites Système

1. Modifiez les paramètres du noyau pour Elasticsearch :

```bash
sudo nano /etc/sysctl.conf
```

Ajoutez :

```bash
vm.max_map_count=262144
fs.file-max=65536
ulimit -n 65536
ulimit -u 4096
```

2. Redémarrez le système :

```bash
sudo reboot
```

### Étape 8 : Accès à l’Interface Web

1. Accédez à SonarQube via : http://<IP_public>:9000  
   Identifiants par défaut :  
   Nom d’utilisateur : `admin`  
   Mot de passe : `admin`

<p align="center">
  <img src="images/sona.JPG" alt="sona"/>
</p>

Félicitations !
Vous avez installé SonarQube avec succès sur une instance EC2 Ubuntu. 🎉


---

## Intégration de SonarQube sur AWS EC2 via GitHub Actions Workflow

Ce guide explique comment intégrer le service SonarQube hébergé sur une instance AWS EC2 dans un pipeline GitHub Actions pour l'analyse continue du code.

## Pré-requis

- Une instance AWS EC2 configurée avec Ubuntu 22.04/20.04 LTS et SonarQube installé (référez-vous au guide précédent pour l'installation de SonarQube).
- Une clé SSH pour accéder à l'instance EC2.
- Un dépôt GitHub contenant le code source à analyser.
- Une configuration correcte du projet token projectKey unique pour chaque projet.


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


### 3. modifier le fichier de configuration de sonar systemd service en /opt/sonarqube/conf/sonar.properties

```bash
sonar.branch.name=main
sonar.sources=.
sonar.sourceEncoding=UTF-8
sonar.language=py
sonar.exclusions=**/migrations/**, **/__pycache__/**, **/*.pyc, **/node_modules/**, **/venv/**
```

```bash
sudo systemctl restart sonar.service
```

### 3. Ajouter le job dans Workflow GitHub Actions

dans fichier workflow dans `.github/workflows` ajoutez ce job qui commence par tester la connectivité puis réalise le scan:

```yaml
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


---

## Configuration Trivy pour scan d'image

ce job crée une image Docker en local (cloud utilisé pargithub actions) avec le fichier Dockerfile.  
La construction ne pousse pas encore l'image sur Docker Hub (push: `false`).  
Scanne l'image pour détecter des failles de sécurité ou des dépendances vulnérables.  
Si des vulnérabilités critiques sont détectées, l'étape échoue, empêchant le push de l'image.  
Le push n'est exécuté que si le scan Trivy réussit (aucune vulnérabilité bloquante).

### 1. Ajouter des Secrets GitHub

Dans votre dépôt GitHub, configurez les secrets suivants :

1. **`DOCKERHUB_USERNAME`** : Le nom utilisateur de votre compte Dockerhub.
2. **`DOCKERHUB_TOKEN`** : Le token généré depuis Dockerhub.

### 2. Ajouter le job dans Workflow GitHub Actions

```yaml
build-trivy-scan-and-push:
  runs-on: ubuntu-latest
  needs: sonarq-integration # Ensure SonarQube analysis completes before the build

  steps:
    - name: Checkout code
      uses: actions/checkout@v2

    - name: Log in to Docker Hub
      uses: docker/login-action@v1
      with:
        username: ${{ secrets.DOCKERHUB_USERNAME }}
        password: ${{ secrets.DOCKERHUB_TOKEN }}

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v1

    - name: Build Docker image
      id: build-image
      uses: docker/build-push-action@v2
      with:
        context: .
        file: ./Dockerfile
        push: false
        tags: ${{ secrets.DOCKERHUB_USERNAME }}/web:latest
    - name: Scan image with Trivy
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: ${{ secrets.DOCKERHUB_USERNAME }}/web:latest
    - name: Push Docker image
      if: success() # Push only if Trivy scan succeeds
      uses: docker/build-push-action@v2
      with:
        context: .
        file: ./Dockerfile
        push: true
        tags: ${{ secrets.DOCKERHUB_USERNAME }}/web:latest
```

Félicitations !
Vous avez integré trivy pour scanner votre image. 🎉


---

## Construction et Analyse avec ZAP

si dessous les étapes exécutées dans la phase `build-and-zap-scan` du pipeline CI/CD. Cette phase effectue les tâches suivantes :  

- Récupération du code source.
- Vérification de l'installation de Docker Compose.
- Construction et exécution des services via Docker Compose.
- Inspection et vérification de l'état des conteneurs.
- Analyse de sécurité avec ZAP (Zed Attack Proxy) pour identifier les vulnérabilités de l'application.
- Téléchargement du rapport d'analyse ZAP comme artefact.

## Étapes


### 1. Récupération du Code Source
Le code du dépôt est récupéré dans l'environnement du runner à l'aide de l'action GitHub [actions/checkout@v2](https://github.com/actions/checkout).

```yaml
- name: Checkout code
  uses: actions/checkout@v2
```

### 2. Vérification de la Version de Docker Compose
Vérifie que Docker Compose est installé et affiche la version.

```yaml
- name: Check Docker Compose version
  run: docker compose --version
```

### 3. Construction et Exécution avec Docker Compose
Construit et démarre les services définis dans le fichier `docker-compose.yml`. Les variables d'environnement sont sécurisées avec les Secrets GitHub.

```yaml
- name: Build and run Docker Compose
  env:
    MYSQL_DATABASE: ${{ secrets.MYSQL_DATABASE }}
    MYSQL_USER: ${{ secrets.MYSQL_USER }}
    MYSQL_PASSWORD: ${{ secrets.MYSQL_PASSWORD }}
    MYSQL_ROOT_PASSWORD: ${{ secrets.MYSQL_ROOT_PASSWORD }}
    DATABASE_URL: ${{ secrets.DATABASE_URL }}
  run: |
    docker compose up -d
    sleep 15
```

### 4. Débogage des Conteneurs Docker
Liste tous les conteneurs Docker en cours d'exécution pour vérifier que les services sont démarrés.

```yaml
- name: Debug Docker containers
  run: docker ps
```

### 5. Obtenir l'Adresse IP du Conteneur Web et Vérifier l'Accessibilité
Récupère l'adresse IP du conteneur nommé `web` et vérifie que l'application est accessible.

```yaml
- name: Get web container IP address and check accessibility
  id: get_ip
  run: |
    CONTAINER_ID=$(docker ps -qf "name=web")
    echo "Web Container ID: $CONTAINER_ID"
    CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CONTAINER_ID)
    echo "Web Container IP: $CONTAINER_IP"
    echo "container_ip=$CONTAINER_IP" >> $GITHUB_ENV
    curl http://$CONTAINER_IP:8000
```

### 6. Analyse avec ZAP
Utilise l'action [ZAP Full Scan](https://github.com/zaproxy/action-full-scan) pour effectuer une analyse de vulnérabilités de l'application web.

```yaml
- name: ZAP Scan
  uses: zaproxy/action-full-scan@v0.7.0
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
    target: http://${{ env.container_ip }}:8000
    artifact_name: "zap-alerts"
```

### 7. Vérification de la Génération du Fichier d'Alerte ZAP
S'assure que le fichier de rapport d'analyse ZAP est généré avec succès.

```yaml
- name: Verify ZAP Alerts File Generation
  run: ls -l | grep report
```

### 8. Téléchargement des Alertes ZAP comme Artefact
Télécharge le rapport d'analyse ZAP dans les artefacts GitHub pour examen ultérieur.

```yaml
- name: Upload ZAP Alerts as Artifact
  uses: actions/upload-artifact@v4
  with:
    name: zap-alerts
    path: ./report_html.html
```

## Prérequis
- Docker et Docker Compose doivent être installés sur le runner.
- Le fichier `docker-compose.yml` doit définir les services de l'application.
- Les Secrets GitHub doivent être configurés pour les variables d'environnement requises (`MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`, `DATABASE_URL`).

## Résultats

- Un rapport d'analyse ZAP (`report_html.html`) est téléchargé comme artefact dans GitHub Actions comme suit,
Les artefacts du dernier run du workflow peuvent être téléchargés depuis la page GitHub Actions.

1. Allez sur la [page Actions] (https://github.com/halekammoun/Microservice-Based-Password-Manager-with-a-Secure-CI-CD-Pipeline/actions).
2. Sélectionnez le dernier run.
3. Faites défiler jusqu'à la section **Artefacts** et téléchargez l'artefact nommé `zap-alerts`.
<p align="center">
  <img src="images/zap1.JPG" alt="high-level diagram"/>
</p>

4. Extractes le Zip et consultes le rapport `report_html.html`
<p align="center">
  <img src="images/zap2.JPG" alt="high-level diagram"/>
</p>
<p align="center">
  <img src="images/zap3.JPG" alt="high-level diagram"/>
</p>

## Remarques
- Ajustez la durée de `sleep` dans l'étape Docker Compose en fonction du temps de démarrage de vos services.
- Assurez-vous que le nom du conteneur web correspond au nom défini dans votre fichier `docker-compose.yml`.
- Examinez le rapport d'analyse ZAP pour résoudre les vulnérabilités identifiées.

