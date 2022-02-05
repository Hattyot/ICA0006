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
There are 4 hosts
* s1 - server 1 | 192.168.161.91
* s2 - server 2 | 192.168.161.92
* s3 - server 3 | 192.168.161.93
* s4 - server 4 | 192.168.161.94  (doesn't exist yet)
---
### Groups
* dns_master - specifies which host is dns master
* dns_slave - specifies which hosts are dns slaves
___
### Playbook
The playbook is separated into x plays
* init -> roles that need to be associated with all the hosts
___
### Roles
* init -> sets up automatic apt cache updates, does apt update and sets hostname
* bind -> installs and configures bind9 on the hosts to make inter-host communication easier
  * Files:
    * master -> master dns database
    * named.conf.local -> master dns local conf
    * named.conf.local.slave -> slave dns local conf
    * named.conf.options -> bind9 conf
    * reverse-master -> ptr master dns database
* dns -> switches the nameservers to bind9 name servers
  * Files:
    * resolv.conf -> resolver conf file
* full_reset -> Fully resets all servers except the external one
  * Files:
    * 000-default.conf -> apache2 site conf
    * apache.conf -> apache2 conf
    * auto-install-1.cfg -> cloud-init conf for server 1
    * auto-install-2.cfg -> cloud-init conf for server 2
    * auto-install-3.cfg -> cloud-init conf for server 3
    * ngrok.service -> ngrok service file
    * ngrok.yaml -> ngrok conf file
___
### Group vars
* domain_name -> bind9 domain name
* reverse -> first 3 octets of the ipv4 in reverse
* dns_transfer_key -> transfer key used by bind9
* dns_update_key -> update key used by bind9
* ptr_domain_name -> ptr domain name
* dns_forwarders -> nameservers to use when local bind9 cant resolve something
* dns_allowed -> list of ips which are allowed to use dns
* public_key -> ssh public key used to authorize ssh sessions to main accounts on servers
* root_public_key -> public key used to authorize ssh sessions to root accounts on servers
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