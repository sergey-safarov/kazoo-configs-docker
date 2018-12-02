To check daemon status you can use this commands.
For kazoo daemons:
1. systemctl status couchdb-docker.service
1. systemctl status freeswitch-docker.service
1. systemctl status haproxy-docker.service
1. systemctl status kamailio-docker.service
1. systemctl status kazoo-app-docker.service
1. systemctl status kazoo-ecallmgr-docker.service
1. systemctl status nginx-docker.service
1. systemctl status postgres-docker.service
1. systemctl status rabbitmq-docker.service

For service containers
1. systemctl status dns-docker.service
1. systemctl status fakehost-docker.service

Other systemd units that exit, but not requires maintenance:
1. systemctl status environment.service
1. systemctl status kazoo-docker-network.service
1. systemctl status kazoo-git-config.service
1. systemctl status kazoo-git-disable.service
1. systemctl status kazoo.target
1. systemctl status rt_runtime_us.service