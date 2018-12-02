**CouchDB**

To check daemon logs please use this command.
```
journalctl -flu couchdb-docker
```

**FreeSwitch**

To check daemon logs please use this command. If required change container name.
```
docker exec -it fs1a fs_cli
```
Optionally you can look FreeSwitch logs at `/var/lib/docker/volumes/freeswitch-log/_data/` directory 

**haproxy**

Typically daemon is maintained via web interface on `22002` port

**Kamailio**

To check daemon logs please use this command.
```
journalctl -flu kamailio-docker
```

**Kazoo apps daemon**

To check daemon logs please use this command.
```
journalctl -flu kazoo-app-docker
```
To increase log details level. If required change container name
```
docker exec -it kz-app1a sup kazoo_maintenance console_level debug
```

**Kazoo ecallmgr daemon**

To check daemon logs please use this command.
```
journalctl -flu kazoo-ecallmgr-docker
```
To increase log details level. If required change container name
```
docker exec -it kz-ecallmgr1a sup kazoo_maintenance console_level debug
```

**nginx**

To check daemon logs please use this command.
```
journalctl -flu nginx-docker
```

**PostgreSQL**

To check daemon logs please use this command.
```
journalctl -flu postgres-docker
```

**RabbitMQ**

To check daemon logs please use this command.
```
journalctl -flu rabbitmq-docker
```

