-- Parameters

local YFLAT = 7 -- Flat area elevation y
local YSAND = 4 -- Top of beach y
local TERSCA = 192 -- Vertical terrain scale in nodes
local STODEP = 5 -- Stone depth below surface in nodes at sea level
local TGRID = 0.18 -- City grid area width
local TFLAT = 0.2 -- Flat coastal area width
local TCITY = 0 -- City size.
				-- 0.3 = 1/3 of coastal land area, 0 = 1/2 of coastal land area.
local TFIS = 0.01 -- Fissure width
local TTUN = 0.02 -- Tunnel width
local LUXCHA = 1 / 9 ^ 3 -- Luxore chance per stone node.
local ORECHA = 1 / 5 ^ 3 -- Ore chance per stone node.
						-- 1 / n ^ 3 where n = average distance between ores.
local APPCHA = 1 / 4 ^ 2 -- Appletree maximum chance per grass node.
						-- 1 / n ^ 2 where n = minimum average distance between flora.
local FLOCHA = 1 / 13 ^ 2 -- Flowers maximum chance per grass node
local GRACHA = 1 / 5 ^ 2 -- Grasses maximum chance per grass node
local PSCA = 16 -- Player scatter. Maximum distance in chunks (80 nodes)
				-- of player spawn points from (0, 0, 0).

-- 2D noise for base terrain

local np_base = {
	offset = 0,
	scale = 1,
	spread = {x = 2048, y = 2048, z = 2048},
	seed = -9111,
	octaves = 6,
	persist = 0.6
}

-- 2D noise for intercity roads

local np_road = {
	offset = 0,
	scale = 1,
	spread = {x = 2048, y = 2048, z = 2048},
	seed = -9111, -- same seed as above for similar structre but smoother
	octaves = 5,
	persist = 0.5
}

-- 2D noise for alt roads and tunnels

local np_alt = {
	offset = 0,
	scale = 1,
	spread = {x = 1024, y = 1024, z = 1024},
	seed = 11,
	octaves = 3,
	persist = 0.4
}

-- 2D noise for city areas

local np_city = {
	offset = 0,
	scale = 1,
	spread = {x = 1024, y = 1024, z = 1024},
	seed = 3166616,
	octaves = 2,
	persist = 0.5
}

-- 2D noise for paths

local np_path = {
	offset = 0,
	scale = 1,
	spread = {x = 512, y = 512, z = 512},
	seed = 7000023,
	octaves = 4,
	persist = 0.4
}

local np_path2 = {
	offset = 0,
	scale = 1,
	spread = {x = 512, y = 512, z = 512},
	seed = -2315551,
	octaves = 4,
	persist = 0.4
}

-- 2D noise for trees

local np_tree = {
	offset = 0,
	scale = 1,
	spread = {x = 256, y = 256, z = 256},
	seed = 133338,
	octaves = 3,
	persist = 0.5
}

-- 2D noise for grasses

local np_grass = {
	offset = 0,
	scale = 1,
	spread = {x = 256, y = 256, z = 256},
	seed = 133,
	octaves = 2,
	persist = 0.5
}

-- 2D noise for flowers

local np_flower = {
	offset = 0,
	scale = 1,
	spread = {x = 256, y = 256, z = 256},
	seed = -70008,
	octaves = 1,
	persist = 0.5
}


-- 3D noise for fissures

local np_fissure = {
	offset = 0,
	scale = 1,
	spread = {x = 384, y = 384, z = 384},
	seed = 2001,
	octaves = 4,
	persist = 0.5
}

-- 3D noise for web a

local np_weba = {
	offset = 0,
	scale = 1,
	spread = {x = 192, y = 192, z = 192},
	seed = 5900033,
	octaves = 3,
	persist = 0.5
}

-- 3D noise for web b

local np_webb = {
	offset = 0,
	scale = 1,
	spread = {x = 191, y = 191, z = 191},
	seed = 33,
	octaves = 3,
	persist = 0.5
}

-- 3D noise for web c

local np_webc = {
	offset = 0,
	scale = 1,
	spread = {x = 190, y = 190, z = 190},
	seed = -18000001,
	octaves = 3,
	persist = 0.5
}


-- Do files

dofile(minetest.get_modpath("noisegrid") .. "/functions.lua")
dofile(minetest.get_modpath("noisegrid") .. "/nodes.lua")


-- Set mapgen parameters

minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_params({mgname = "singlenode", flags = "nolight"})
end)


-- Initialize noise objects to nil

