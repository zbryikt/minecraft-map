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
  (regions) <- map.read "/Users/tkirby/workspace/zbryikt/minecraft" .then
  console.log "patching map..."
  #console.log regions[0][0].chunks[0][0].data[""].value.Level.value.Sections.value.0.value.Blocks
  for cx from 0 to 31 => for cz from 0 to 31 =>
    chunk = regions[0][0].chunks[cz][cx]
    if !chunk or !chunk.data => continue
    sections = regions[0][0].chunks[cz][cx].data[""]value.Level.value.Sections.value
    [x,y,z] = [0,0,0]
    for s in sections =>
      for y from 0 to 15 => for x from 0 to 15 => for z from 0 to 15 => s.value.Blocks.value[y*256 + z*16 + x] = 89

  console.log "saving..."
  <- map.write "/Users/tkirby/workspace/zbryikt/minecraft/out", regions .then
  verify!

patch!
#verify!
