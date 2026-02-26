extends Area2D

@export var item_name : String = "TimeDiamond"
@export var item_type : String = "time_diamond"

func _on_body_entered(body):
	if body.name == "Player":
		print("بازیکن الماس زمان رو گرفت!")
		
		# به بازیکن بگو الماس زمان رو جمع کنه
		body.collect_time_diamond()
		
		# آیتم رو حذف کن
		queue_free()
