About project
=============

Project created as set of support tools to deploy kazoo solution on docker environment. My needs:
1) need tools to deploy kazoo in Amazon cloud;
2) required use Linux dist that have docker out of box.

To cover this reqirments i selected `CoreOS` dist and wrote this tools.
Project ready to deploy kazoo as cluster with zones and as `All in one` with one zone 

Usage instruction
=================

To start
1) need download [`Container Linux Config Transpiler`](https://github.com/coreos/container-linux-config-transpiler/releases) utility and play folder included
into your PATH environment variable. On my dist Fedora this `~/.local/bin/` folder;
2) download and edit `config.yaml` file
```sh
curl -O https://raw.githubusercontent.com/sergey-safarov/kazoo-configs-docker/master/config.yaml
vi config.yaml
```
3) generate `ignition` data
```sh
ct -in-file config.yaml
```
4) copy `ignition` data into Amazon [`CoreOS instance`](https://coreos.com/os/docs/latest/booting-on-ec2.html) creation dialog as `user-data`
5) Create new `CoreOS` instance and wait when systemd booted.

Post boot preparation
---------------------

On first Amazon instance need to create `docker swarm master` node
```sh
docker swarm init
```
On all next nodes need to join to created `docker swarm cluster` using token generatd on first master node. Additonal nodes is created as `workers`.
If you need, then you can switch node from `worker` to `master`.

Then need to create docker swam network
```sh
docker network create --driver overlay --attachable --subnet 192.168.30.0/24 --gateway 192.168.30.1 kazoo
/usr/bin/git clone https://github.com/sergey-safarov/kazoo-configs-core.git /etc/kazoo/kazoo-configs-core
/usr/bin/git clone https://github.com/sergey-safarov/kazoo-configs-freeswitch.git /etc/kazoo/kazoo-configs-freeswitch
/usr/bin/git clone https://github.com/sergey-safarov/kazoo-configs-haproxy.git /etc/kazoo/kazoo-configs-haproxy
/usr/bin/git clone https://github.com/sergey-safarov/kazoo-configs-couchdb.git /etc/kazoo/kazoo-configs-couchdb
/usr/bin/git clone https://github.com/sergey-safarov/kazoo-configs-kamailio.git /etc/kazoo/kazoo-configs-kamailio

```