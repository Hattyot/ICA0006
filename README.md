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
___
### Group vars
* domain_name -> bind9 domain name
* reverse -> first 3 octets of the ipv4 in reverse
* dns_transfer_key -> transfer key used by bind9
* dns_update_key -> update key used by bind9
* ptr_domain_name -> ptr domain name
* dns_forwarders -> nameservers to use when local bind9 cant resolve something
* dns_allowed -> list of ips which are allowed to use dns
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