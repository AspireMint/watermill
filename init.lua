minetest.register_node("watermill:watermill_3", {
	description = "Watermill 3",
	drawtype = "mesh",
	mesh = "watermill_3.obj",
	inventory_image = "watermill_3_inv.png",
	wield_image = "watermill_3_inv.png",
	paramtype2 = "facedir",
	tiles = {
		{
			name = "watermill_3.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 81,
				aspect_h = 27,
				length = 5,
			},
		},
	},
	groups = {choppy=2, dig_immediate=3, flammable=1},
})

minetest.register_craft({
	output = "watermill:watermill_3",
	recipe = {
		{'default:stick', 'default:wood', 'default:stick'},
		{'default:wood', 'default:steel_ingot', 'default:wood'},
		{'default:stick', 'default:wood', 'default:stick'},
	}
})
