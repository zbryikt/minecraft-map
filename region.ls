require! <[fs zlib bluebird ./nbt]>
require! bluebird: Promise
require! './util': {b2v,b2u,makebuf}

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
    console.log filename
    [{x,z} for x from 0 to 31 for z from 0 to 31].map ( ({x,z}) ~>
      chunk = r.chunks[x][z]
      (zbuf) <- @encode-chunk chunk .then
      #chunk.buffer = zbuf
    )

  parse-chunk: (chunk) ->
    (inflated-buf) <- inflate chunk.buffer .then
    chunk.data = nbt.parse(inflated-buf)

  encode-chunk: (chunk) ->
    if chunk.block-count != 0 => 
      rawbuf = nbt.encode chunk.data
    new Promise(->).then ->
    #deflate rawuf



module.exports = region
