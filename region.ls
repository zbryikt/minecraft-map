require! <[fs zlib bluebird ./nbt]>
require! bluebird: Promise
require! './util': {b2v,unicode,makebuf}

read-file = Promise.promisify fs.read-file
inflate = Promise.promisify zlib.inflate

region = do
  read: (filename, cb) ->
    (data) <~ read-file(filename).then
    region = {chunks: {}, data}
    Promise.all(
      (for x from 0 to 31 => for z from 0 to 31 =>
        offset = 4 * (z * 32 + x)
        block-count = b2v(data, offset + 3, 1)
        timestamp = b2v(data, offset + 4096, 4)
        offset = b2v(data, offset, 3) * 4096
        [length, compression-type] = if block-count =>
          [b2v(data, offset, 4), b2v(data, offset + 4, 1)]
        else => [0,0]
        region.chunks.{}[x][z] = chunk = {x, z, block-count, offset, length, timestamp, compression-type}
        if block-count == 0 => continue
        chunk.buffer = makebuf(data, offset + 5, length - 1)
        @parse-chunk chunk
      ).filter -> it
    ).then -> region
  parse-chunk: (chunk, cb) ->
    (inflated-buf) <- inflate chunk.buffer .then
    chunk.data = nbt.parse(inflated-buf)[""]
    #cb chunk.data

module.exports = region
