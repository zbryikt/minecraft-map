require! <[./region]>

console.log \123
data = []
region.read "/Users/tkirby/Library/Application\ Support/minecraft/saves/The\ Whole\ New\ World/region/r.0.0.mca" .then (r) -> 
  console.log \ok
  sections = r.chunks[0][0].data[""].value.Level.value.Sections.value
  for s in sections =>
    Y = s.value.Y.value
    console.log Y
    if Y == 5 =>
      for x from 0 to 15
        for y from 0 to 15
          for z from 0 to 15
            v = s.value.Blocks.value[y * 256 + z * 16 + x]
            data.push v
      console.log data.length
      break
#region.read \r.0.0.mca, -> console.log it.chunks[0][0]
#region.read \r.0.0.mca .then -> console.log it
