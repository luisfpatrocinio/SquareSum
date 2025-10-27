extends Node

var save_path = "user://savegame.save"

var data_dict = {
	"last_score": 0,
	"greatest_score": 0,
	"times_played": 0
}

var usingEsplora = true;

func _ready():
	
	pass

func save_data():
	var file = File.new()
	var error = file.open(save_path, file.WRITE)
	if error == OK:
		file.store_var(data_dict)
		file.close()
		print('[ save_data ]: Dados salvos com sucesso!')
		print(' >  Última pontuação: ' + str(Global.data_dict["last_score"]))
		print(' >  Maior pontuação: ' + str(Global.data_dict["greatest_score"]))
		print(" >  Vezes jogadas: " + str(Global.data_dict["times_played"]))

func load_data():
	var file = File.new()
	if file.file_exists(save_path):
		var error = file.open(save_path, file.READ)
		if error == OK:
			data_dict = file.get_var()
			print('[ load_data ]: Dados carregados com sucesso!')
			print(' >  Última pontuação: ' + str(Global.data_dict["last_score"]))
			print(' >  Maior pontuação: ' + str(Global.data_dict["greatest_score"]))
			print(" >  Vezes jogadas: " + str(Global.data_dict["times_played"]))
	
	elif data_dict.times_played == 0:
		print("[ load_data (WARN) ]: Arquivo de save não encontrado! (nunca foi criado)")
	else:
		print("[ load_data (ERR) ]: Arquivo de save não foi encontrado! (missing)")
		
