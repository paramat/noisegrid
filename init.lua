-- noisegrid 0.2.3 by paramat
-- For latest stable Minetest and back to 0.4.8
-- Depends default
-- License: code WTFPL

-- Raised path slabs, wider paths.

-- Parameters

local YGRID = 5
local YSAND = 3
local TERSCA = 192
local TROAD = 0.1
local TGRID = 0.12
local TFIS = 0.02 -- Fissure threshold, controls width
local ORECHA = 1 / 5 ^ 3 -- Ore chance per stone node
local APPCHA = 1 / 11 ^ 2 -- Appletree
local CACCHA = 1 / 61 ^ 2 -- Cactus
local FLOCHA = 1 / 23 ^ 2 -- Random flower
local GRACHA = 1 / 6 ^ 2 -- Grass

-- 2D noise for base terrain

local np_base = {
	offset = 0,
	scale = 1,
	spread = {x=2048, y=2048, z=2048},
	seed = -9111,
	octaves = 6,
	persist = 0.6
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

-- Set mapgen parameters

minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_params({mgname="singlenode"})
end)

-- Spawn player

function spawnplayer(player)
	player:setpos({x=0, y=2, z=0})
end

minetest.register_on_newplayer(function(player)
	spawnplayer(player)
end)

minetest.register_on_respawnplayer(function(player)
	spawnplayer(player)
	return true
end)

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
	
	local c_grass = minetest.get_content_id("noisegrid:grass")
	local c_dirt = minetest.get_content_id("noisegrid:dirt")
	local c_stone = minetest.get_content_id("noisegrid:stone")
	local c_water = minetest.get_content_id("default:water_source")
	local c_sand = minetest.get_content_id("default:sand")
	local c_roadblack = minetest.get_content_id("noisegrid:roadblack")
	local c_roadwhite = minetest.get_content_id("noisegrid:roadwhite")
	local c_path = minetest.get_content_id("noisegrid:path")
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
	local nvals_fissure = minetest.get_perlin_map(np_fissure, chulens):get3dMap_flat(minposxyz)
	
	local cross = false
	local nroad = false
	local eroad = false
	local sroad = false
	local wroad = false
	if math.abs(nvals_base[6359]) < TROAD then
		nroad = true
	end
	if math.abs(nvals_base[3121]) < TROAD then
		wroad = true
	end
	if math.abs(nvals_base[3160]) < TROAD then
		cross = true
	end
	if math.abs(nvals_base[3200]) < TROAD then
		eroad = true
	end
	if math.abs(nvals_base[39]) < TROAD then
		sroad = true
	end
	
	local nixz = 1
	local nixyz = 1
	for z = z0, z1 do
		for y = y0, y1 do
			local vi = area:index(x0, y, z)
			local via = area:index(x0, y+1, z)
			for x = x0, x1 do
				local xr = x - x0
				local zr = z - z0
				
				local ysurf
				local hills = false
				local sea = false
				local grid = false
				local n_base = nvals_base[nixz]
				local n_absbase = math.abs(n_base)
				if n_base > TGRID then
					ysurf = YGRID + math.floor((n_base - TGRID) * TERSCA)
					hills = true
				elseif n_base < -TGRID then
					ysurf = YGRID - math.floor((-TGRID - n_base) * TERSCA)
					sea = true
				else
					ysurf = YGRID
					grid = true
				end
				
				local n_fissure = nvals_fissure[nixyz]
				local nofis = false
				if math.abs(n_fissure) > TFIS then
					nofis = true
				end
				
				if y == YGRID and grid then
					if xr >= 36 and xr <= 42 and zr >= 36 and zr <= 42 -- centre
					and (nroad or eroad or sroad or wroad) and cross then
						data[vi] = c_roadblack
					elseif xr >= 33 and xr <= 45 and zr >= 43 -- north
					and nroad and cross then
						if xr == 39
						or (zr <= 45 and (xr == 37 or xr == 41)) then
							data[vi] = c_roadwhite
						elseif xr >= 36 and xr <= 42 then
							data[vi] = c_roadblack
						else
							data[vi] = c_dirt
							data[via] = c_path
						end
					elseif xr >= 43 and zr >= 33 and zr <= 45 -- east
					and eroad and cross then
						if zr == 39
						or (xr <= 45 and (zr == 37 or zr == 41)) then
							data[vi] = c_roadwhite
						elseif zr >= 36 and zr <= 42 then
							data[vi] = c_roadblack
						else
							data[vi] = c_dirt
							data[via] = c_path
						end
					elseif xr >= 33 and xr <= 45 and zr <= 35 -- south
					and sroad and cross then
						if xr == 39
						or (zr >= 33 and (xr == 37 or xr == 41)) then
							data[vi] = c_roadwhite
						elseif xr >= 36 and xr <= 42 then
							data[vi] = c_roadblack
						else
							data[vi] = c_dirt
							data[via] = c_path
						end
					elseif xr <= 35 and zr >= 33 and zr <= 45 -- west
					and wroad and cross then
						if zr == 39
						or (xr >= 33 and (zr == 37 or zr == 41)) then
							data[vi] = c_roadwhite
						elseif zr >= 36 and zr <= 42 then
							data[vi] = c_roadblack
						else
							data[vi] = c_dirt
							data[via] = c_path
						end
					elseif xr >= 33 and xr <= 45 and zr >= 33 and zr <= 45
					and cross then
						data[vi] = c_dirt
						data[via] = c_path
					else -- grass
						if math.random() < APPCHA then
							noisegrid_appletree(x, y+1, z, area, data)
						else
							data[vi] = c_grass
							if math.random() < FLOCHA then
								noisegrid_flower(data, via)
							elseif math.random() < GRACHA then
								noisegrid_grass(data, via)
							end
						end
					end
				elseif y <= ysurf - 4 and nofis then
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
				elseif y <= ysurf and y >= ysurf - 7 and y <= YSAND and sea then
					data[vi] = c_sand
				elseif y == ysurf and (nofis or grid or sea) then -- grass
					if math.random() < APPCHA then
						noisegrid_appletree(x, y+1, z, area, data)
					else
						data[vi] = c_grass
						if math.random() < FLOCHA then
							noisegrid_flower(data, via)
						elseif math.random() < GRACHA then
							noisegrid_grass(data, via)
						end
					end
				elseif y < ysurf and y >= ysurf - 3 and (nofis or grid) then
					data[vi] = c_dirt
				elseif y <= 1 and y > ysurf then
					data[vi] = c_water
				end
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