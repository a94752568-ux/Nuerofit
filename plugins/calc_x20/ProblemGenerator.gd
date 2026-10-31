# plugins/calc_x20/ProblemGenerator.gd
# Genera estímulos según nivel de dificultad (1..8). Ver docs/plugin-calc-x20-design.md §6.
extends Reference

var _rng := RandomNumberGenerator.new()
var _last_key: String = ""


func _init(seed_value: int = 0) -> void:
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()


func generate(difficulty: int) -> Dictionary:
	var level: int = clamp(difficulty, 1, 8)
	var problem: Dictionary
	var attempts := 0
	while attempts < 24:
		problem = _generate_once(level)
		var key: String = "%s%s%s" % [problem["a"], problem["op"], problem["b"]]
		if key != _last_key:
			_last_key = key
			return problem
		attempts += 1
	_last_key = "%s%s%s" % [problem["a"], problem["op"], problem["b"]]
	return problem


func _generate_once(level: int) -> Dictionary:
	match level:
		1, 2:
			return _add(1, 9, 12)
		3, 4:
			if _rng.randf() < 0.55:
				return _add(1, 20, 40)
			return _sub(1, 20)
		5, 6:
			var r: float = _rng.randf()
			if r < 0.34:
				return _add(1, 30, 60)
			elif r < 0.67:
				return _sub(1, 30)
			return _mul(2, 12, 81)
		_:
			var r2: float = _rng.randf()
			if r2 < 0.25:
				return _add(1, 40, 80)
			elif r2 < 0.5:
				return _sub(1, 40)
			elif r2 < 0.75:
				return _mul(2, 12, 144)
			return _div_exact(2, 12)


func _add(lo: int, hi: int, max_sum: int) -> Dictionary:
	var a: int = _rng.randi_range(lo, hi)
	var b_max: int = min(hi, max_sum - a)
	if b_max < lo:
		b_max = lo
	var b: int = _rng.randi_range(lo, max(lo, b_max))
	return _pack(a, "+", b, a + b)


func _sub(lo: int, hi: int) -> Dictionary:
	var a: int = _rng.randi_range(lo, hi)
	var b: int = _rng.randi_range(lo, a)  # resultado no negativo
	return _pack(a, "−", b, a - b)


func _mul(lo: int, hi: int, max_prod: int) -> Dictionary:
	var a: int = _rng.randi_range(lo, hi)
	var b_hi: int = min(hi, int(max_prod / max(a, 1)))
	b_hi = max(lo, b_hi)
	var b: int = _rng.randi_range(lo, b_hi)
	return _pack(a, "×", b, a * b)


func _div_exact(lo: int, hi: int) -> Dictionary:
	var b: int = _rng.randi_range(lo, hi)
	var q: int = _rng.randi_range(lo, hi)
	var a: int = b * q
	return _pack(a, "÷", b, q)


func _pack(a: int, op: String, b: int, answer: int) -> Dictionary:
	return {
		"a": a,
		"op": op,
		"b": b,
		"correct_answer": answer,
		"display": "%d %s %d" % [a, op, b]
	}
