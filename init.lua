-- noisegrid 0.3.2 by paramat
-- For latest stable Minetest and back to 0.4.8
-- Depends default
-- License: code WTFPL

-- vary flower density
-- streets not cut by city biome

-- Parameters

local YFLAT = 7 -- Flat area elevation
local YSAND = 4 -- Top of beach
local TERSCA = 192 -- Vertical terrain scale
local STODEP = 5 -- Stone depth below surface at sea level
local TGRID = 0.18 -- Grid area width
local TFLAT = 0.2 -- Flat coastal area width
local TCITY = 0.3 -- City size. 0.3 = 1/3 of coastal land area, 0 = 1/2 of coastal land area

local TFIS = 0.02 -- Fissure threshold, controls width
local ORECHA = 1 / 4 ^ 3 -- Ore chance per stone node. 1 / n ^ 3 where n = average distance between ores
local APPCHA = 1 / 4 ^ 2 -- Appletree maximum chance per grass node. 1 / n ^ 2 where n = minimum distance between flora
local FLOCHA = 1 / 6 ^ 2 -- Flowers maximum chance per grass node
local GRACHA = 1 / 5 ^ 2 -- Grasses maximum chance per grass node

-- 2D noise for base terrain

local np_base = {
	offset = 0,
	scale = 1,
	spread = {x=2048, y=2048, z=2048},
	seed = -9111,
	octaves = 6,
	persist = 0.6
}

-- 2D noise for trees

local np_tree = {
	offset = 0,
	scale = 1,
	spread = {x=256, y=256, z=256},
	seed = 133338,
	octaves = 3,
	persist = 0.5
}

-- 2D noise for grasses

local np_grass = {
	offset = 0,
	scale = 1,
	spread = {x=128, y=128, z=128},
	seed = 133,
	octaves = 2,
	persist = 0.5
}

-- 2D noise for flowers

local np_flower = {
	offset = 0,
	scale = 1,
	spread = {x=256, y=256, z=256},
	seed = -70008,
	octaves = 2,
	persist = 0.5
}

-- 2D noise for paths

local np_path = {
	offset = 0,
	scale = 1,
	spread = {x=256, y=256, z=256},
	seed = 7000023,
	octaves = 4,
	persist = 0.4
}

-- 2D noise for intercity roads

local np_road = {
	offset = 0,
	scale = 1,
	spread = {x=2048, y=2048, z=2048},
	seed = -9111,
	octaves = 4,
	persist = 0.6
}

-- 2D noise for city areas

local np_city = {
	offset = 0,
	scale = 1,
	spread = {x=1024, y=1024, z=1024},
	seed = 3166616,
	octaves = 2,
	persist = 0.4
}

-- 3D noise for fissures

local np_fissure = {
	offset = 0,
	scale = 1,
	spread = {x=192, y=192, z=192},
	seed = 2001,
	octaves = 4,
	persist = 0.5
}

-- Stuff

noisegrid = {}

dofile(minetest.get_modpath("noisegrid").."/functions.lua")
dofile(minetest.get_modpath("noisegrid").."/nodes.lua")

-- On generated function

