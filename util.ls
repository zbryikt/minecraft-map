unicode = (data, base, len) ->
  ret = ""
  for i from 0 til len => ret += String.fromCharCode(data[base + i])
  ret

makebuf = (data, base, len) ->
  ret = new Buffer(len)
  for i from 0 til len => ret[i] = data[base + i]
  ret

b2v = (data, base, len, ret = 0) -> 
  for i from 0 til len => ret = ret * 256 + data[base + i]
  ret

module.exports = {unicode,makebuf,b2v}
