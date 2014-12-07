require! <[fs zlib]>
require! './util': {b2v,b2u,u2b,b2i64,makebuf}

nbt = do
  traverse: (chunk) -> for k,v of chunk.data => @_traverse(k, v, 0)
  _traverse: (name, v, lv) ->
    str = ""
    if v.type < 7 => str = v.value
    else if v.type == 7  => str = "Byte Array (#{v.value.length})"
    else if v.type == 8  => str = "[#{v.value}]"
    else if v.type == 9  => 
      str = "List (" + (if v.value.length => "Type #{v.subtype} x #{v.value.length}" else "empty") + ")" 
    else if v.type == 11 => str = "Int Array  (#{v.value.length})"
    console.log "#{'  ' * lv}#{' ' * ( if v.type>9 => 0 else 1)}#{v.type} [#name]#{' ' * (20 - name.length)}#str"
    if v.type == 9 and v.value.length > 0 and v.value.0.type == 10 => 
      @_traverse("#{name}[0]", v.value.0, lv + 1)
    else if v.type == 10 => for k,v of v.value => @_traverse(k, v, lv + 1)
    
  encode: (data) ->
    size = [@size(k,v) for k,v of data].reduce(((a,b)->a+b),0)
    buf = new Buffer(size)
    offset = 0
    for k,v of data =>
      delta = @_encode k, v, buf, offset
      offset += delta
    buf[offset] = 0
    # TODO: better copy method
    nbuf = new Buffer(offset)
    for i from 0 til offset => nbuf[i] = buf[i]
    nbuf
  _encode: (name, {type,value}, buf, offset, tag = true) ->
    delta = 0 
    if tag => delta = @encode-tag name, {type, value}, buf, offset
    offset += delta
    if type == 0 => return delta
    if type == 1 => 
      buf.writeInt8 value, offset
      return delta + 1
    if type == 2 => 
      buf.writeInt16BE value, offset
      return delta + 2
    if type == 3 =>
      buf.writeInt32BE value, offset
      return delta + 4
    if type == 4 => 
      buf.writeUInt32BE value.0, offset
      buf.writeUInt32BE value.1, offset + 4
      return delta + 8
    if type == 5 => 
      buf.writeFloatBE value, offset
      return delta + 4
    if type == 6 => 
      buf.writeDoubleBE value, offset
      return delta + 8
    if type == 7 =>
      buf.writeInt32BE value.length, offset
      for i from 0 til value.length => buf[offset + 4 + i] = value[i]
      return delta + 4 + value.length
    if type == 8 => 
      len = buf.write value, offset, value.length, 'utf-8'
      return delta + len
    if type == 9 =>
      if value.length == 0 => buf.writeInt8 0, offset else buf.writeInt8 value.0.type, offset
      buf.writeInt32BE value.length, offset + 1
      delta2 = 0
      for item in value =>
        delta2 += @_encode null, item, buf, offset + 5 + delta2, false
      return delta + 1 + 4 + delta2
    if type == 10 =>
      delta2 = 0
      for k,v of value => delta2 += @_encode k, v, buf, offset + delta2
      buf.writeInt8 0, offset + delta2
      return delta + delta2 + 1
    if type == 11 =>
      buf.writeInt32BE value.length, offset
      for i from 0 til value.length => buf.writeInt32BE value[i], offset + (i * 4) + 4
      return delta + 4 + value.length * 4
    # should not be here
    return 0


  encode-tag: (name, {type,value}, buf, offset) ->
    buf.writeUInt8 type, offset
    if type == 0 => return 1
    buf.writeUInt16BE name.length, offset + 1
    delta = buf.write name, offset + 3, name.length, 'utf-8'
    delta + 3

  size: (name, {type, value}) ->
    len = if type < 7 => [0 1 2 4 8 4 8][type]
      else if type == 7 => 4 + value.length
      else if type == 8 => 2 + u2b(value).length
      else if type == 9 => 1 + 4 + [@size(null, v) for v in value].reduce(((a,b)->a+b),0)
      else if type == 10 =>
        [3 + @size n, value[n] for n of value].reduce(((a,b)->a+b),0) + 1 # + 1 for type 0
      else if type == 11 => 4 + 4 * value.length
      else 0
    if name!=null => len += ( 3 + u2b(name).length )
    return len

  parse: (data, offset = 0) ->
    ret = @compound data, offset, data.length
    return ret.1

  tag: (data, offset) ->
    type = data[offset]
    if type == 0 => return [1, {type, name: ""}]
    length = b2v(data, offset + 1, 2)
    name = b2u(data, offset + 3, length)
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
      ret[t.name] = {type: t.type, value: v}


  data: (data, offset, tag) ->
    if tag.type < 7 =>
      return switch tag.type
        | 0 => [0, 0]
        | 1 => [1, data[offset]]
        | 2 => [2, data.readInt16BE(offset)]
        | 3 => [4, data.readInt32BE(offset)]
        | 4 => [8, [data.readUInt32BE(offset), data.readUInt32BE(offset + 4)]]
        | 5 => [4, data.readFloatBE(offset)]
        | 6 => [8, data.readDoubleBE(offset)]

    if tag.type == 7 =>
      len = b2v(data, offset, 4)
      ret = makebuf(data, offset + 4, len)
      return [len + 4, ret]
    if tag.type == 8 =>
      len = b2v(data, offset, 2)
      ret = b2u(data, offset + 2, len)
      return [len + 2, ret]
    if tag.type == 9 =>
      tagid = b2v(data, offset, 1)
      len = b2v(data, offset + 1, 4)
      ret = []
      ptr = 5
      for i from 0 til len =>
        [delta, value, subtype] = @data data, offset + ptr, {type: tagid}
        ret ++= [{type: tagid, value}]
        ptr += delta
      return [ptr, ret, tagid]
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
