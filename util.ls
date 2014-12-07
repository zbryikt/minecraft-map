u2b = (str) -> new Buffer(str, 'utf-8')
b2u = (data, base, len) ->
  buf = makebuf data, base, len
  buf.toString 'utf-8'

  #ret = ""
  #for i from 0 til len => ret += String.fromCharCode(data[base + i])
  #ret

makebuf = (data, base, len) ->
  ret = new Buffer(len)
  for i from 0 til len => ret[i] = data[base + i]
  ret

b2v = (data, base, len, ret = 0) -> 
  for i from 0 til len => ret = ret * 256 + data[base + i]
  ret

module.exports = {b2u,u2b,makebuf,b2v}
