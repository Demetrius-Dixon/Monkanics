extends Node

"""
The primary use of the feature_manager is to manage the project's feature tags.

Feature tags control if the Monkanics instance is a:
	1. A Client
	2. A Lobby Server
	3. A Relay Server

Without them, there would be 3 separate project files-
-but with feature tags, there can be unlimited same-project configurations.

Feature tags are put onto the _ready() function of scripts to check for that-
-specific tag. If it isn't there, the script automagically queues free.

Feature tags are assigned upon exporting.

Feature Tag List:
	
	1. "dedicated_server" is godot's built-in tag to trigger a bunch of-
	-effects that are configured specifically for dedicated server mode.
	
	This mode strips all visuals and sound to lightweight placeholders-
	-and makes the instance run in headless mode (No window)
	
	This mode is combined with the lobby and relay instances.

	2. "lobby_server" is Monkanics' tag that tells the instance that it'll-
	-be a lobby server. Meaning, clients can connect to it, create lobbies-
	-and clients also connected to that same server can connect to those lobbies.

	3. "relay_server" is Monkanics' tag that tells the instance that it'll-
	-be a relay server. Meaning, all clients in a lobby connect to that relay-
	-Then, the relay is the one who forwards all game packets to all clients.
"""

const DEDICATED_SERVER : String = "dedicated_server"
const LOBBY_SERVER : String = "lobby_server"
const RELAY_SERVER : String = "relay_server"
