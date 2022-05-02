This is a simple guide to the ansible workings of this project. \
All of this is designed to run on linux and won't run on anything else.
___
# Infrastructure
___
### Servers
This cluster has 3 HP ProLiant DL360 G7 Servers.\
The server specifications can be found [here.](https://support.hpe.com/hpesc/public/docDisplay?docId=emr_na-c02206768)
Each server has:
  * 136GB hard drive (x4)
  * 47G ram
  * Intel(R) Xeon(R) CPU X5650

### Hard Drives
Each server has the 4 136G drives in this configuration:
```
sda (136G)
|_ sda1 (1M) (grub spacer)
|_ sda2 (500M) /boot
   |_ md0 (raid 1 - sdb2)
|_ sda3 (15G) /
   |_ md1 (raid 1 - sdb3)
|_ sda4 (121G)
   |_ lv0/vg0 (osd)

sdb (136G)
|_ sdb1 (1M) (grub spacer)
|_ sdb2 (500M) /boot
   |_ md0 (raid 1 - sda2)
|_ sdb3 (15G) /
   |_ md1 (raid 1 - sda3)
|_ sdb4 (121G)
   |_ lv1/vg1 (osd)

sdc (136G)
|_ sdc1 (136G)
   |_ lv2/vg2 (osd)

sdd (136G)
|_ sdd1 (136G)
   |_ lv3/vg3 (osd)
```
More detailed version of this can be viewed in [roles/full_reset/templates/auto-install-1.cfg](./roles/full_reset/templates/auto-install-1.cfg)
___
### Operating System & Kernel
The operating system used under the ceph cluster is `Ubuntu 20.04`.\
The kernel version is `5.4.0-109-generic`
___
# Ceph Design
___
### UML Diagram
```
                             ┌───────────┐                             ┌───────────┐
                             │Modules    │                             │Modules    │
                             ├───────────┤                             ├───────────┤
                             │balancer   │                             │balancer   │
                             │cephadm    │           ┌────┐            │cephadm    │
           ┌────────────────►│crash      │           │HTTP│            │crash      │◄────────────────┐
           │                 │dashboard  │           └──┬─┘            │dashboard  │                 │
  ┌────────┴┐                │devicehealt│              │              │devicehealt│                ┌┴────────┐
  │         ├───────────┐    │iostat     │              │              │iostat     │   ┌────────────┤         │
┌─┤ Manager │           │    └───────────┘              │              └───────────┘   │            │ Manager ├─┐
│ │         │◄────────┐ │                               │                              │ ┌─────────►│         │ │
│ └─────────┘         │ │    ┌──────────┐               ▼               ┌──────────┐   │ │          └─────────┘ │
│                     │ │    │Dashboard │   ┌───────────────────────┐   │Dashboard │   │ │                      │
│ ┌──────────┐        │ │    ├──────────┤   │Keepalived             │   ├──────────┤   │ │         ┌──────────┐ │
│ │Prometheus│        │ └───►│Port: 8080│◄┐ ├───────────────────────┤ ┌►│Port: 8080│◄──┘ │         │Prometheus│ │
│ ├──────────┤        │      └──────────┘ │ │VRRP IP: 192.168.161.88│ │ └──────────┘     │         ├──────────┤ │
│ │Port: 9095│◄─────┐ │                   │ └───────────┬───────────┘ │                  │ ┌──────►│Port: 9095│ │
│ └──────────┘      │ │      ┌──────────┐ │             │             │ ┌──────────┐     │ │       └──────────┘ │
│                   │ │      │Grafana   │ │             │             │ │Grafana   │     │ │                    │
│ ┌────────────┐    │ │      ├──────────┤ │    ┌────────┴────────┐    │ ├──────────┤     │ │     ┌────────────┐ │
│ │Alertmanager│    │ │ ┌───►│Port: 3000│ │    │                 │    │ │Port: 3000│◄──┐ │ │     │Alertmanager│ │
│ ├────────────┤    │ │ │    └──────────┘ │    │                 │    │ └──────────┘   │ │ │     ├────────────┤ │
│ │Port: 9093  │◄─┐ │ │ │             ▲   └──┐ │                 │ ┌──┘   ▲            │ │ │  ┌─►│Port: 9093  │ │
│ └────────────┘  │ │ │ │    /grafana ┤      │ │                 │ │      ├ /grafana   │ │ │  │  └────────────┘ │
│                 │ │ │ │    ┌────────┴──┐ / │ │                 │ │ / ┌──┴────────┐   │ │ │  │                 │
│ ┌─────────────┐ │ │ │ │    │Nginx      ├─┴─┘ │ ┌─────────────┐ │ └─┴─┤Nginx      │   │ │ │  │ ┌─────────────┐ │
│ │Node-Exporter│ │ │ │ │    ├───────────┤     │ │Node-Exporter│ │     ├───────────┤   │ │ │  │ │Node-Exporter│ │
│ └─────────────┘ │ │ │ │ ┌─►│Port: 443  │◄────┘ └─────────────┘ └──►  │Port: 443  │◄┐ │ │ │  │ └─────────────┘ │
│  ▲      ┌─────┐ │ │ │ │ │  └───────────┘        ▲      ┌─────┐       └───────┬───┘ │ │ │ │  │  ▲      ┌─────┐ │
│  │ ┌───►│Crash│ │ │ │ │ │                       │ ┌───►│Crash│               │     │ │ │ │  │  │ ┌───►│Crash│ │
│  │ │    └─────┘ │ │ │ │ │                       │ │    └─────┘               │     │ │ │ │  │  │ │    └─────┘ │
│ ┌┴─┴────────────┴─┴─┴─┴─┴─────────┐  ┌──────────┴─┴────────────────────┐  ┌──┴─────┴─┴─┴─┴──┴──┴─┴──────────┐ │
│ │ Server 1 (Cephadm)              │  │ Server 2                        │  │ Server 3 (Cephmgr standby)      │ │
│ ├─────────────────────────────────┤  ├─────────────────────────────────┤  ├─────────────────────────────────┤ │
│ │ ILO-IP: 192.168.161.101         │  │ ILO-IP: 192.168.161.102         │  │ ILO-IP: 192.168.161.103         │ │
│ │ IP: 192.168.161.85              │  │ IP: 192.168.161.86              │  │ IP: 192.168.161.87              │ │
│ │ Username: s1                    │  │ Username: s2                    │  │ Username: s3                    │ │
│ │ Hostname: srvr-1                │  │ Hostname: srvr-2                │  │ Hostname: srvr-3                │ │
│ │                                 │  │                                 │  │                                 │ │
│ │ OS: Ubuntu 20.04                │  │ OS: Ubuntu 20.04                │  │ OS: Ubuntu 20.04                │ │
│ │ Kernel: 5.4.0                   │  │ Kernel: 5.4.0                   │  │ Kernel: 5.4.0                   │ │
│ │ OS Disk Size: 15G               │  │ OS Disk Size: 15G               │  │ OS Disk Size: 15G               │ │
│ └────────┬────┬─┬─┬─┬────┬────────┘  └────────┬────┬─┬─┬─┬────┬────────┘  └────────┬────┬─┬─┬─┬────┬────────┘ │
│          │    │ │ │ │    │                    │    │ │ │ │    │                    │    │ │ │ │    │          │
│          ▼    │ │ │ │    ▼                    ▼    │ │ │ │    ▼                    ▼    │ │ │ │    ▼          │
│ ┌──────────┐  │ │ │ │  ┌──────────┐  ┌──────────┐  │ │ │ │  ┌──────────┐  ┌──────────┐  │ │ │ │  ┌──────────┐ │
│ │OSD       │  │ │ │ │  │OSD       │  │OSD       │  │ │ │ │  │OSD       │  │OSD       │  │ │ │ │  │OSD       │ │
│ ├──────────┤  │ │ │ │  ├──────────┤  ├──────────┤  │ │ │ │  ├──────────┤  ├──────────┤  │ │ │ │  ├──────────┤ │
│ │Size: 121G│  │ │ │ │  │Size: 121G│  │Size: 121G│  │ │ │ │  │Size: 121G│  │Size: 121G│  │ │ │ │  │Size: 121G│ │
│ │Disk: sda4│  │ │ │ │  │Disk: sdb4│  │Disk: sda4│  │ │ │ │  │Disk: sdb4│  │Disk: sda4│  │ │ │ │  │Disk: sdb4│ │
│ └┬─────────┘  │ │ │ │  └────────┬─┘  └┬─────────┘  │ │ │ │  └─────────┬┘  └┬─────────┘  │ │ │ │  └─────────┬┘ │
│  │            │ │ │ │           │     │            │ │ │ │            │    │            │ │ │ │            │  │
│  │    ┌───────┘ │ │ └───────┐   └──┐  │    ┌───────┘ │ │ └──────┐     │    │    ┌───────┘ │ │ └───────┐    │  │
│  │    ▼         │ │         ▼      │  │    ▼         │ │        ▼     │  ┌─┘    ▼         │ │         ▼    │  │
│  │ ┌──────────┐ │ │ ┌──────────┐   │  │ ┌──────────┐ │ │ ┌──────────┐ │  │   ┌──────────┐ │ │ ┌──────────┐ │  │
│  │ │OSD       │ │ │ │OSD       │   │  │ │OSD       │ │ │ │OSD       │ │  │   │OSD       │ │ │ │OSD       │ │  │
│  │ ├──────────┤ │ │ ├──────────┤   │  │ ├──────────┤ │ │ ├──────────┤ │  │   ├──────────┤ │ │ ├──────────┤ │  │
│  │ │Size: 136G│ │ │ │Size: 136G│   │  │ │Size: 136G│ │ │ │Size: 136G│ │  │   │Size: 136G│ │ │ │Size: 136G│ │  │
│  │ │Disk: sdc1│ │ │ │Disk: sdd1│   │  │ │Disk: sdc1│ │ │ │Disk: sdd1│ │  │   │Disk: sdc1│ │ │ │Disk: sdd1│ │  │
│  │ └┬─────────┘ │ │ └─────────┬┘   │  │ └┬─────────┘ │ │ └─────────┬┘ │  │   └┬─────────┘ │ │ └─────────┬┘ │  │
│  │  │           │ │           │    │  │  │           │ │           │  │  │    │           │ │           │  │  │
│  │  │           │ └────────┐  │    │  │  │           │ └────────┐  │  │  │    │           │ └────────┐  │  │  │
│  │  │           ▼          │  │    │  │  │           ▼          │  │  │  │    │           ▼          │  │  │  │
│  │  │     ┌─────────────┐  │  │    │  │  │    ┌─────────────┐   │  │  │  │    │    ┌─────────────┐   │  │  │  │
│  │  │ ┌───┤Monitor      │  │  │    │  │  │ ┌──┤Monitor      │   │  │  │  │    │ ┌──┤Monitor      │   │  │  │  │
│  │  │ │   ├─────────────┤  │  │    │  │  │ │  ├─────────────┤   │  │  │  │    │ │  ├─────────────┤   │  │  │  │
│  │  │ │   │V2 Port: 3300│  │  │    │  │  │ │  │V2 Port: 3300│   │  │  │  │    │ │  │V2 Port: 3300│   │  │  │  │
│  │  │ │   │V1 Port: 6789│  │  │    │  │  │ │  │V1 Port: 6789│   │  │  │  │    │ │  │V1 Port: 6789│   │  │  │  │
│  │  │ │   └─────────────┘  │  │    │  │  │ │  └─────────────┘   │  │  │  │    │ │  └─────────────┘   │  │  │  │
│  │  │ │                    │  │    │  │  │ │                    │  │  │  │    │ │                    │  │  │  │
│  │  │ │  ┌───────────────┐ │  │    │  │  │ │ ┌───────────────┐  │  │  │  │    │ │ ┌───────────────┐  │  │  │  │
│  │  │ │  │Metadata Server│◄┘  │    │  │  │ │ │Metadata Server│◄─┘  │  │  │    │ │ │Metadata Server│◄─┘  │  │  │
│  │  │ │  └───────┬───────┘    │    │  │  │ │ └───────┬───────┘     │  │  │    │ │ └───────┬───────┘     │  │  │
│  │  │ │          │            │    │  │  │ │         │             │  │  │    │ │         │             │  │  │
│  │  │ │          │            │    ▼  ▼  ▼ ▼         ▼             ▼  ▼  ▼    │ │         │             │  │  │
│  │  │ │          │            └──►┌───────────────────────────────────────┐◄──┘ │         │             │  │  │
│  │  │ │          │                │Ceph Cluster                           │     │         │             │  │  │
│  │  │ │          └───────────────►├───────────────────────────────────────┤◄────┘         │             │  │  │
│  │  │ │                           │fsid: 7eec669e-b41a-11ec-9909-e160ce8bf│               │             │  │  │
│  │  │ └──────────────────────────►│Raw Storage Capacity: 1.5TiB           │◄──────────────┘             │  │  │
│  │  │                             │                                       │                             │  │  │
│  │  └────────────────────────────►│                                       │◄────────────────────────────┘  │  │
│  │                                │                                       │                                │  │
│  └───────────────────────────────►│                                       │◄───────────────────────────────┘  │
│                                   │                                       │                                   │
└──────────────────────────────────►└─────────────────┬─┬─┬─────────────────┘◄──────────────────────────────────┘
                                                      │ │ │
                                  ┌───────────────────┘ │ └────────────────┐
                                  ▼                     ▼                  ▼
        ┌────────────────────────────┐ ┌────────────────────────────┐ ┌────────────────────────────┐
        │Pool                        │ │Pool                        │ │Pool                        │
        ├────────────────────────────┤ ├────────────────────────────┤ ├────────────────────────────┤
        │Name: rbd                   │ │Name: cephfs_meta           │ │Name: cephfs_data           │
        │Type: replication           │ │Type: replication           │ │Type: replication           │
        │Replica Count: 3            │ │Replica Count: 3            │ │Replica Count: 3            │
        │PG Count: 256               │ │PG Count: 256               │ │PG Count: 256               │
        │Applications: rbd           │ │Applications: cephfs        │ │Applications: cephfs        │
        └─┬─┬────────────────────────┘ └──────────────────────────┬─┘ └──────┬─────────────────────┘
          │ │                                                     │          │
          │ └───────────────────────────────┐                     └────────┐ │
          ▼                                 ▼                              ▼ ▼
    ┌──────────────┬─┬─────────────┐  ┌──────────────┬─┬─────────────┐    ┌────────────┬─────────────────┐
    │Namespace     │ │User         │  │Namespace     │ │User         │    │User        │                 │
    ├──────────────┤ ├─────────────┤  ├──────────────┤ ├─────────────┤    ├────────────┤                 │
    │Name: telegraf│ │ID: telegraf │  │Name: agama   │ │ID: agama    │    │ID: vmfs    │                 │
    ├──────────────┘ └─────────────┤  ├──────────────┘ └─────────────┤    ├────────────┘                 │
    │                              │  │                              │    │                              │
    ├──────────────────────────────┤  ├──────────────────────────────┤    ├──────────────────────────────┤
    │Block Image                   │  │Block Image                   │    │File System                   │
    ├──────────────────────────────┤  ├──────────────────────────────┤    ├──────────────────────────────┤
    │Name: telegraf-image          │  │Name: agama-image             │    │Name: cephfs                  │
    │Size: 5G                      │  │Size: 5G                      │    │                              │
    └──────────────────────────────┘  └──────────────────────────────┘    └──────────────────────────────┘
```


___
### Ceph Services
Each server has:
* Monitor (x1)
  * V2 port: 3300
  * V1 port: 6789
* Osd (x4)
* Crash (x1)
* Node-Exporter (x1)

The servers in the `cephmgr` group also have:
* Manager (x1)
  * Dashboard Port: 8080
  * SSL Dashboard Port: 443 
* Grafana (x1)
  * Port: 3000
* Prometheus (x1)
  * Port: 9095
* Alertmanager (x1)
  * Port: 9093
___
### Pools
Currently one pool is created for use by clients:
* rbd:
  * Size: 3
  * Placement Groups: 512
  * Type: replication
___
### RBD images
Each application which uses rados block devices to store data has its own image
Currently 2 images are created:
* agama-image -> For the web application agama:
  * Size: 5G
  * Namespace: agama
  * User: agama
  * Pool: rbd
* telegraf-image -> For storing telegraf data:
  * Size: 5G
  * Namespace: telegraf
  * User: rsyslog
  * Pool: rbd
___
### Load Balancing
Load balancing is handled by keepalived\
VRRP IP: 192.168.161.88

Priority is based on which dashboard is currently active.
___
### SSL & Domain
Certs are generated with letsencrypt and associated with the `ssaart.xyz` domain.\
Dns is handled by cloudflare.\
Records:
* A -> VRRP IP
* CNAME -> www -> A record
___
### Passwords
Every password that's set and used is in one of the group_vars files and can be decrypted with the vault password
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
There are 3 hosts
* s1 - server 1 | 192.168.161.85
* s2 - server 2 | 192.168.161.86
* s3 - server 3 | 192.168.161.87
* vm - ubuntu vm | 192.168.180.42 
---
### Connecting with the hosts
Ansible connects to the root account of the hosts through the id_rsa key in the project root directory
The playbook assumes the public key has been added to root user's authorized_keys file
___
### Groups
* restart_server - The group of the restart server
* hp_servers - Main servers which will host osds, monitors and managers
* cephadm - The admin server which will initialize ceph and install it's components on all the servers
* cephmgr - The manager servers, which will host the dashboard and it's services
___
### Playbook
The playbook is separated into x plays
* pre-tasks -> Decrypts the id_rsa key for use
* init -> The very basic stuff that needs to come before everything else, apt update, hosts file update etc.
* requirements -> Installs software that's needed on all servers
* network -> Sets up the network aspects on the admin server, creates certificates and sets up dns
* cephmgr requirements -> Installs cephmgr services requirements and sets up load balancing
* cephadm -> Installs cephadm and bootstraps the cluster, then installs all the services on all the hosts
* ceph config -> Configures ceph services after install
* storage -> Sets up rados block device images and ceph filesystems
* logs -> Sets up rsyslog to send all logs to a central telegraf/influxdb server
* full reset -> fully resets the hp_servers to base ubuntu
* post-tasks -> encrypts the id_rsa key
___
### Roles
* init -> Sets up automatic apt cache updates, does apt update and upgrade, sets hostname and adds main user to sudoers file.
* hosts -> Updates hosts file with connections to other servers
* journalctl -> Configures journald
  * Files:
    * journalctl.conf -> journald config file, which sets logs max size to 500M
* ntp -> Installs and configures ntp
  * Files:
    * ntp.conf -> The ntp config files, which sets the pools the servers wil sync with.
* python -> Installs python 3 and pip3
* ssh -> Configures sshd, creates ssh keys for servers and gives access from other servers to itself
  * Files:
    * sshd_config -> Minimized sshd config file, allows root login
* docker -> install docker.io, python-docker and python-docker-compose and sets docker daemon config
  * Files:
    * daemon.json -> Docker daemon config file, sets default log config to journald
* Cloudflare -> Configures cloudflare dns for the domain
* letsencrypt -> Creates letsencrypt certs for the dashboard and grafana
  * Templates:
    * certbot.sh -> Certbot script which creates the certs
    * cloudflare.ini -> File containing the cloudflare zone edit token
* keepalived -> Installs and configures keepalived
  * Templates:
    * keepalived.conf -> The keepalived config file, which sets up vrrp
    * keepalived_script.sh -> Script used to check the current active dashboard
* nginx_docker -> Sets up nginx docker container
  * Files: 
    * docker-compose.yaml -> docker-compose file for nginx
  * Templates:
    * nginx.conf -> config file for nginx, which sets up ssl for the dashboard
* ceph -> installs ceph on non-cephadm servers
* cephadm -> Installs cephadm, adds osds and pools
  * Templates:
    * ceph.conf -> Initial configuration file used in cephadm bootstrap
    * osd_spec.yaml -> OSD specification file used to create osds
    * crash_spec.yaml -> Crash specification file used to create crash instances
    * host_spec.yaml -> Hosts specification file used to add hosts to the cluster
    * manager_spec.yaml -> Manager specification file used to create manager and its services instances
    * monitor_spec.yaml -> Monitor specification file used to create monitor instances
    * node-exporter_spec.yaml -> Node-exporter specification file used to create node-exporter instances
* ceph_mgr -> Configures ceph manager and its services
* rbd -> Creates namespaces, users and rbd images for services that use the cluster
* cephfs -> Creates pools for filesystems and filesystems
* rsyslog -> Redirects all syslogs to a telegraf server
  * Files:
    * rsyslog.conf -> top-level config file for rsyslog
  * Templates:
    * rsyslog-telegraf.conf -> rsyslog config file
    * syslog-lograte -> sets up faster log rotation for /var/log/syslog
* full_reset -> Fully resets all servers except the external one
  * Templates:
    * auto-install-1.cfg -> cloud-init conf for server 1
    * auto-install-2.cfg -> cloud-init conf for server 2
    * auto-install-3.cfg -> cloud-init conf for server 3
___
### Group vars
**all.yaml**:
* domain_name -> domain used to connect to the cluster
* public_keys -> ssh public keys used to authorize ssh sessions to main accounts on servers
* root_public_key -> public key part of id_rsa key used to authorize ssh sessions to root accounts on servers
* ips -> Ips assigned to the servers
* hostnames -> hostnames assigned to the servers
* default_gateway -> default gateway on the servers' network
* name_servers -> name servers used on the servers
* telegraf_port -> port for the telegraf service
* vrrp_ip -> ip assigned to the vrrp in keepalived

**cephadm.yaml**:
* initial_dashboard_user -> username of the admin account on the dashboard 
* initial_dashboard_password -> password of the admin account on the dashboard 
* fsid -> ceph cluster ID (File System ID)
* admin_keyring_file -> path to the file which contains the admin keyring 
* osd_partitions -> partitions which the osds will be place on
* osd_pg_per_pool -> Placement groups per pool
* certbot_email -> email given  to certbot

**cephmgr.yaml**
* dashboard_port -> non-ssl port of the dashboard
* grafana_port -> port assigned to grafana
* prometheus_port -> port assigned to prometheus
* alertmanager_port -> port assigned to alertmanager
* agama_image_size -> size of the rbd agama image
* rsyslog_image_size -> size of the rbd rsyslog image
* cloudflare_zone_edit_token -> cloudflare api token used to edit domain zone

**restart_server.yaml**
* ilo_ip -> hp ilo ips of the servers, used to contact the server through the ilo api
* ubuntu_archive -> Ubuntu archive url
* ngrok_auth_token -> encrypted ngrok auth token, used to authenticate ngrok on external server.
* ngrok_region -> ngrok region the tunnel operates in.
* ngrok_hostname -> domain reserved through ngrok
* apache_dir -> dir in which the files in the apache server will be stored in
* ilo_username -> username used to connect to the ilo
* ilo_password -> password used to connect to the ilo
* password_hash -> password hashes used to create accounts on servers
* iso_download_url -> direct url to latest release of ubuntu 20.04
* os_password -> password for the main users on the servers
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