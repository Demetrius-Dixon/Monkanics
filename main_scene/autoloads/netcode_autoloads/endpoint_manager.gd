extends Node

# IP Addresses

const LOBBY_MANAGER_IPV4 : String = LOCALHOST_IPV4

const RELAY_REGIONS : Dictionary = {
	&"NA": LOCALHOST_IPV4
	}

var current_relay_region : String = RELAY_REGIONS[&"NA"]

const LOCALHOST_IPV4 : String = "127.0.0.1"

# Ports

const LOBBY_MANAGER_TCP_PORT : int = 5378
const LOBBY_MANAGER_UDP_PORT : int = 5379
const LOBBY_MANAGER_ORDERED_UDP_PORT : int = 5380

const RELAY_MANAGER_TCP_PORT : int = 5381
const RELAY_MANAGER_UDP_PORT : int = 5382
const RELAY_MANAGER_ORDERED_UDP_PORT  : int = 5383
