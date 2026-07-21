extends Node

var Sent_Reliable_Packets_In_Transit : Array[Dictionary] = []
const MAX_RELIABLE_PACKET_RESEND_DELAY : float = 0.3
const MIN_RELIABLE_PACKET_RESEND_DELAY : float = 0.0

var Received_Reliable_Packets : Array = []
const MAX_SAVED_RELIABLE_PACKETS : int = 100

func send_udp_packet(
Packet_Info:String,Packet_Sender:Variant,Packet_Destination:String,
Is_Reliable:bool,Is_Confirmation_Packet:bool) -> void:
	
	var Packet_Parameters : Dictionary = {}
	
	Packet_Parameters = {
		
		&"PacketInfo": Packet_Info,
		&"IsReliable": Is_Reliable,
		&"IsConfirmation": Is_Confirmation_Packet
		
	}
	
	if Is_Reliable == true:
		Packet_Parameters.get_or_add(&"TimeSinceSend", 0.0)
		Packet_Parameters.get_or_add(&"PacketResender", Packet_Sender)
		Packet_Parameters.get_or_add(&"ResendDestination", Packet_Destination)
		Packet_Parameters.get_or_add(&"PacketID", str(randf_range(-100_000,100_000)))
		Sent_Reliable_Packets_In_Transit.append(Packet_Parameters)
	
	var Encoded_Packet : Variant = JSON.stringify(Packet_Parameters)
	
	#print(Packet_Parameters)
	
	Encoded_Packet = Encoded_Packet.to_utf8_buffer()
	
	Packet_Sender.set_dest_address(Packet_Destination, RelayInfo.RELAY_ROUTER_PORT)
	
	Packet_Sender.put_packet(Encoded_Packet)

func receive_udp_packet(Packet:Variant) -> Dictionary:
	
	var Decoded_Packet : Variant = Packet.get_string_from_utf8()
	
	print(Decoded_Packet.get_packet_ip())
	
	var JSON_Translation : Variant = JSON.new()
	
	JSON_Translation = JSON.parse_string(Decoded_Packet)
	
	Decoded_Packet = JSON_Translation
	
	
	
	#print(Decoded_Packet)
	
	return Decoded_Packet

#func confirm_reliable_packets(Decoded_Packet:Dictionary) -> void:
	#
	#send_udp_packet(
		#Decoded_Packet[&"PacketID"], 
		#Packet_Peer,
		#Decoded_Packet.get_packet_ip(),
		#false,false,true)
	#
	#Received_Reliable_Packets.append(Decoded_Packet)
	#
	#if Received_Reliable_Packets.size() == MAX_SAVED_RELIABLE_PACKETS:
		#Received_Reliable_Packets.pop_front()

func tick_and_resend_reliable_packets(delta:float) -> void:
	
	if Sent_Reliable_Packets_In_Transit.is_empty() == true: return
	
	if Sent_Reliable_Packets_In_Transit.is_empty() == false:
		
		for reliable_packet in Sent_Reliable_Packets_In_Transit:
			
			reliable_packet[&"TimeSinceSend"] = reliable_packet[&"TimeSinceSend"] + delta
			
			if reliable_packet[&"TimeSinceSend"] >= MAX_RELIABLE_PACKET_RESEND_DELAY:
				
				send_udp_packet(
					reliable_packet[&"PacketInfo"],
					reliable_packet[&"PacketResender"],
					reliable_packet[&"ResendDestination"],
					false,false)
				
				reliable_packet[&"TimeSinceSend"] = MIN_RELIABLE_PACKET_RESEND_DELAY

func _physics_process(delta: float) -> void:
	
	tick_and_resend_reliable_packets(delta)
