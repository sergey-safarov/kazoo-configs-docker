#!/bin/sh -e

# Uncoment next line for debug mode
# set -x

CONTAINER=$1
IFNAME=$2

check_container_presence() {
    local CONTAINER=$1
    set +e
    docker inspect --format="Container \"${CONTAINER}\" is present" ${CONTAINER} 2> /dev/null
    if [ $? -ne 0 ]; then
        echo "Container \"${CONTAINER}\" is not exist. Exiting"
        exit 1
    fi
    set -e
}

count_networks() {
    local CONTAINER=$1
    docker inspect --format='{{len  .NetworkSettings.Networks}}' ${CONTAINER}
}

get_container_net() {
    local CONTAINER=$1
    docker inspect --format='{{.HostConfig.NetworkMode}}' ${CONTAINER}
}

get_container_netns() {
    local CONTAINER=$1
    local NETWORK=$2
    docker inspect --format="1-{{.NetworkSettings.Networks.${NETWORK}.NetworkID}}" ${CONTAINER} | grep -o -P '^\S{12}'
}

get_container_ip() {
    local CONTAINER=$1
    local NETWORK=$2
    docker inspect --format="{{.NetworkSettings.Networks.${NETWORK}.IPAddress}}" ${CONTAINER}
}

get_container_mask() {
    local CONTAINER=$1
    local NETWORK=$2
    docker inspect --format="{{.NetworkSettings.Networks.${NETWORK}.IPPrefixLen}}" ${CONTAINER}
}

get_container_mac() {
    local CONTAINER=$1
    local NETWORK=$2
    docker inspect --format="{{.NetworkSettings.Networks.${NETWORK}.MacAddress}}" ${CONTAINER}
}

add_link() {
    local NETNS=$1
    local IFNAME=$2
    local MAC=$3
    set +e
    ip netns exec ${NETNS} ip link add veth-${IFNAME} type veth peer name br-${IFNAME} 2> /dev/null
    if [ $? -ne 0 ]; then
        echo "error: cannot create veth pair \"br-${IFNAME}\" to \"veth-${IFNAME}\""
        rm -f /var/run/netns/${NETNS}
        exit 1
    fi
    ip netns exec ${NETNS} ip link set dev veth-${IFNAME} address ${MAC}
        if [ $? -ne 0 ]; then
        echo "error: cannot set MAC address of net veth interface"
        ip netns exec ${NETNS} ip link delete br-${IFNAME}
        rm -f /var/run/netns/${NETNS}
        exit 1
    fi
    ip netns exec ${NETNS} ip link set veth-${IFNAME} netns 1 2> /dev/null
    if [ $? -ne 0 ]; then
        echo "error: cannot move container end of veth pair to default namespace"
        ip netns exec ${NETNS} ip link delete br-${IFNAME}
        rm -f /var/run/netns/${NETNS}
        exit 1
    fi
    ip netns exec ${NETNS} ip link set br-${IFNAME} up 2> /dev/null
    if [ $? -ne 0 ]; then
        echo "error: cannot set bridge end of veth pair to UP state"
        ip netns exec ${NETNS} ip link delete br-${IFNAME}
        rm -f /var/run/netns/${NETNS}
        exit 1
    fi
    ip netns exec ${NETNS} ip link set br-${IFNAME} master br0 2> /dev/null
    if [ $? -ne 0 ]; then
        echo "error: cannot link bridge end of veth pair to namespace bridge"
        ip netns exec ${NETNS} ip link delete br-${IFNAME}
        rm -f /var/run/netns/${NETNS}
        exit 1
    fi
    set -e
}

config_veth() {
    local NETNS=$1
    local IFNAME=$2
    local IFIP=$3
    local NETMASK=$4
    ip addr change ${IFIP}/${NETMASK} dev veth-${IFNAME}
    if [ $? -ne 0 ]; then
        echo "error: cannot set ip addr on interface \"veth-${IFNAME}\""
        ip netns exec ${NETNS} ip link delete br-${IFNAME}
        rm -f /var/run/netns/${NETNS}
        exit 1
    fi
    ip link set veth-${IFNAME} up
    if [ $? -ne 0 ]; then
        echo "error: cannot set UP state for interface \"veth-${IFNAME}\""
        ip netns exec ${NETNS} ip link delete br-${IFNAME}
        rm -f /var/run/netns/${NETNS}
        exit 1
    fi
    echo "Assigned IP address ${IFIP} to ${IFNAME} interface"
}


if [ $# -eq 0 ]; then
    echo 'Script configures link between overlay network and host network'
    echo 'Usage case: overlay2host.sh ${FROM} ${IFNAME}'
    echo '${FROM} - container name, which eth0 MAC and IP address will be copied to new NIC'
    echo '${IFNAME} - what NIC suffix need to add for created interface, mandatory'
    exit 0
fi

if [ -z ${CONTAINER} ]; then
    echo "error: container name witch NIC settings will be copied cannot be empty"
    exit 1
fi

if [ -z ${IFNAME} ]; then
    echo "error: created interface name cannot be empty"
    exit 1
fi

check_container_presence ${CONTAINER}
if [ $(count_networks ${CONTAINER}) -ne 1 ]; then
    echo "Container must be connected to only one network. Exiting"
    exit 1
fi

NET=$(get_container_net ${CONTAINER})
NETNS=$(get_container_netns ${CONTAINER} ${NET})
IFIP=$(get_container_ip ${CONTAINER} ${NET})
MASK=$(get_container_mask ${CONTAINER} ${NET})
MAC=$(get_container_mac ${CONTAINER} ${NET})

mkdir -p /var/run/netns
rm -f /var/run/netns/${NETNS}
ln -s /var/run/docker/netns/${NETNS} /var/run/netns

add_link ${NETNS} ${IFNAME} ${MAC}
config_veth ${NETNS} ${IFNAME} ${IFIP} ${MASK}
rm -f /var/run/netns/${NETNS}
exit 0
