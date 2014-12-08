require! <[fs path ./region ./nbt]>
require! bluebird: Promise

readdir = Promise.promisify fs.readdir

map = do
  read: (mappath) ->
    (files) <- readdir path.join(mappath, \region) .then
    regions = {}
    Promise.all files.map (fn) -> 
      ret = /r\.([0-9-]+)\.([0-9-]+)\.mca/.exec fn
      if !ret => return
      [x,z] = [ret.1, ret.2]
      (r) <- region.read path.join(mappath, \region, fn) .then
      regions.{}[x][z] = r <<< {x,z}
    .then -> regions
  write: (mappath, regions) ->
    if not fs.exists-sync(mappath) => fs.mkdir-sync mappath
    if not fs.exists-sync(path.join mappath, \region) => fs.mkdir-sync path.join(mappath, \region)
    Promise.all [regions[x][z] for x of regions for z of regions[x]].map (r) ->
      region.write path.join(mappath, \region, "r.#{r.x}.#{r.z}.mca"), r
    .then -> console.log \done

#(regions) <- map.read "/Users/tkirby/Library/Application Support/minecraft/saves/FORDEV" .then
(regions) <- map.read "/Users/tkirby/workspace/zbryikt/minecraft" .then
map.write "/Users/tkirby/workspace/zbryikt/minecraft2", regions
