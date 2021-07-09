local modname = minetest.get_current_modname()
local use_mesecon = core.global_exists("mesecon")

local watermill = {
	lavamill = false,
	state = {
		on = "on",
		off = "off",
	}
}

local get_name = function(name, state)
	return name.."_"..state
end

local get_on_blast = function()
	return use_mesecon and mesecon.on_blastnode
end

local get_mesecon_state = function(state)
	if use_mesecon then
		if state == watermill.state.on then
			return mesecon.state.on
		end
		if state == watermill.state.off then
			return mesecon.state.off
		end
	end
	return nil
end

local get_image = function(name)
	return name:gsub(".*:", "")..".png"
end

local get_inv_image = function(name)
	return name:gsub(".*:", "").."_inv.png"
end

local get_mesh = function(name)
	return name:gsub(".*:", "")..".obj"
end

local get_bearing_image = function(bgimg)
	return bgimg.."^[combine:16x16:0,0=bearing.png"
end

local lbm_replace_node = function(old_name, new_name)
	minetest.register_lbm({
		name = modname..":lbm_replace_node_"..old_name:gsub("%:", ""),
		nodenames = {old_name},
		action = function(pos, node)
			minetest.swap_node(pos, {name=new_name, param2=node.param2})
		end,
	})
end

local lbm_replace_watermill_node = function(old_name, new_name)
	lbm_replace_node(old_name.."_off", get_name(new_name, watermill.state.off))
	lbm_replace_node(old_name.."_on", get_name(new_name, watermill.state.on))
end
lbm_replace_watermill_node("watermill:bearing_3", "watermill:bearing_mossycobble")
lbm_replace_watermill_node("watermill:watermill_3", "watermill:watermill_3_v1")

local register_bearing_node = function(name, def, def2)
	def = def or {}
	def2 = def2 or {}
	
	local get_def = function (state)
		local _def = {
			description = "Watermill bearing",
			inventory_image = def.tiles and def.tiles[1] or "bearing.png",
			tiles = { "bearing.png" },
			mesecons = {conductor = {
				state = get_mesecon_state(state),
				onstate = get_name(name, watermill.state.on),
				offstate = get_name(name, watermill.state.off),
				rules = {
					{x = 1, y = 0, z = 0},
					{x =-1, y = 0, z = 0},
					{x = 0, y = 1, z = 0},
					{x = 0, y =-1, z = 0},
					{x = 0, y = 0, z = 1},
					{x = 0, y = 0, z =-1},
				}
			}},
			sounds = default.node_sound_metal_defaults(),
			groups = {cracky=1, oddly_breakable_by_hand=1},
			on_blast = get_on_blast(),
			drop = get_name(name, watermill.state.off).." 1",
		}
		
		for k,v in pairs(def) do
			_def[k] = v
		end
		
		if state == watermill.state.on then
			_def.description = nil
		end
		
		return _def
	end
	
	minetest.register_node(get_name(name, watermill.state.off), get_def(watermill.state.off))
	minetest.register_node(get_name(name, watermill.state.on), get_def(watermill.state.on))
	
	if def2.recipe then
		minetest.register_craft({
			output = get_name(name, watermill.state.off),
			recipe = def2.recipe
		})
	end
end

local register_watermill_node = function(name, def, def2)
	def = def or {}
	def2 = def2 or {}
	
	local watermill_on = get_name(name, watermill.state.on)
	local watermill_off = get_name(name, watermill.state.off)

	local get_def = function(state)
		local _def = {
			description = "Watermill",
			drawtype = "mesh",
			mesh = get_mesh(name),
			paramtype2 = "facedir",
			inventory_image = get_inv_image(name),
			wield_image = get_inv_image(name),
			groups = {choppy=2, oddly_breakable_by_hand=1, flammable=watermill.lavamill and 0 or 1},
			drop = watermill_off.." 1",
			sounds = default.node_sound_wood_defaults(),
			mesecons = {receptor = {
				state = get_mesecon_state(state)
			}},
			on_blast = get_on_blast(),
		}
		
		for k,v in pairs(def) do
			_def[k] = v
		end
		
		if state == watermill.state.off then
			_def.tiles = {
				get_image(name).."^[sheet:1x"..def2.frames..":0,0"
			}
		else
			_def.description = nil
			_def.tiles = {
				{
					name = get_image(name),
					animation = {
						type = "vertical_frames",
						aspect_w = def2.aspect_w,
						aspect_h = def2.aspect_h,
						length = def2.length,
					},
				},
			}
		end
		
		return _def
	end
	
	minetest.register_node(watermill_off, get_def(watermill.state.off))
	minetest.register_node(watermill_on, get_def(watermill.state.on))
	
	if def2.recipe then
		minetest.register_craft({
			output = watermill_off,
			recipe = def2.recipe
		})
	end
	
	minetest.register_abm({
		nodenames = { watermill_off },
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
				minetest.set_node(pos, {name=watermill_on, param2 = param2})
				if use_mesecon then
					mesecon.receptor_on(pos)
				end
			end
		end,
	})
	
	minetest.register_abm({
		nodenames = { watermill_on },
		interval = 1,
		chance = 1,
		action = function(pos, node, active_object_count, active_object_count_wider)	
			local waterpos={x=pos.x, y=pos.y-1, z=pos.z}
			local flow = get_flow(pos)
			if flow == 0 or not can_rotate(pos, 3) then
				minetest.set_node(pos, {name=watermill_off, param2 = node.param2})
				if use_mesecon then
					mesecon.receptor_off(pos)
				end
			end
		end,
	})
end

register_bearing_node("watermill:bearing_mossycobble", {
	description = "Watermill mossycobble bearing",
	tiles = { get_bearing_image("default_mossycobble.png") },
})

register_watermill_node("watermill:watermill_3_v1", { description = "Watermill (r=3)" }, {
	frames = 9,
	aspect_w = 3,
	aspect_h = 1,
	length = 5,
	recipe = {
		{'default:stick', 'default:wood', 'default:stick'},
		{'default:wood', 'default:steel_ingot', 'default:wood'},
		{'default:stick', 'default:wood', 'default:stick'},
	}
})

register_watermill_node("watermill:watermill_4_v1", { description = "Watermill (r=4)", inventory_image = '', wield_image = '' }, {
	frames = 3,
	aspect_w = 54,
	aspect_h = 16,
	length = 2,
	recipe = {
		{'default:stick', 'default:tree', 'default:stick'},
		{'default:tree', 'default:steel_ingot', 'default:tree'},
		{'default:stick', 'default:tree', 'default:stick'},
	}
})

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
