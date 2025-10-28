extends Node

onready var SERCOMM = preload("res://addons/GDSerCommDock/bin/GDSerComm.gdns");

# Inicializar arduino apenas se for definido na Global.
onready var PORT = SERCOMM.new() if Global.usingEsplora else null 

onready var com = get_node("Com");
onready var debug = null;
#onready var personagem = get_parent().get_node("Node/Godotinho")

var port = "/dev/ttyACM0";
var baudRate = 9600;
var message_to_receive;
var message_to_send;
var mensagem = "";

var BUTTON_DOWN = false;
var BUTTON_UP = false;
var BUTTON_LEFT = false;
var BUTTON_RIGHT = false;

var SLIDER_VALUE = 0;
var TILT_VALUE = 0;

func _ready():
	if PORT != null:
		PORT.close()
		if port != null and baudRate!=0:
			PORT.open(port,baudRate,1000,com.bytesz.SER_BYTESZ_8, com.parity.SER_PAR_NONE, com.stopbyte.SER_STOPB_ONE)
			PORT.flush()
			print("Conectado com o Esplora na porta " + str(port))
		else:
			print("Não foi possível estabelecer uma comunicação com a porta desejada. Cheque se a porta desejada foi selecionada corretamente.")
	
	
func _physics_process(_delta):
	# DEBUG:
#	print("No Esplora: " + str(get_slider()))
	if (Input.is_key_pressed(KEY_A)):
		limpar_debug()
		
	if (Input.is_key_pressed(KEY_B)):
		print("toca ae")
		message_to_send = "t"
		send_text()
		
#	print(str(PORT.get_available()))
	if PORT != null && PORT.get_available()>0:
		for _i in range(PORT.get_available()):
			message_to_receive = str(PORT.read())
			
			var _msg = ""
			if (len(message_to_receive) > 1):
				# A mensagem recebida JÁ ESTÁ em ascii. Entregar dessa forma.
				_msg = message_to_receive
			else:
				# Não está em ascii, devemos portanto converte-lo-a
				_msg = ord(message_to_receive)
			
			tratar_mensagem(_msg)

func debugar(_texto):
#	debug.text += _texto;
	pass
	
	
func limpar_debug():
#	debug.text = "";
	pass


func tratar_mensagem(_msg):
	var _char = char(_msg);
	if (_char != "]"):
		mensagem += _char;
	else:
		desempacotar(mensagem);
		mensagem = "";
		
func get_slider():
	return SLIDER_VALUE;


func get_tilt():
	return TILT_VALUE;


func get_button_pressed(button):
	match button: 
		"UP": return BUTTON_UP
		"DOWN" : return BUTTON_DOWN
		"LEFT": return BUTTON_LEFT
		"RIGHT": return BUTTON_RIGHT
		_ : 
			print("ERROR: get_button_pressed() doesn't match any!");
			return false;
	

func desempacotar(_msg: String):
	var _msgArray = _msg.split("#");
	for _pacotes in _msgArray:
		var _comandoArray = _pacotes.split(":");
		if (len(_comandoArray) > 1):
			if (Input.is_key_pressed(KEY_0)): debugar(str(_comandoArray));
			var _comando = str(_comandoArray[0]).strip_edges(true, true);
			var _valor = _comandoArray[1];
				
			match _comando:
				"b1": BUTTON_DOWN	= bool(_valor);
				"b2": BUTTON_LEFT 	= bool(_valor);
				"b3": BUTTON_UP 	= bool(_valor);
				"b4": BUTTON_RIGHT 	= bool(_valor);
				"sv": SLIDER_VALUE 	= float(_valor);
				"tv": TILT_VALUE 	= float(_valor);
	
	
func send_text():
	var text=message_to_send.replace(("\\n"),com.endline)
	PORT.write(text) # write function, please use only ascii

