extends Area2D

@export var item_name : String = "SummerFruit"
@export var item_type : String = "summer"  # تغییر به summer

func _on_body_entered(body):
	if body.name == "Player":
		print("بازیکن با آیتم برخورد کرد:", item_name)
		
		# به بازیکن بگو آیتم رو جمع کنه
		body.collect_item(item_name, item_type)
		
		# به صحنه فصل اطلاع بده
		var parent = get_parent()
		if parent and parent.has_method("on_item_collected"):
			parent.on_item_collected()
		
		# آیتم رو حذف کن
		queue_free()
