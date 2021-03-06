// Generated by LiveScript 1.3.1
var fs, zlib, bluebird, nbt, Promise, ref$, v2b, b2v, b2u, makebuf, readFile, inflate, deflate, region;
fs = require('fs');
zlib = require('zlib');
bluebird = require('bluebird');
nbt = require('./nbt');
Promise = require('bluebird');
ref$ = require('./util'), v2b = ref$.v2b, b2v = ref$.b2v, b2u = ref$.b2u, makebuf = ref$.makebuf;
readFile = Promise.promisify(fs.readFile);
inflate = Promise.promisify(zlib.inflate);
deflate = Promise.promisify(zlib.deflate);
region = {
  read: function(filename){
    var this$ = this;
    return readFile(filename).then(function(data){
      var r, x, z;
      r = {
        chunks: {},
        data: data
      };
      return Promise.all((function(){
        var i$, j$, results$ = [];
        for (i$ = 0; i$ <= 31; ++i$) {
          x = i$;
          for (j$ = 0; j$ <= 31; ++j$) {
            z = j$;
            results$.push({
              x: x,
              z: z
            });
          }
        }
        return results$;
      }()).map(function(arg$){
        var x, z, offset, blockCount, timestamp, ref$, length, compressionType, chunk;
        x = arg$.x, z = arg$.z;
        offset = 4 * (z * 32 + x);
        blockCount = b2v(data, offset + 3, 1);
        timestamp = b2v(data, offset + 4096, 4);
        offset = b2v(data, offset, 3) * 4096;
        ref$ = blockCount
          ? [b2v(data, offset, 4), b2v(data, offset + 4, 1)]
          : [0, 0], length = ref$[0], compressionType = ref$[1];
        ((ref$ = r.chunks)[x] || (ref$[x] = {}))[z] = chunk = {
          x: x,
          z: z,
          blockCount: blockCount,
          offset: offset,
          length: length,
          timestamp: timestamp,
          compressionType: compressionType
        };
        if (blockCount === 0) {
          return;
        }
        chunk.buffer = makebuf(data, offset + 5, length - 1);
        return this$.parseChunk(chunk);
      }).filter(function(it){
        return it;
      })).then(function(){
        return r;
      });
    });
  },
  write: function(filename, r){
    var x, z, this$ = this;
    return Promise.all((function(){
      var i$, j$, results$ = [];
      for (i$ = 0; i$ <= 31; ++i$) {
        x = i$;
        for (j$ = 0; j$ <= 31; ++j$) {
          z = j$;
          results$.push({
            x: x,
            z: z
          });
        }
      }
      return results$;
    }()).map(function(arg$){
      var x, z, chunk;
      x = arg$.x, z = arg$.z;
      chunk = r.chunks[x][z];
      if (!chunk || chunk.blockCount === 0) {
        return new Promise(function(it){
          return it();
        });
      }
      return this$.encodeChunk(chunk).then(function(zbuf){
        if (zbuf) {
          return chunk.buffer = zbuf;
        }
      });
    })).then(function(){
      var regionLen, i$, x, j$, z, chunk, ref$, chunklen, sectorCount, regionBuf, sectorOffset, base;
      regionLen = 8192;
      for (i$ = 0; i$ <= 31; ++i$) {
        x = i$;
        for (j$ = 0; j$ <= 31; ++j$) {
          z = j$;
          chunk = r.chunks[x][z];
          if (chunk.blockCount === 0) {
            ref$ = [0, 0], chunklen = ref$[0], sectorCount = ref$[1];
          } else {
            chunklen = r.chunks[x][z].buffer.length + 1;
            sectorCount = parseInt(Math.ceil((chunklen + 4) / 4096));
            regionLen += sectorCount * 4096;
          }
          ref$ = r.chunks[x][z];
          ref$.length = chunklen;
          ref$.sectorCount = sectorCount;
        }
      }
      regionBuf = new Buffer(regionLen);
      sectorOffset = 2;
      for (i$ = 0; i$ <= 31; ++i$) {
        x = i$;
        for (j$ = 0; j$ <= 31; ++j$) {
          z = j$;
          chunk = r.chunks[x][z];
          base = 4 * (z * 32 + x);
          v2b(regionBuf, base, 3, chunk.blockCount === 0 ? 0 : sectorOffset);
          regionBuf[base + 3] = chunk.sectorCount;
          v2b(regionBuf, 4096 + base, 4, chunk.timestamp);
          if (chunk.blockCount) {
            regionBuf.writeInt32BE(chunk.length, sectorOffset * 4096);
            regionBuf.writeInt8(2, sectorOffset * 4096 + 4);
            chunk.buffer.copy(regionBuf, sectorOffset * 4096 + 5, 0);
          }
          sectorOffset += chunk.sectorCount;
        }
      }
      return fs.writeFileSync(filename, regionBuf);
    });
  },
  parseChunk: function(chunk){
    return inflate(chunk.buffer).then(function(inflatedBuf){
      return chunk.data = nbt.parse(inflatedBuf);
    });
  },
  encodeChunk: function(chunk){
    var rawbuf;
    if (chunk.blockCount !== 0) {
      rawbuf = nbt.encode(chunk.data);
      return deflate(rawbuf);
    }
    return new Promise(function(it){
      return it();
    }).then(function(){
      return null;
    });
  }
};
module.exports = region;