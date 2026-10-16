extends Node

"""
IMPORTANT NOTICE:

This script's purpose is to contain the secrets that-
-authenticate official relay servers. 

Secrets are NEVER committed to the Monkanics Github or made public.
With the exception of this message and variable names.

To apply your own secret:
	1. Manually copy/paste your 264-bit key here.
	2. Export your server project(s) with those secrets.
	3. Remove those secrets from the client export.

VERY IMPORTANT TIPS:
	1. DO NOT COMMIT ANY SECRETS TO GIT! Delete them and then save.
	2. DON'T SHARE ANY SECRETS WITH ANYONE! Not even your mom...
	3. KEEP ALL KEYS LOCAL! A relay's key stays on the physical relay server.
"""

const TEST_KEY : Variant = 12345 # FOR DEBUGGING LOCALLY ONLY!

var RELAY_SERVER_US_KEY : Variant

func _ready() -> void:
	
	if not OS.has_feature("dedicated_server"): 
		queue_free()
