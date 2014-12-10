require! <[fs path ./region ./nbt ./map]>
require! bluebird: Promise

verify = ->
  console.log "verifying..."
  (regions) <- map.read "/Users/tkirby/workspace/zbryikt/minecraft/out" .then
  console.log "traversing..."
  for z from 0 to 31 => for x from 0 to 31 =>
    chunk = regions[0][0].chunks[z][x]
    if !chunk => continue
    nbt.traverse chunk


patch = ->
  console.log "reading original map..."
  (regions) <- map.read "/Users/tkirby/workspace/zbryikt/minecraft/tests/" .then
  console.log "patching map..."
  for cx from 0 to 31 => for cz from 0 to 31 =>
    chunk = regions[0][0].chunks[cz][cx]
    if !chunk or !chunk.data => continue
    sections = regions[0][0].chunks[cz][cx].data[""]value.Level.value.Sections.value
    [x,y,z] = [0,0,0]
    for s in sections =>
      console.log s
      console.log s.value.Y
      Y = s.value.Y.value
      for y from 0 to 15 => for x from 0 to 15 => for z from 0 to 15 => s.value.Blocks.value[y*256 + z*16 + x] = 0
      if Y <=3 => 
        for y from 0 to 15 => for x from 0 to 15 => for z from 0 to 15 => s.value.Blocks.value[y*256 + z*16 + x] = 56
      if Y == 4 =>
        for y from 0 to 7 => for x from 0 to 15 => for z from 0 to 15 =>
          s.value.Blocks.value[y * 256 + z * 16 + x] = if (x % 2) == 0 => 79 else 0

  console.log "saving..."
  <- map.write "/Users/tkirby/workspace/zbryikt/minecraft/out", regions .then
  verify!

patch!
