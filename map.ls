require! <[fs path ./region]>
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
      region.read path.join(mappath, \region, fn) .then -> regions.{}[x][z] = it
    .then -> console.log regions

map.read "/Users/tkirby/Library/Application Support/minecraft/saves/FORDEV"
