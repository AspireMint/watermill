local lavamill = false	-- LOL
local use_abm  = true	-- modify only if use_mesecon is false

local use_mesecon = core.global_exists("mesecon")

local bearing_rules = {
	{x = 1, y = 0, z = 0},
	{x =-1, y = 0, z = 0},
	{x = 0, y = 1, z = 0},
	{x = 0, y =-1, z = 0},
	{x = 0, y = 0, z = 1},
	{x = 0, y = 0, z =-1},
}

minetest.register_node("watermill:bearing_3_off", {
    description = "Watermill bearing 3",
    inventory_image = "bearing_3.png",
    tiles = { "default_mossycobble.png^[combine:16x16:0,0=bearing_3.png" },
	mesecons = {conductor = {
		state = use_mesecon and mesecon.state.off,
		onstate = "watermill:bearing_3_on",
		offstate = "watermill:bearing_3_off",
		rules = mesewire_rules
	}},
	sounds = default.node_sound_metal_defaults(),
	groups = {cracky=1, oddly_breakable_by_hand=1},
	on_blast = use_mesecon and mesecon.on_blastnode,
})

minetest.register_node("watermill:bearing_3_on", {
    description = "Watermill bearing 3",
    inventory_image = "bearing_3.png",
    tiles = { "default_mossycobble.png^[combine:16x16:0,0=bearing_3.png" },
	mesecons = {conductor = {
		state = use_mesecon and mesecon.state.on,
		onstate = "watermill:bearing_3_on",
		offstate = "watermill:bearing_3_off",
		rules = mesewire_rules
	}},
	sounds = default.node_sound_metal_defaults(),
	groups = {cracky=1, oddly_breakable_by_hand=1, not_in_creative_inventory=1},
	on_blast = use_mesecon and mesecon.on_blastnode,
})

minetest.register_node("watermill:watermill_3_off", {
	description = "Watermill 3",
	drawtype = "mesh",
	mesh = "watermill_3.obj",
	inventory_image = "watermill_3_inv.png",
	wield_image = "watermill_3_inv.png",
	paramtype2 = "facedir",
	tiles = {
		"watermill_3.png^[sheet:1x9:0,8"
	},
	groups = {choppy=2, oddly_breakable_by_hand=1, flammable=lavamill and 0 or 1, not_in_creative_inventory=(use_mesecon or use_abm) and 0 or 1},
	drop = "watermill:watermill_3_".. ((use_mesecon or use_abm) and "off" or "on") .." 1",
	sounds = default.node_sound_wood_defaults(),
	mesecons = {receptor = {
		state = use_mesecon and mesecon.state.off
	}},
	on_blast = use_mesecon and mesecon.on_blastnode,
})

minetest.register_node("watermill:watermill_3_on", {
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
	groups = {choppy=2, oddly_breakable_by_hand=1, flammable=lavamill and 0 or 1, not_in_creative_inventory=(use_mesecon or use_abm) and 1 or 0},
	drop = "watermill:watermill_3_".. ((use_mesecon or use_abm) and "off" or "on") .." 1",
	sounds = default.node_sound_wood_defaults(),
	mesecons = {receptor = {
		state = use_mesecon and mesecon.state.on
	}},
	on_blast = use_mesecon and mesecon.on_blastnode,
})

minetest.register_craft({
	output = "watermill:watermill_3_".. ((use_mesecon or use_abm) and "off" or "on"),
	recipe = {
		{'default:stick', 'default:wood', 'default:stick'},
		{'default:wood', 'default:steel_ingot', 'default:wood'},
		{'default:stick', 'default:wood', 'default:stick'},
	}
})

if use_mesecon or use_abm then
	minetest.register_abm({
		nodenames = {"watermill:watermill_3_off"},
		interval = 1,
		chance = 1,
		action = function(pos, node, active_object_count, active_object_count_wider)
			local waterpos={x=pos.x, y=pos.y-1, z=pos.z}
			local flow = get_flow(pos)
			if math.abs(flow) ~= 0 and can_rotate(pos, 3) then
				local param2 = node.param2
				if flow < 0 then
					param2 = mod(param2+2, 4)
				end
				minetest.set_node(pos, {name="watermill:watermill_3_on", param2 = param2})
				if use_mesecon then
					mesecon.receptor_on(pos)
				end
			end
		end,
	})
	
	local ONE_TIME = true

	minetest.register_abm({
		nodenames = {"watermill:watermill_3_on"},
		interval = 1,
		chance = 1,
		action = function(pos, node, active_object_count, active_object_count_wider)	
			local waterpos={x=pos.x, y=pos.y-1, z=pos.z}
			local flow = get_flow(pos)
			if flow == 0 or not can_rotate(pos, 3) then
				minetest.set_node(pos, {name="watermill:watermill_3_off", param2 = node.param2})
				if use_mesecon then
					mesecon.receptor_off(pos)
				end
			end
		end,
	})
end

can_rotate = function(pos, d)
	local wmd = get_watermill_dir(pos)
	local r = math.floor(d/2) -- not really r
	for i=-r,r do
		for j=-r,r do
			if i ~= 0 or j ~= 0 then
				local nodepos = vector.add(vector.add(pos, vector.new(0,i,0)), vector.multiply(wmd, j))
				if not is_air(nodepos) and not is_liquid(nodepos) then
					return false
				end
			end
		end
	end
	
	return true
end

get_flow = function(pos)
	local node = minetest.get_node(pos)
	local wmd = get_watermill_dir(pos)
	
	local flow = 0
	local total_power = 0
	local prev_power = nil
	for i=-1,1 do
		local waterposlevel = vector.add(vector.add(pos, vector.new(0,-1,0)), vector.multiply(wmd, i))
		if is_flowing(waterposlevel) then
			local power = minetest.get_node(waterposlevel).param2
			if prev_power then
				if prev_power == power then
					--
				else
					if prev_power > power then
						flow = flow + 1
					else
						flow = flow - 1
					end
					total_power = total_power + power
				end
			else
				prev_power = power
			end
		elseif is_source(waterposlevel) then
			--
		else
			return 0
		end
	end
	
	return total_power > 3 and flow or 0
end

is_air = function(pos)
	return minetest.get_node(pos).name == "air"
end

is_liquid = function(pos)
	return is_source(pos) or is_flowing(pos)
end

is_source = function(pos)
	local name = minetest.get_node(pos).name
	return minetest.registered_items[name].liquidtype == "source"
end

is_flowing = function(pos)
	local name = minetest.get_node(pos).name
	return minetest.registered_items[name].liquidtype == "flowing"
end

get_watermill_dir = function(pos)
	local facedirflow = mod(minetest.get_node(pos).param2-1, 4)
	return minetest.facedir_to_dir(facedirflow)
end

mod = function(a, b)
	return a - math.floor(a/b)*b
end
