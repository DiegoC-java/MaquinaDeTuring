extends Node2D

# ====== ESTADO DE LA MÁQUINA DE TURING ======
var current_state = "q0"  # Estado inicial
var tape = []  # La cinta (array de símbolos)
var head_position = 0  # Posición del cabezal
var halt = false  # Si la máquina se detuvo

# ====== TABLA DE TRANSICIONES ======
# Formato: transitions[estado_actual][símbolo_leído] = [nuevo_estado, símbolo_a_escribir, dirección]
# Dirección: "L" = izquierda, "R" = derecha, "N" = no mover
var transitions = {
	# ===== ESTADOS INICIALES =====
	"q0": {  # Buscar el operador
		"1": ["q0", "1", "R"],  # Avanza sobre los unos del primer número
		"+": ["q_suma_inicio", "0", "R"],  # Detectó suma, marca con 0 y va a sumar
		"-": ["q_resta_inicio", "0", "R"],  # Detectó resta, marca con 0 y va a restar
		"_": ["qf", "_", "N"]  # Celda vacía, halt
	},
	
	# ===== SUMA =====
	"q_suma_inicio": {  # Convertir el primer 1 del segundo número en espacio
		"1": ["q_suma_mover", "_", "R"],  # Borra un 1 y va a mover
		"_": ["q_limpiar", "_", "L"]  # No hay segundo número, termina
	},
	"q_suma_mover": {  # Ir al final de la cinta
		"1": ["q_suma_mover", "1", "R"],
		"_": ["q_suma_escribir", "1", "L"]  # Llegó al final, escribe un 1 y vuelve
	},
	"q_suma_escribir": {  # Volver al separador (0)
		"1": ["q_suma_escribir", "1", "L"],
		"_": ["q_suma_escribir", "_", "L"],  # ← LÍNEA NUEVA
		"0": ["q_suma_inicio", "0", "R"]  # Vuelve a buscar más unos del segundo número
	},
	
	# ===== RESTA =====
	"q_resta_inicio": {  # Buscar el primer 1 del segundo número
		"1": ["q_resta_borrar_segundo", "_", "L"],  # Borra un 1 del segundo número
		"_": ["q_limpiar", "_", "L"]  # No hay más en segundo número, termina
	},
	"q_resta_borrar_segundo": {  # Volver al separador
		"1": ["q_resta_borrar_segundo", "1", "L"],
		"0": ["q_resta_borrar_primero", "0", "L"]  # Llegó al separador, va a borrar del primero
	},
	"q_resta_borrar_primero": {  # Buscar el último 1 del primer número
		"1": ["q_resta_encontrado", "_", "R"],  # Borra un 1 del primer número
		"_": ["q_resta_encontrado", "_", "R"]  # (manejo de casos borde)
	},
	"q_resta_encontrado": {  # Volver al separador
		"1": ["q_resta_encontrado", "1", "R"],
		"0": ["q_resta_inicio", "0", "R"],  # Vuelve a buscar más unos del segundo número
		"_": ["q_resta_inicio", "0", "R"]
	},
	
	# ===== LIMPIEZA =====
	"q_limpiar": {  # Limpiar el separador (0) y espacios extras
		"0": ["q_limpiar", "_", "L"],
		"1": ["q_ir_inicio", "1", "L"],
		"_": ["q_limpiar", "_", "L"]
	},
	"q_ir_inicio": {  # Ir al inicio de la cinta
		"1": ["q_ir_inicio", "1", "L"],
		"_": ["qf", "_", "R"]  # Llegó al inicio, halt
	}
}

# ====== FUNCIONES PRINCIPALES ======

func _ready():
	print("=== MÁQUINA DE TURING INICIADA ===")
	# Ejemplo de suma: 3 + 2 = 5
	initialize_tape("11111-11")
	# Ejemplo de resta: 5 - 2 = 3
	# initialize_tape("11111-11")
	print_tape()

func initialize_tape(input_string: String):
	"""Inicializa la cinta con una cadena de entrada"""
	tape.clear()
	
	# Agregar espacios vacíos al inicio
	for i in range(3):
		tape.append("_")
	
	# Convertir string a array de caracteres
	for char in input_string:
		tape.append(char)
	
	# Agregar espacios vacíos al final
	for i in range(10):
		tape.append("_")
	
	# El cabezal empieza después de los espacios iniciales
	head_position = 3
	current_state = "q0"
	halt = false
	
	print("Cinta inicializada: ", input_string)

func step():
	"""Ejecuta un paso de la máquina de Turing"""
	if halt:
		print("⛔ La máquina ya se detuvo")
		return
	
	# Expandir la cinta si es necesario
	if head_position >= tape.size():
		tape.append("_")
	if head_position < 0:
		tape.push_front("_")
		head_position = 0
	
	# Leer símbolo actual
	var current_symbol = tape[head_position]
	
	print("\n--- PASO ---")
	print("Estado: ", current_state)
	print("Posición: ", head_position)
	print("Símbolo leído: '", current_symbol, "'")
	
	# Buscar transición
	if not transitions.has(current_state):
		print("❌ ERROR: Estado '", current_state, "' no existe en la tabla")
		halt = true
		return
	
	if not transitions[current_state].has(current_symbol):
		print("❌ ERROR: No hay transición para el símbolo '", current_symbol, "' en estado '", current_state, "'")
		halt = true
		return
	
	var transition = transitions[current_state][current_symbol]
	var new_state = transition[0]
	var write_symbol = transition[1]
	var direction = transition[2]
	
	# Escribir nuevo símbolo
	tape[head_position] = write_symbol
	print("Escribe: '", write_symbol, "'")
	
	# Mover cabezal
	if direction == "L":
		head_position -= 1
		print("Mueve: ← Izquierda")
	elif direction == "R":
		head_position += 1
		print("Mueve: → Derecha")
	else:
		print("Mueve: - (No se mueve)")
	
	# Cambiar estado
	current_state = new_state
	print("Nuevo estado: ", new_state)
	
	# Verificar si llegó a estado final
	if current_state == "qf":
		halt = true
		print("\n✅ ¡MÁQUINA DETENIDA!")
		print("🎉 RESULTADO FINAL:")
		print_tape()
		print_result()
	else:
		print_tape()

func print_tape():
	"""Imprime la cinta de forma visual"""
	var tape_str = ""
	for i in range(tape.size()):
		if i == head_position:
			tape_str += "[" + tape[i] + "]"
		else:
			tape_str += " " + tape[i] + " "
	print("Cinta: ", tape_str)

func print_result():
	"""Cuenta y muestra el resultado (cantidad de 1s)"""
	var count = 0
	for symbol in tape:
		if symbol == "1":
			count += 1
	print("Cantidad de 1s en la cinta: ", count)

# ====== FUNCIÓN PARA TESTING RÁPIDO ======
func _process(delta):
	# Presiona ESPACIO para avanzar un paso (solo para testing)
	if Input.is_action_just_pressed("ui_accept"):
		step()