local nobj_base = nil
local nobj_road = nil
local nobj_alt = nil
local nobj_city = nil
local nobj_path = nil
local nobj_path2 = nil
local nobj_tree = nil
local nobj_grass = nil
local nobj_flower = nil

local nobj_fissure = nil
local nobj_weba = nil
local nobj_webb = nil
local nobj_webc = nil

-- On generated function

minetest.register_on_generated(function(minp, maxp, seed)
	local t1 = os.clock()
	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z
	
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
	local data = vm:get_data()
	
	local c_air       = minetest.get_content_id("air")
	local c_grass     = minetest.get_content_id("noisegrid:grass")
	local c_dirt      = minetest.get_content_id("noisegrid:dirt")
	local c_stone     = minetest.get_content_id("noisegrid:stone")
	local c_roadblack = minetest.get_content_id("noisegrid:roadblack")
	local c_roadwhite = minetest.get_content_id("noisegrid:roadwhite")
	local c_slab      = minetest.get_content_id("noisegrid:slab")
	local c_path      = minetest.get_content_id("noisegrid:path")
	local c_concrete  = minetest.get_content_id("noisegrid:concrete")
	local c_light     = minetest.get_content_id("noisegrid:light")
	local c_luxore    = minetest.get_content_id("noisegrid:luxore")
	
	local c_water   = minetest.get_content_id("default:water_source")
	local c_sand    = minetest.get_content_id("default:sand")
	local c_wood    = minetest.get_content_id("default:wood")
	local c_stodiam = minetest.get_content_id("default:stone_with_diamond")
	local c_stomese = minetest.get_content_id("default:stone_with_mese")
	local c_stogold = minetest.get_content_id("default:stone_with_gold")
	local c_stocopp = minetest.get_content_id("default:stone_with_copper")
	local c_stoiron = minetest.get_content_id("default:stone_with_iron")
	local c_stocoal = minetest.get_content_id("default:stone_with_coal")
	
	local sidelen = x1 - x0 + 1
	local overlen = sidelen + 1
	local chulensxyz = {x = overlen, y = sidelen, z = overlen}
	local minposxyz = {x = x0 - 1, y = y0, z = z0 - 1}
	local chulensxz = {x = overlen, y = overlen, z = 1} -- different because here x=x, y=z
	local minposxz = {x = x0 - 1, y = z0 - 1}
	
	nobj_base   = nobj_base   or minetest.get_perlin_map(np_base, chulensxz)
	nobj_road   = nobj_road   or minetest.get_perlin_map(np_road, chulensxz)
	nobj_alt    = nobj_alt    or minetest.get_perlin_map(np_alt, chulensxz)
	nobj_city   = nobj_city   or minetest.get_perlin_map(np_city, chulensxz)
	nobj_path   = nobj_path   or minetest.get_perlin_map(np_path, chulensxz)
	nobj_path2  = nobj_path2  or minetest.get_perlin_map(np_path2, chulensxz)
	nobj_tree   = nobj_tree   or minetest.get_perlin_map(np_tree, chulensxz)
	nobj_grass  = nobj_grass  or minetest.get_perlin_map(np_grass, chulensxz)
	nobj_flower = nobj_flower or minetest.get_perlin_map(np_flower, chulensxz)
	
	nobj_fissure = nobj_fissure or minetest.get_perlin_map(np_fissure, chulensxyz)
	nobj_weba    = nobj_weba    or minetest.get_perlin_map(np_weba, chulensxyz)
	nobj_webb    = nobj_webb    or minetest.get_perlin_map(np_webb, chulensxyz)
	nobj_webc    = nobj_webc    or minetest.get_perlin_map(np_webc, chulensxyz)
	
	local nvals_base   = nobj_base  :get2dMap_flat(minposxz)
	local nvals_road   = nobj_road  :get2dMap_flat(minposxz)
	local nvals_alt    = nobj_alt   :get2dMap_flat(minposxz)
	local nvals_city   = nobj_city  :get2dMap_flat(minposxz)
	local nvals_path   = nobj_path  :get2dMap_flat(minposxz)
	local nvals_path2  = nobj_path2 :get2dMap_flat(minposxz)
	local nvals_tree   = nobj_tree  :get2dMap_flat(minposxz)
	local nvals_grass  = nobj_grass :get2dMap_flat(minposxz)
	local nvals_flower = nobj_flower:get2dMap_flat(minposxz)
	
	local nvals_fissure = nobj_fissure:get3dMap_flat(minposxyz)
	local nvals_weba    = nobj_weba   :get3dMap_flat(minposxyz)
	local nvals_webb    = nobj_webb   :get3dMap_flat(minposxyz)
	local nvals_webc    = nobj_webc   :get3dMap_flat(minposxyz)
	
	local cross = math.abs(nvals_base[3281]) < TGRID and nvals_city[3281] > TCITY -- grid elements
	local nroad = math.abs(nvals_base[6521]) < TGRID and nvals_city[6521] > TCITY -- enabled per chunk,
	local eroad = math.abs(nvals_base[3321]) < TGRID and nvals_city[3321] > TCITY -- dependant on
	local sroad = math.abs(nvals_base[122])  < TGRID and nvals_city[122]  > TCITY -- chunksize = 5.
	local wroad = math.abs(nvals_base[3242]) < TGRID and nvals_city[3242] > TCITY
	
	local nixz = 1
	local nixyz = 1
	local stable = {}
	for z = z0 - 1, z1 do
		for x = x0 - 1, x1 do
			local si = x - x0 + 2 -- +2 because overgeneration
			stable[si] = 2
		end
		for y = y0, y1 do
			local vi = area:index(x0 - 1, y, z)
			local via = area:index(x0 - 1, y + 1, z)
			local n_xprepath = false
			local n_xprepath2 = false
			local n_xpreroad = false
			local n_xprealt = false
			for x = x0 - 1, x1 do
				local nodid = data[vi]
				local xr = x - x0
				local zr = z - z0
				local si = xr + 2
				local chunk = (x >= x0 and z >= z0)
				
				local sea = false
				local flat = false
				local ysurf
				local n_base = nvals_base[nixz]
				local n_absbase = math.abs(n_base)
				if n_base > TFLAT then
					ysurf = YFLAT + math.floor((n_base - TFLAT) * TERSCA)
				elseif n_base < -TFLAT then
					ysurf = YFLAT - math.floor((-TFLAT - n_base) * TERSCA)
					sea = true
				else
					ysurf = YFLAT
					flat = true
				end
				
				local weba = math.abs(nvals_weba[nixyz]) < TTUN
				local webb = math.abs(nvals_webb[nixyz]) < TTUN
				local webc = math.abs(nvals_webc[nixyz]) < TTUN

				local n_fissure = nvals_fissure[nixyz]
				local n_absfissure = math.abs(n_fissure)
				local nofis = n_absfissure > TFIS and
					not (weba and webb) and not (weba and webc)
				local wood = n_absfissure < TFIS * 2 and not flat
				
				local n_city = nvals_city[nixz]
				local city = n_city > TCITY
				
				local n_tree = math.min(math.max(nvals_tree[nixz], 0), 1)
				local n_grass = math.min(math.max(nvals_grass[nixz], 0), 1)
				local n_flower = math.min(math.max(nvals_flower[nixz], 0), 1)
				
				local n_path = nvals_path[nixz]
				local n_abspath = math.abs(n_path)
				local n_zprepath = nvals_path[(nixz - overlen)]
				
				local n_path2 = nvals_path2[nixz]
				local n_abspath2 = math.abs(n_path2)
				local n_zprepath2 = nvals_path2[(nixz - overlen)]
				
				local n_road = nvals_road[nixz]
				local n_absroad = math.abs(n_road)
				local n_zpreroad = nvals_road[(nixz - overlen)]
				
				local n_alt = nvals_alt[nixz]
				local n_absalt = math.abs(n_alt)
				local n_zprealt = nvals_alt[(nixz - overlen)]
				
				local stodep = math.max(STODEP * (TERSCA - y) / TERSCA, 1)
				
				if chunk then
					-- tunnel road
					if y == YFLAT and n_base > -TGRID and
							(((n_alt >= 0 and n_xprealt < 0) or
							(n_alt < 0 and n_xprealt >= 0)) or
							((n_alt >= 0 and n_zprealt < 0) or
							(n_alt < 0 and n_zprealt >= 0))) then
						data[vi] = c_roadwhite
						for i = -3, 3 do
						for k = -3, 3 do
							if (math.abs(i)) ^ 2 + (math.abs(k)) ^ 2 <= 13 then
								local vi = area:index(x + i, y, z + k)
								local via = area:index(x + i, y + 1, z + k)
								local nodid = data[vi]
								if nodid ~= c_roadwhite then
									data[vi] = c_roadblack
								end
								data[via] = c_air -- to remove pavements
							end
						end
						end
					-- tunnel air
					elseif y <= ysurf and y >= YFLAT + 1 and y <= YFLAT + 4 and
							n_absalt < 0.025 then
						data[vi] = c_air
						stable[si] = 0
					-- tunnel lights
					elseif y <= ysurf - 1 and y == YFLAT + 5 and n_absalt > 0.003 and
							n_absalt < 0.007 then
						data[vi] = c_light
						stable[si] = stable[si] + 1
					-- tunnel concrete
					elseif y <= ysurf and y >= YFLAT and y <= YFLAT + 6 and
							n_absalt < 0.035 and n_base > TFLAT and
							nodid ~= c_roadblack then
						data[vi] = c_concrete
						stable[si] = stable[si] + 1
					-- stone and ores
					elseif y <= ysurf - stodep and nodid ~= c_roadblack and
							(nofis or ((flat or sea) and y >= ysurf - 16)) then
						if math.random() < LUXCHA then
							data[vi] = c_luxore
						elseif math.random() < ORECHA then
							local osel = math.random(24)
							if osel == 24 then
								data[vi] = c_stodiam
							elseif osel == 23 then
								data[vi] = c_stomese
							elseif osel == 22 then
								data[vi] = c_stogold
							elseif osel >= 19 then
								data[vi] = c_stocopp
							elseif osel >= 10 then
								data[vi] = c_stoiron
							else
								data[vi] = c_stocoal
							end
						else
							data[vi] = c_stone
						end
						stable[si] = stable[si] + 1
					-- surface layer
					elseif y == ysurf and y > YSAND then
						-- intercity road
						if ((n_road >= 0 and n_xpreroad < 0) or
								(n_road < 0 and n_xpreroad >= 0)) or
								((n_road >= 0 and n_zpreroad < 0) or
								(n_road < 0 and n_zpreroad >= 0)) then
							data[vi] = c_roadwhite
							for i = -3, 3 do
							for k = -3, 3 do
								if (math.abs(i)) ^ 2 + (math.abs(k)) ^ 2 <= 13 then
									local vi = area:index(x + i, y, z + k)
									local via = area:index(x + i, y + 1, z + k)
									local nodid = data[vi]
									if nodid ~= c_roadwhite then
										data[vi] = c_roadblack
									end
									data[via] = c_air
								end
							end
							end
						-- city grid
						-- junction
						elseif xr >= 36 and xr <= 42 and zr >= 36 and zr <= 42 and
								(nroad or eroad or sroad or wroad) and
								cross and nodid ~= c_roadblack then
							if xr == 39 and zr == 39 then
								data[vi] = c_roadwhite
							else
								data[vi] = c_roadblack
							end
						-- north road
						elseif xr >= 33 and xr <= 45 and zr >= 43 and nroad and
								cross and nodid ~= c_roadblack then
							if xr == 39 then
								data[vi] = c_roadwhite
							elseif xr >= 36 and xr <= 42 then
								data[vi] = c_roadblack
							else
								data[vi] = c_dirt
								data[via] = c_slab
							end
						-- east road
						elseif xr >= 43 and zr >= 33 and zr <= 45 and eroad and
								cross and nodid ~= c_roadblack then
							if zr == 39 then
								data[vi] = c_roadwhite
							elseif zr >= 36 and zr <= 42 then
								data[vi] = c_roadblack
							else
								data[vi] = c_dirt
								data[via] = c_slab
							end
						-- south road
						elseif xr >= 33 and xr <= 45 and zr <= 35 and sroad and
								cross and nodid ~= c_roadblack then
							if xr == 39 then
								data[vi] = c_roadwhite
							elseif xr >= 36 and xr <= 42 then
								data[vi] = c_roadblack
							else
								data[vi] = c_dirt
								data[via] = c_slab
							end
						-- west road
						elseif xr <= 35 and zr >= 33 and zr <= 45 and wroad and 
								cross and nodid ~= c_roadblack then
							if zr == 39 then
								data[vi] = c_roadwhite
							elseif zr >= 36 and zr <= 42 then
								data[vi] = c_roadblack
							else
								data[vi] = c_dirt
								data[via] = c_slab
							end
						-- pavement in junction gaps
						elseif xr >= 33 and xr <= 45 and zr >= 33 and zr <= 45 and
								(nroad or eroad or sroad or wroad) and
								cross and nodid ~= c_roadblack then
							data[vi] = c_dirt
							data[via] = c_slab
						-- path 1
						elseif ((n_path >= 0 and n_xprepath < 0) or
								(n_path < 0 and n_xprepath >= 0)) or
								((n_path >= 0 and n_zprepath < 0) or
								(n_path < 0 and n_zprepath >= 0)) then
							if wood then
								local viu = area:index(x, y - 1, z)
								local viuu = area:index(x, y - 2, z)
								data[viu] = c_wood
								data[viuu] = c_wood
							end
							for i = -1, 1 do
							for k = -1, 1 do
								local vi = area:index(x + i, y, z + k)
								local nodid = data[vi]
								if nodid ~= c_roadwhite and
										nodid ~= c_roadblack then
									if wood then
										data[vi] = c_wood
									else
										data[vi] = c_path
									end
								end
							end
							end
						-- path 2
						elseif ((n_path2 >= 0 and n_xprepath2 < 0) or
								(n_path2 < 0 and n_xprepath2 >= 0)) or
								((n_path2 >= 0 and n_zprepath2 < 0) or
								(n_path2 < 0 and n_zprepath2 >= 0)) then
							if wood then
								local viu = area:index(x, y - 1, z)
								local viuu = area:index(x, y - 2, z)
								data[viu] = c_wood
								data[viuu] = c_wood
							end
							for i = -1, 1 do
							for k = -1, 1 do
								local vi = area:index(x + i, y, z + k)
								local nodid = data[vi]
								if nodid ~= c_roadwhite and
										nodid ~= c_roadblack then
									if wood then
										data[vi] = c_wood
									else
										data[vi] = c_path
									end
								end
							end
							end
						-- stable dirt with grass
						elseif stable[si] >= 2 and nodid ~= c_roadblack and
								nodid ~= c_path then
							-- appletrees
							if math.random() < APPCHA * n_tree and
									n_abspath > 0.015 and
									n_abspath2 > 0.015 and
									n_absroad > 0.02 and
									(n_absalt > 0.04 or y > YFLAT) then
								noisegrid_appletree(x, y + 1, z, area, data)
							else
								data[vi] = c_grass
								-- flowers
								if math.random() < FLOCHA * n_flower and
										n_absroad > 0.015 and
										n_absalt > 0.03 then
									noisegrid_flower(data, via)
								-- grasses
								elseif math.random() < GRACHA * n_grass and
										n_absroad > 0.015 and
										n_absalt > 0.03 then
									noisegrid_grass(data, via)
								end
							end
						end
					-- sand
					elseif y <= ysurf and y >= ysurf - 16 and y <= YSAND then
						data[vi] = c_sand
					-- stable dirt
					elseif y < ysurf and y > ysurf - stodep and stable[si] >= 2 and
							nodid ~= c_roadblack then
						data[vi] = c_dirt
					-- water
					elseif y <= 1 and y > ysurf then
						data[vi] = c_water
						stable[si] = 0
					-- air
					else
						stable[si] = 0
					end
				end

				n_xprepath = n_path
				n_xprepath2 = n_path2
				n_xpreroad = n_road
				n_xprealt = n_alt
				nixz = nixz + 1
				nixyz = nixyz + 1
				vi = vi + 1
				via = via + 1
			end
			nixz = nixz - overlen
		end
		nixz = nixz + overlen
	end
	
	vm:set_data(data)
	vm:calc_lighting()
	vm:write_to_map(data)
	vm:update_liquids()

	local chugent = math.ceil((os.clock() - t1) * 1000)
	print ("[noisegrid] " .. chugent .. " ms")
end)


