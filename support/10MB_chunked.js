var Buffer = require('buffer').Buffer,
    http   = require('http');

var buffer = new Buffer(1024 * 1024 * 10);

for (i = 0; i < buffer.length; i++) {
  buffer[i] = 0;
}

http.createServer(function(req, res){
  res.writeHead(200);
  res.end(buffer);
}).listen(8084, '127.0.0.1');
