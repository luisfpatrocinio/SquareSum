extends Node

onready var SERCOMM = preload("res://addons/GDSerCommDock/bin/GDSerComm.gdns");

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		print(SERCOMM);