minetest.register_on_generated(function(minp, maxp, seed)
	if minp.y > 208 then
		return
	end

	local t1 = os.clock()
	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z
	
	print ("[noisegrid] chunk minp ("..x0.." "..y0.." "..z0..")")
	
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	
	local c_air = minetest.get_content_id("air")
	local c_grass = minetest.get_content_id("noisegrid:grass")
	local c_dirt = minetest.get_content_id("noisegrid:dirt")
	local c_stone = minetest.get_content_id("noisegrid:stone")
	local c_roadblack = minetest.get_content_id("noisegrid:roadblack")
	local c_roadwhite = minetest.get_content_id("noisegrid:roadwhite")
	local c_slab = minetest.get_content_id("noisegrid:slab")
	local c_path = minetest.get_content_id("noisegrid:path")
	local c_water = minetest.get_content_id("default:water_source")
	local c_sand = minetest.get_content_id("default:sand")
	local c_stodiam = minetest.get_content_id("default:stone_with_diamond")
	local c_stomese = minetest.get_content_id("default:stone_with_mese")
	local c_stogold = minetest.get_content_id("default:stone_with_gold")
	local c_stocopp = minetest.get_content_id("default:stone_with_copper")
	local c_stoiron = minetest.get_content_id("default:stone_with_iron")
	local c_stocoal = minetest.get_content_id("default:stone_with_coal")
	
	local sidelen = x1 - x0 + 1
	local chulens = {x=sidelen, y=sidelen, z=sidelen}
	local minposxyz = {x=x0, y=y0, z=z0}
	local minposxz = {x=x0, y=z0}
	
	local nvals_base = minetest.get_perlin_map(np_base, chulens):get2dMap_flat(minposxz)
	local nvals_tree = minetest.get_perlin_map(np_tree, chulens):get2dMap_flat(minposxz)
	local nvals_grass = minetest.get_perlin_map(np_grass, chulens):get2dMap_flat(minposxz)
	local nvals_flower = minetest.get_perlin_map(np_flower, chulens):get2dMap_flat(minposxz)
	local nvals_path = minetest.get_perlin_map(np_path, chulens):get2dMap_flat(minposxz)
	local nvals_road = minetest.get_perlin_map(np_road, chulens):get2dMap_flat(minposxz)
	local nvals_city = minetest.get_perlin_map(np_city, chulens):get2dMap_flat(minposxz)
	local nvals_fissure = minetest.get_perlin_map(np_fissure, chulens):get3dMap_flat(minposxyz)
	
	local cross = math.abs(nvals_base[3160]) < TGRID and nvals_city[3160] > TCITY -- grid elements enabled per chunk
	local nroad = math.abs(nvals_base[6359]) < TGRID and nvals_city[6359] > TCITY
	local eroad = math.abs(nvals_base[3200]) < TGRID and nvals_city[3200] > TCITY
	local sroad = math.abs(nvals_base[39]) < TGRID and nvals_city[39] > TCITY
	local wroad = math.abs(nvals_base[3121]) < TGRID and nvals_city[3121] > TCITY
	
	local nixz = 1
	local nixyz = 1
	local stable = {}
	for z = z0, z1 do
		for x = x0, x1 do
			local si = x - x0 + 1
			stable[si] = 2
		end
		for y = y0, y1 do
			local vi = area:index(x0, y, z)
			local via = area:index(x0, y+1, z)
			local n_xprepath = false
			local n_xpreroad = false
			for x = x0, x1 do
				local nodid = data[vi]
				local si = x - x0 + 1
				local xr = x - x0
				local zr = z - z0
				
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
				
				local n_fissure = nvals_fissure[nixyz]
				local nofis = math.abs(n_fissure) > TFIS
				
				local n_city = nvals_city[nixz]
				local city = n_city > TCITY
				
				local n_tree = math.min(math.max(nvals_tree[nixz], 0), 1)
				local n_grass = math.min(math.max(nvals_grass[nixz], 0), 1)
				local n_flower = math.min(math.max(nvals_flower[nixz], 0), 1)
				
				local n_path = nvals_path[nixz]
				local n_abspath = math.abs(n_path)
				local n_zprepath = nvals_path[(nixz - 80)]
				local n_road = nvals_road[nixz]
				local n_absroad = math.abs(n_road)
				local n_zpreroad = nvals_road[(nixz - 80)]
				
				local stodep = math.max(STODEP * (TERSCA - y) / TERSCA, 1)
				
				if y <= ysurf - stodep and (nofis or ((flat or sea) and y >= ysurf - 16)) then -- stone
					if math.random() < ORECHA then
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
				elseif y == ysurf and y > YSAND then -- surface layer
					if x > x0 and z > z0
					and (((n_road >= 0 and n_xpreroad < 0) -- intercity road
					or (n_road < 0 and n_xpreroad >= 0))
					or ((n_road >= 0 and n_zpreroad < 0)
					or (n_road < 0 and n_zpreroad >= 0))) then
						data[vi] = c_roadwhite
						for i = -3, 3 do
						for k = -3, 3 do
							if (math.abs(i)) ^ 2 + (math.abs(k)) ^ 2 <= 13 then
								local vi = area:index(x+i, y, z+k)
								local via = area:index(x+i, y+1, z+k)
								local nodid = data[vi]
								if nodid ~= c_roadwhite then
									data[vi] = c_roadblack
								end
								data[via] = c_air
							end
						end
						end
					elseif xr >= 36 and xr <= 42 and zr >= 36 and zr <= 42 -- city grid
					and (nroad or eroad or sroad or wroad) and cross and nodid ~= c_roadblack then -- junction
						if xr == 39 and zr == 39 then
							data[vi] = c_roadwhite
						else
							data[vi] = c_roadblack
						end
					elseif xr >= 33 and xr <= 45 and zr >= 43 -- north road
					and nroad and cross and nodid ~= c_roadblack then
						if xr == 39 then
							data[vi] = c_roadwhite
						elseif xr >= 36 and xr <= 42 then
							data[vi] = c_roadblack
						else
							data[vi] = c_dirt
							data[via] = c_slab
						end
					elseif xr >= 43 and zr >= 33 and zr <= 45 -- east road
					and eroad and cross and nodid ~= c_roadblack then
						if zr == 39 then
							data[vi] = c_roadwhite
						elseif zr >= 36 and zr <= 42 then
							data[vi] = c_roadblack
						else
							data[vi] = c_dirt
							data[via] = c_slab
						end
					elseif xr >= 33 and xr <= 45 and zr <= 35 -- south road
					and sroad and cross and nodid ~= c_roadblack then
						if xr == 39 then
							data[vi] = c_roadwhite
						elseif xr >= 36 and xr <= 42 then
							data[vi] = c_roadblack
						else
							data[vi] = c_dirt
							data[via] = c_slab
						end
					elseif xr <= 35 and zr >= 33 and zr <= 45 -- west road
					and wroad and cross and nodid ~= c_roadblack then
						if zr == 39 then
							data[vi] = c_roadwhite
						elseif zr >= 36 and zr <= 42 then
							data[vi] = c_roadblack
						else
							data[vi] = c_dirt
							data[via] = c_slab
						end
					elseif xr >= 33 and xr <= 45 and zr >= 33 and zr <= 45 -- pavement in gaps
					and cross and nodid ~= c_roadblack then
						data[vi] = c_dirt
						data[via] = c_slab
					elseif n_absroad < 0.01 and city and nodid ~= c_roadblack then -- pavement around intercity road in city
						data[vi] = c_dirt
						data[via] = c_slab
					elseif x > x0 and z > z0 -- path
					and (((n_path >= 0 and n_xprepath < 0)
					or (n_path < 0 and n_xprepath >= 0))
					or ((n_path >= 0 and n_zprepath < 0)
					or (n_path < 0 and n_zprepath >= 0))) then
						for i = -1, 1 do
						for k = -1, 1 do
							local vi = area:index(x+i, y, z+k)
							local nodid = data[vi]
							if nodid ~= c_roadwhite and nodid ~= c_roadblack then
								data[vi] = c_path
							end
						end
						end
					elseif stable[si] >= 2 and nodid ~= c_roadblack and nodid ~= c_path then -- dirt with grass
						if math.random() < APPCHA * n_tree -- appletree
						and n_abspath > 0.03 and n_absroad > 0.02 then
							noisegrid_appletree(x, y+1, z, area, data)
						else
							data[vi] = c_grass
							if math.random() < FLOCHA * n_flower and n_absroad > 0.015 then -- flowers
								noisegrid_flower(data, via)
							elseif math.random() < GRACHA * n_grass and n_absroad > 0.015 then -- grasses
								noisegrid_grass(data, via)
							end
						end
					end
				elseif y <= ysurf and y >= ysurf - 16 and y <= YSAND and sea and stable[si] >= 2 then -- sand
					data[vi] = c_sand
				elseif y < ysurf and y > ysurf - stodep and (nofis or flat) and stable[si] >= 2 then -- dirt
					data[vi] = c_dirt
				elseif y <= 1 and y > ysurf then -- water
					data[vi] = c_water
					stable[si] = 0
				else -- air
					stable[si] = 0
				end
				n_xprepath = n_path
				n_xpreroad = n_road
				nixz = nixz + 1
				nixyz = nixyz + 1
				vi = vi + 1
				via = via + 1
			end
			nixz = nixz - 80
		end
		nixz = nixz + 80
	end
	
	vm:set_data(data)
	vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map(data)
	local chugent = math.ceil((os.clock() - t1) * 1000)
	print ("[noisegrid] "..chugent.." ms")
end)