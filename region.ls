require! <[fs zlib bluebird ./nbt]>
require! bluebird: Promise
require! './util': {v2b, b2v,b2u,makebuf}

read-file = Promise.promisify fs.read-file
inflate = Promise.promisify zlib.inflate
deflate = Promise.promisify zlib.deflate

region = do
  read: (filename, cb) ->
    (data) <~ read-file(filename).then
    r = {chunks: {}, data}
    Promise.all(
      [{x,z} for x from 0 to 31 for z from 0 to 31].map( ({x,z}) ~>
        offset = 4 * (z * 32 + x)
        block-count = b2v(data, offset + 3, 1)
        timestamp = b2v(data, offset + 4096, 4)
        offset = b2v(data, offset, 3) * 4096
        [length, compression-type] = if block-count =>
          [b2v(data, offset, 4), b2v(data, offset + 4, 1)]
        else => [0,0]
        r.chunks.{}[x][z] = chunk = {x, z, block-count, offset, length, timestamp, compression-type}
        if block-count == 0 => return
        chunk.buffer = makebuf(data, offset + 5, length - 1)
        @parse-chunk chunk
      ).filter -> it
    ).then -> r
  write: (filename, r) -> 
    <- Promise.all(
      [{x,z} for x from 0 to 31 for z from 0 to 31].map ( ({x,z}) ~>
        chunk = r.chunks[x][z]
        if !chunk => return
        if chunk.block-count =>
        (zbuf) <- @encode-chunk chunk .then
        if zbuf => chunk.buffer = zbuf
      )
    ).then
    region-len = 8192
    for x from 0 to 31 => for z from 0 to 31 =>
      chunklen = r.chunks[x][z].buffer.length + 1
      sector-count = parseInt(Math.ceil((chunklen + 4) / 4096))
      region-len += (sector-count * 4096)
      r.chunks[x][z] <<< {length: chunklen, sector-count}
    region-buf = new Buffer(region-len)
    sector-offset = 2
    for x from 0 to 31 => for z from 0 to 31 =>
      chunk = r.chunks[x][z]
      base = 4 * ( z * 32 + x )
      v2b region-buf, base, 3, sector-offset
      region-buf[base + 3] = chunk.sector-count 
      v2b regions-buf, 4096 + base, 4, chunk.timestamp
      chunk.buffer.copy region-buf, sector-offset * 4096, 0
      sector-offset += chunk.sector-count
    fs.write-file-sync filename, region-buf

  parse-chunk: (chunk) ->
    (inflated-buf) <- inflate chunk.buffer .then
    chunk.data = nbt.parse(inflated-buf)

  encode-chunk: (chunk) ->
    if chunk.block-count != 0 => 
      rawbuf = nbt.encode chunk.data
      return deflate rawbuf
    new Promise(->).then -> null

module.exports = region
