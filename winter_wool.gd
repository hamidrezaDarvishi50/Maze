extends Area2D

# این متغیرها رو می‌تونیم از Inspector تنظیم کنیم
@export var item_name : String = "WinterWool"
@export var item_type : String = "winter"


func _on_body_entered(body):
	# وقتی بازیکن با آیتم برخورد کرد
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
