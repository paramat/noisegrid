noisegrid 0.4.0 by paramat
For Minetest 0.4.12 and later
Depends default
Licenses: Code LGPL 2.1, textures CC BY-SA

For use with 'singlenode' mapgen.
City street grid areas, coastal intercity roads, tunnel roads, 2 dirt paths, wooden bridges over fissures.
Underground fissure system.
All default ores.
White lines, raised half-slab pavements.
Mountains up to y = 256.
Tree, grass and flower areas with varying density.
Mod's own appletree drops saplings that are grown by voxelmanip.
Overgeneration is used in x and z axes for continuous roads and paths over chunk borders.

Spawnplayer function randomly searches a large area for land to spawn players on.
Players are spawned scattered up to 1280 nodes from world centre.
The player scatter from world centre can be set by parameter 'PSCA' in the functions.lua file, since oceans can be up to 2kn across searches will fail when PSCA is set too small.