-- Spawn player function

local function noisegrid_spawnplayer(player)
	local xsp
	local ysp
	local zsp
	local nobj_base = nil

	for chunk = 1, 128 do
		print ("[noisegrid] searching for spawn " .. chunk)
		local x0 = 80 * math.random(-PSCA, PSCA) - 32
		local z0 = 80 * math.random(-PSCA, PSCA) - 32
		local y0 = -32
		local x1 = x0 + 79
		local z1 = z0 + 79
		local y1 = 47

		local sidelen = 80
		local chulens = {x = sidelen, y = sidelen, z = 1}
		local minposxz = {x = x0, y = z0}

		nobj_base = nobj_base or minetest.get_perlin_map(np_base, chulens)

		local nvals_base = nobj_base:get2dMap_flat(minposxz)

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
		print ("[noisegrid] spawn player (" .. xsp .. " " .. ysp .. " " .. zsp .. ")")
		player:setpos({x = xsp, y = ysp, z = zsp})
	else	
		print ("[noisegrid] no suitable spawn found")
		player:setpos({x = 0, y = 2, z = 0})
	end
end

minetest.register_on_newplayer(function(player)
	noisegrid_spawnplayer(player)
end)

minetest.register_on_respawnplayer(function(player)
	noisegrid_spawnplayer(player)
	return true
end)
