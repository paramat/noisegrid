function noisegrid_appletree(x, y, z, area, data)
	local c_tree = minetest.get_content_id("default:tree")
	local c_apple = minetest.get_content_id("default:apple")
	local c_appleaf = minetest.get_content_id("noisegrid:appleleaf")
	local top = 3 + math.random(2)
	for j = -2, top do
		if j == top - 1 or j == top then
			for i = -2, 2 do
			for k = -2, 2 do
				local vi = area:index(x + i, y + j, z + k)
				if j == top - 1 and math.random() < 0.04 then
					data[vi] = c_apple
				elseif math.random(5) ~= 2 then
					data[vi] = c_appleaf
				end
			end
			end
		elseif j == top - 2 then
			for i = -1, 1 do
			for k = -1, 1 do
				if math.abs(i) + math.abs(k) == 2 then
					local vi = area:index(x + i, y + j, z + k)
					data[vi] = c_tree
				end
			end
			end
		else
			local vi = area:index(x, y + j, z)
			data[vi] = c_tree
		end
	end
end

function noisegrid_grass(data, vi)
	local c_grass1 = minetest.get_content_id("default:grass_1")
	local c_grass2 = minetest.get_content_id("default:grass_2")
	local c_grass3 = minetest.get_content_id("default:grass_3")
	local c_grass4 = minetest.get_content_id("default:grass_4")
	local c_grass5 = minetest.get_content_id("default:grass_5")
	local rand = math.random(5)
	if rand == 1 then
		data[vi] = c_grass1
	elseif rand == 2 then
		data[vi] = c_grass2
	elseif rand == 3 then
		data[vi] = c_grass3
	elseif rand == 4 then
		data[vi] = c_grass4
	else
		data[vi] = c_grass5
	end
end

function noisegrid_flower(data, vi)
	local c_danwhi = minetest.get_content_id("flowers:dandelion_white")
	local c_danyel = minetest.get_content_id("flowers:dandelion_yellow")
	local c_rose = minetest.get_content_id("flowers:rose")
	local c_tulip = minetest.get_content_id("flowers:tulip")
	local c_geranium = minetest.get_content_id("flowers:geranium")
	local c_viola = minetest.get_content_id("flowers:viola")
	local rand = math.random(6)
	if rand == 1 then
		data[vi] = c_danwhi
	elseif rand == 2 then
		data[vi] = c_rose
	elseif rand == 3 then
		data[vi] = c_tulip
	elseif rand == 4 then
		data[vi] = c_danyel
	elseif rand == 5 then
		data[vi] = c_geranium
	else
		data[vi] = c_viola
	end
end

-- ABM

-- Appletree sapling

minetest.register_abm({
	nodenames = {"noisegrid:appling"},
	interval = 31,
	chance = 5,
	action = function(pos, node)
		local x = pos.x
		local y = pos.y
		local z = pos.z
		local vm = minetest.get_voxel_manip()
		local pos1 = {x=x-2, y=y-2, z=z-2}
		local pos2 = {x=x+2, y=y+5, z=z+2}
		local emin, emax = vm:read_from_map(pos1, pos2)
		local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
		local data = vm:get_data()
		noisegrid_appletree(x, y, z, area, data)
		vm:set_data(data)
		vm:write_to_map()
		vm:update_map()
	end,
})

-- Spread tunnel lights

minetest.register_abm({
	nodenames = {"noisegrid:lightoff"},
	interval = 5,
	chance = 8,
	action = function(pos, node)
		minetest.add_node(pos, {name="noisegrid:lighton"})
		nodeupdate(pos)
	end,
})

-- Spread lux ore light

minetest.register_abm({
	nodenames = {"noisegrid:luxoff"},
	interval = 7,
	chance = 1,
	action = function(pos, node)
		minetest.remove_node(pos)
		minetest.place_node(pos, {name="noisegrid:luxore"})
	end,
})

-- Set mapgen parameters

minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_params({mgname="singlenode"})
end)

-- Spawn player

function spawnplayer(player)
	-- Parameters
	local PSCA = 16 -- Player scatter. Maximum distance in chunks (80 nodes) of player spawn from (0, 0, 0)
	local YFLAT = 7 -- Flat area elevation
	local TERSCA = 192 -- Vertical terrain scale
	local TFLAT = 0.2 -- Flat area width
	
	local xsp
	local ysp
	local zsp
	local np_base = {
		offset = 0,
		scale = 1,
		spread = {x=2048, y=2048, z=2048},
		seed = -9111,
		octaves = 6,
		persist = 0.6
	}
	for chunk = 1, 128 do
		print ("[noisegrid] searching for spawn "..chunk)
		local x0 = 80 * math.random(-PSCA, PSCA) - 32
		local z0 = 80 * math.random(-PSCA, PSCA) - 32
		local y0 = -32
		local x1 = x0 + 79
		local z1 = z0 + 79
		local y1 = 47

		local sidelen = 80
		local chulens = {x=sidelen, y=sidelen, z=sidelen}
		local minposxz = {x=x0, y=z0}

		local nvals_base = minetest.get_perlin_map(np_base, chulens):get2dMap_flat(minposxz)

		local nixz = 1
		for z = z0, z1 do
			for x = x0, x1 do
				local ysurf
				local n_base = nvals_base[nixz]
				local n_absbase = math.abs(n_base)
				if n_base > TFLAT then
					ysurf = YFLAT + math.floor((n_base - TFLAT) * TERSCA)
				elseif n_base < -TFLAT then
					ysurf = YFLAT - math.floor((-TFLAT - n_base) * TERSCA)
				else
					ysurf = YFLAT
				end
				if ysurf >= 1 then
					ysp = ysurf + 1
					xsp = x
					zsp = z
					break
				end
				nixz = nixz + 1
			end
			if ysp then
				break
			end
		end
		if ysp then
			break
		end
	end
	if ysp then
		print ("[noisegrid] spawn player ("..xsp.." "..ysp.." "..zsp..")")
		player:setpos({x=xsp, y=ysp, z=zsp})
	else	
		print ("[noisegrid] no suitable spawn found")
		player:setpos({x=0, y=2, z=0})
	end
end

minetest.register_on_newplayer(function(player)
	spawnplayer(player)
end)

minetest.register_on_respawnplayer(function(player)
	spawnplayer(player)
	return true
end)
