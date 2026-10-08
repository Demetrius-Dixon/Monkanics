extends Node

# IP Addresses

const LOBBY_MANAGER_IPV4 : String = LOCALHOST_IPV4

var relay_regions : Dictionary = {
	&"NA": LOCALHOST_IPV4
	}

var current_relay_region : String = relay_regions[&"NA"]

const LOCALHOST_IPV4 : String = "127.0.0.1"
const LOCALHOST_IPV6 : String = "::1"

# Ports

const LOBBY_MANAGER_TCP_PORT : int = 5378

const RELAY_MANAGER_TCP_PORT : int = 5378
const RELAY_MANAGER_UDP_PORT : int = 5380
const RELAY_MANAGER_ORDERED_UDP_PORT  : int = 5381

const P2P_TCP_PORT : int = 5382
const P2P_UDP_PORT : int = 5383
const P2P_ORDERED_UDP_PORT  : int = 5384
