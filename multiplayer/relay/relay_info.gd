extends Node

const RELAY_ROUTER_IPV4 : String = "127.0.0.1"
const LOCALHOST_IPV4 : String = "127.0.0.1"

const RELAY_ROUTER_PORT : int = 5377

const RELAY_ROUTER_IPV6 : String = "" 
const LOCALHOST_IPV6 : String = "::1"
#INFO The official Monkanics relay server only supports IPv4 connections.
# However, these IPv6 variables have been left for people who'd like to utilize them.
# Keep in mind that IPv6 is not universal for all routers and dual stacking is quite complex.
# Oh also, the entire multiplayer netcode was designed completely around IPv4.
# If you make a working duel-stack setup for Monkanics, let Demetrius know.
# Have fun!
