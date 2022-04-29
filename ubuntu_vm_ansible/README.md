This playbook installs all the services that will use the ceph cluster
___
# Server
___
### Operating System & Kernel
The operating system used under the vm is `Ubuntu 20.04`.\
The kernel version is `5.4.0-109-generic`
___
# Services
___
## Frontend Services
___
### Agama
Agama is a simple web service which uses mysql to store its data.\
Port: 9095
___
### Telegraf
Telegraf is a server agent which collects metrics data, in our case syslogs.\
Port: 6514
___
### Nginx
Nginx directs traffic towards the vm's services. \
Paths:
* `/` -> agama
* `/influxdb` -> influxdb
* `/telegraf` -> telegraf
___
## Backend Services
___
### Mysql
Mysql is configured to store each database in its own folder, allowing each database to have its own 
rbd image, namespace and user, meaning every service does not need its own instance of mysql running. \
Port: 3306

Databases: 
* agama:
  * `rbd image` -> agama-image
  * `mount-point` -> /var/lib/mysql/agama
___
### Influxdb
Influxdb is configured to run in the same way as mysql, each database has its own folder
Ports: 8092, 8125, 8094 
Databases:
* telegraf
  * `rbd image` -> telegraf-image
  * `mount-point` -> /opt/influxdb/data/data/telegraf
___
# Ansible
___
### Ansible Requirements
* ansible >= 2.11.6
* python >= 3.9
* jinja >= 3.0.2
___
### Run the playbook
The playbook needs to be run in the same directory as the infra.yaml file.
```shell
ansible-playbook infra.yaml --vault-password-file /path/to/vault/password/file
```
___
### Hosts
There is 1 host
* vm - lab | 192.168.180.42
---
### Connecting with the hosts
Ansible connects to the root account of the hosts through the id_rsa key in the project root directory
The playbook assumes the public key has been added to root user's authorized_keys file
___
### Playbook
The playbook is separated into x plays
* pre-tasks -> Decrypts the id_rsa key for use
* init -> The very basic stuff that needs to come before everything else, apt update, hosts file update etc.
* requirements -> Install the required software
* network -> Sets up the network aspects on the server, creates certificates and sets up dns and nginx
* storage -> Install storge services and sets up the connection to the ceph cluster through rbd devices
* services -> Install services which use the storage services
* post-tasks -> Encrypts the id_rsa key
___
### Roles
* init -> Sets up automatic apt cache updates, does apt update and upgrade, creates vm user and adds it to the sudoers file.
* hosts -> Adds hp servers to hosts file
* journalctl -> Configures journald
  * Files:
    * journalctl.conf -> journald config file, which sets logs max size to 500M
* ssh -> Configures sshd, creates ssh keys for the server and gives ssh access to the server
  * Files:
    * sshd_config -> Minimized sshd config file, allows root login
* python -> Installs python 3 and pip3
* docker -> install docker.io, python-docker and python-docker-compose and sets docker daemon config
  * Files:
    * daemon.json -> Docker daemon config file, sets default log config to journald
* ceph -> install ceph 16 through cephadm script
* letsencrypt -> Creates letsencrypt certs for the sub-domain
  * Templates:
    * certbot.sh -> Certbot script which creates the certs
    * cloudflare.ini -> File containing the cloudflare zone edit token
* Cloudflare -> Adds A record to domain which points at the host
* nginx_docker -> Sets up nginx docker container
  * Files: 
    * docker-compose.yaml -> docker-compose file for nginx
  * Templates:
    * nginx.conf -> config file for nginx, which sets up ssl for the dashboard
* mysql -> Installs and configures mysql for use by services like agama
  * Templates:
    * my.cnf -> Mysql client config file which allows root user to access mysql
    * mysql.cnf -> Config file for mysqld
* influxdb -> Installs and configures influxdb for use by services like telegraf
  * Templates:
    * docker-compose.yaml -> Docker-compose file for telegraf and influxdb
    * influxdb.conf -> Influxdb config file
    * telegraf.conf -> Telegraf config file
* rbd -> Maps and mounts needed rbd images for services
  * Files:
    * rbdmap -> File that's used to automatically map rbd-images at boot
* agama -> Installs and launches agama service
  * Templates:
    * docker-compose.yaml -> Docker-compose file used to launch agama
    * Dockerfile -> Dockerfile which agama is built from
* rsyslog -> Installs and configures rsyslog
  * Templates:
    * rsyslog-telegraf.conf -> Configures rsyslog to send all logs to telegraf
___
### Group vars
**all.yaml**:
* hp_server_ips -> ips of the hp servers
* public_keys -> ssh public keys used to authorize ssh sessions to main accounts on servers
* domain_name -> domain used to connect to the cluster and the vm
* certbot_email -> email given to certbot
* cloudflare_zone_edit_token -> cloudflare api token used to edit domain zone
* agama_port -> port which can be used to access agama
* mysql_port -> port which can be used to access mysql
* influxdb_port -> port which can be used to access influxdb
* telegraf_port -> port which can be used to access telegraf
* mysql_host -> ip of the mysql host machine
* mysql_root_password -> root password used to create mysql root user

**agama.yaml**:
* mysql_user -> agama mysql user used to access agama database
* mysql_password -> agama mysql password used to access agama database
* mysql_database -> agama database name

**influxdb.yaml**
* influx_db -> influxdb db
* influxdb_admin_user -> name of the influxdb admin user
* influxdb_admin_password -> password of the influxdb admin user
___
### Encrypt and Decrypt
Encrypt strings
```bash
ansible-vault encrypt_string --vault-password-file vault_password_file important_string 123
```
Encrypt files
```bash
ansible-vault encrypt --vault-password-file vault_password_file .env
```

Decrypt files
```bash
ansible-vault decrypt --vault-password-file vault_password_file .env
```

Decrypt variables
```bash
ansible all -m debug -a 'var=<variable>'
```
