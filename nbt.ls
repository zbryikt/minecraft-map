require! <[fs zlib]>
require! './util': {b2v,unicode,makebuf}

nbt = do
  parse: (data, offset = 0) ->
    ret = @compound data, offset, data.length
    return ret.1

  tag: (data, offset) ->
    type = data[offset]
    if type == 0 => return [1, {type, name: ""}]
    length = b2v(data, offset + 1, 2)
    name = unicode(data, offset + 3, length)
    [1 + 2 + length, {type, name}]

  compound: (data, offset, limit = 0) ->
    ret = {}
    delta = 0
    while true =>
      if limit and delta >= limit => return [delta, ret]
      [d1, t] = @tag data, offset + delta
      delta += d1
      if t.type == 0 => return [delta, ret]
      [d2, v] = @data data, offset + delta, t
      delta += d2
      ret[t.name] = v


  data: (data, offset, tag) ->
    if tag.type < 7 =>
      return switch tag.type
        | 0 => [0, 0]
        | 1 => [1, data[offset]]
        | 2 => [2, b2v(data, offset, 2)]
        | 3 => [4, b2v(data, offset, 4)]
        | 4 => [8, b2v(data, offset, 8)]
        | 5 => [4, b2v(data, offset, 4)] # todo: implement arrat -> float
        | 6 => [8, b2v(data, offset, 8)] # todo: implement arrat -> double

    if tag.type == 7 =>
      len = b2v(data, offset, 4)
      ret = makebuf(data, offset + 4, len)
      return [len + 4, ret]
    if tag.type == 8 =>
      len = b2v(data, offset, 2)
      ret = unicode(data, offset + 2, len)
      return [len + 2, ret]
    if tag.type == 9 =>
      tagid = b2v(data, offset, 1)
      len = b2v(data, offset + 1, 4)
      ret = []
      ptr = 5
      for i from 0 til len =>
        [delta, value] = @data data, offset + ptr, {type: tagid}
        ret ++= [value]
        ptr += delta
      return [ptr, ret]
    if tag.type == 10 =>
      return @compound(data, offset)
    if tag.type == 11 =>
      len = b2v(data, offset, 4)
      ret = new Array(len)
      for i from 0 til len =>
        ret[i] = b2v(data, offset + 4 + i * 4, 4)
      return [len * 4 + 4, ret]

#block in a chk:
# Y2 = parseInt(y / 16) => find section with Y = Y2
# index inside Blocks array: (y % 16) * 256 + (z % 16) * 16 + (x % 16)

module.exports = nbt
