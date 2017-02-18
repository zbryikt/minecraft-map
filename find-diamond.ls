require! <[fs ./region bluebird]>

home = do
  x: -260
  y: 14
  z: -96

pad = (v, len=5) ->
  v = "#v"
  (if v.length < len => " " * (len - v.length) else "") + v
files = fs.readdir-sync "D:\\games\\minecraft\\game-dir\\saves\\20170211\\region\\" .map ->
  "D:\\games\\minecraft\\game-dir\\saves\\20170211\\region\\#it"
diamonds = []

getptr = (rx, rz, cx, cz, Y, x, y, z) ->
  return do
    x: rx * 512 + cx * 16 + x
    y: Y * 16 + y
    z: rz * 512 + cz * 16 + z

find = (name)->
  ret = /([0-9-]+)\.([0-9-]+)/.exec(name)
  [rx,rz] = [+ret.1, +ret.2]
  region.read file .then (r) ->
    for cx from 0 til 32
      for cz from 0 til 32
        chunk = r.chunks[cx][cz];
        if !chunk.data => continue
        sections = chunk.data[""].value.Level.value.Sections.value
        for s in sections =>
          Y = s.value.Y.value
          for x from 0 to 15
            for y from 0 to 15
              for z from 0 to 15
                v = s.value.Blocks.value[y * 256 + z * 16 + x]
                if v == 129 => #56: diamond. 54: chest. 131: trap wire. 19: sponge. 46: tnt. 120: end portal frame. 129: emerald. 103: melon
                  ptr = getptr rx, rz, cx, cz, Y, x, y, z
                  diamonds.push(ptr)

promises = for file in files => find file
bluebird.all promises .then ->
  diamonds.map -> it <<< {d: Math.round(Math.sqrt((it.x - home.x)**2 + (it.y - home.y)**2 + (it.z - home.z)**2))}
  diamonds.sort (a,b) -> b.d - a.d
  console.log diamonds.map(-> "#{pad(it.x)} #{pad(it.y)} #{pad(it.z)} (Distance: #{pad(it.d)}").join("\n")
