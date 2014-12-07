require! <[./region]>

#region.read \r.0.0.mca, -> console.log it.chunks[0][0]
region.read \r.0.0.mca .then -> console.log it
