This is a simple guide to the ansible workings of this project. \
All of this is designed to run on linux and won't run on anything else.
___
### Requirements
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
There are 3 hosts
* s1 - server 1 | 192.168.161.85
* s2 - server 2 | 192.168.161.86
* s3 - server 3 | 192.168.161.87
* srvr - Outside server which facilitates main server restarts
---
### Groups
* restart_server - the group of the restart server
* hp_servers - main servers which will host osds, monitors and managers
* cephadm - the admin server which will host the dashboard and manage other servers
___
### Playbook
The playbook is separated into x plays
* init -> The very basic stuff that needs to come before everything else, update, hosts file update etc.
* requirements -> Install requirements for other services
* network -> Sets up the network aspects on the admin server, creates certificates and starts up nginx
* clean lvm -> Optional play, which removes then adds back all the lvms and ceph
* cephadm -> The main ceph play, which installs cephadm, bootstraps ceph, creats osds and pools
* cephadm_config -> Configures ceph after install
* full reset -> fully resets the hp_servers to base ubuntu
___
### Roles
* init -> Sets up automatic apt cache updates, does apt update and upgrade and sets hostname
* hosts -> Updates hosts file with connections to other servers
* python -> Installs python 3 and pip3
* ssh -> Configures sshd, creates ssh keys for servers and gives access from other servers to itself
  * Files:
    * sshd_config -> Minimized sshd config file, allows root login
* docker -> install docker.io, python-docker and python-docker-compose
* nginx_docker -> Sets up nginx docker container
  * Files: 
    * docker-compose.yaml -> docker-compose file for nginx
  * Templates:
    * nginx.conf -> config file for nginx, which sets up ssl for the dashboard
* letsencrypt -> Creates letsencrypt certs for the dashboard and grafana
  * Templates:
    * certbot.sh -> Certbot script which creates the certs
* lvm_clean -> Removes ceph, removes lvms then adds them back
* cephadm -> Installs cephadm, adds osds and pools
  * Templates:
    * ceph.conf -> Initial configuration file used in cephadm bootstrap
    * osd_spec.yaml -> OSD specification file used to create osds
* ceph_mgr -> Configures ceph manager and its services
* full_reset -> Fully resets all servers except the external one
  * Templates:
    * 000-default.conf -> apache2 site conf
    * apache.conf -> apache2 conf
    * auto-install-1.cfg -> cloud-init conf for server 1
    * auto-install-2.cfg -> cloud-init conf for server 2
    * auto-install-3.cfg -> cloud-init conf for server 3
    * ngrok.service -> ngrok service file
    * ngrok.yaml -> ngrok conf file
___
### Group vars
**all.yaml**:
* domain_name -> bind9 domain name
* public_keys -> ssh public keys used to authorize ssh sessions to main accounts on servers
* root_public_key -> public key used to authorize ssh sessions to root accounts on servers

**cephadm.yaml**:
* initial_dashboard_user -> username of the admin account on the dashboard 
* initial_dashboard_password -> password of the admin account on the dashboard 
* fsid -> ceph cluster ID (File System ID)
* admin_keyring_file -> path to the file which contains the admin keyring 
* osd_partitions -> partitions which the osds will be place on
* osd_pg_per_pool -> Placement groups per pool
* domain_name -> Domain name used to connect to the dashboard
* certbot_email -> email given  to certbot
* dashboard_ssl_port -> ssl port of the dashboard
* dashboard_port -> http port for the dashboard

**restart_server.yaml**
* hostnames -> hostnames given to the servers
* ips -> ips of the servers
* ilo_ip -> ilo ips of the servers
* default_gateway -> default gateway on the servers' network
* name_servers -> name servers used on the servers
* ubuntu_archive -> Ubuntu archive url
* ilo_username -> username used to connect to the ilo
* ilo_password -> password used to connect to the ilo
* iso_download_url -> direct url to latest release of ubuntu 20.04
* password_hash -> password hashes used to create accounts on servers
* ilo_ip -> hp ilo ips of the servers, used to contact the server through the api
* ngrok_auth_token -> encrypted ngrok auth token, used to authenticate ngrok on external server.
It is required because the current external server is behind NAT.
* ngrok_region -> ngrok region the tunnel operates in.
* ngrok_hostname -> domain reserved through ngrok
* apache_dir -> dir in which the files in the apache server will be stored in.
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
___