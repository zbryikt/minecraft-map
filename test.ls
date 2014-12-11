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

box = (map, x, y, z, wx, wy, wz, id) ->
  dv = [[1, 1, 1], [wx - 1, wy - 1, wz - 1]]
  for i from 0 to 2
    dv.0[i] = dv.1[i]
    for cx from x til x + wx by (dv.0.0 or 1)
      for cy from y til y + wy by (dv.0.1 or 1)
        for cz from z til z + wz by (dv.0.2 or 1)
          set map, cx, cy, cz, id
    dv.0[i] = 1

wireframe = (map, x, y, z, wx, wy, wz, id) ->
  dv = [[wx - 1, wy - 1, wz - 1], [wx - 1, wy - 1, wz - 1]]
  for i from 0 to 2
    dv.0[i] = 1
    for cx from x til x + wx by (dv.0.0 or 1)
      for cy from y til y + wy by (dv.0.1 or 1)
        for cz from z til z + wz by (dv.0.2 or 1)
          set map, cx, cy, cz, id
    dv.0[i] = dv.1[i]

fill = (map, x, y, z, wx, wy, wz, id) ->
  for cx from x til x + wx
    for cy from y til y + wy
      for cz from z til z + wz
        set map, cx, cy, cz, id

set = (map, x, y, z, id) ->
  [cx, cy, cz] = [x / 16, y / 16, z / 16]map -> parseInt it
  [rx, rz] = [ cx / 32, cz / 32 ]map -> parseInt it
  [dx, dy, dz] = [x, y, z]map -> it % 16
  region = map.regions[rx][rz]
  chunk = region.chunks[cz][cx]
  sections = chunk.data[""].value.Level.value.Sections.value
  for s in sections =>
    Y = s.value.Y.value
    if Y == cy => return (s.value.Blocks.value[dy * 256 + dz * 16 + dx] = id)
  ns = ^^sections[0]
  ns.value.Y.value = cy
  for dx from 0 to 15 => for dy from 0 to 15 => for dz from 0 to 15 =>
    ns.value.Blocks.value[dy * 256 + dz * 16 + dx] = 0
  sections.push ns

patch = ->
  console.log "reading original map..."
  (regions) <- map.read "/Users/tkirby/workspace/zbryikt/minecraft/tests/" .then
  console.log "patching map..."

  /*for cx from 0 to 31 => for cz from 0 to 31 =>
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
  */

  console.log "saving..."
  <- map.write "/Users/tkirby/workspace/zbryikt/minecraft/out", regions .then
  verify!

single-patch = ->
  console.log "read..."
  (r) <- region.read \tests/sample.mca .then
  console.log "ok. patching..."
  regions = {0: {0: r <<< {x: 0, z: 0}}}
  m = {regions}
  wireframe m, 1, 99, 1, 10,  6, 10, 17
  fill m, 1, 89 ,1, 10, 10, 10, 20
  box m, 1, 99, 1, 10, 1, 10, 17
  box m, 1, 104, 1, 10, 1, 10, 17
  box m, 2, 100, 1, 8, 4, 1, 20
  box m, 2, 100, 10, 8, 4, 1, 20
  box m, 1, 100, 2, 1, 4, 8, 20
  box m, 10, 100, 2, 1, 4, 8, 20

  console.log "patched."
  <- map.write "/Users/tkirby/workspace/zbryikt/minecraft/out", regions .then
  console.log \done

single-patch!
