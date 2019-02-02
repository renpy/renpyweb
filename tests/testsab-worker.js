var sab;
var buffer;

onmessage = function(e) {
    console.log('worker: received: ' + e.data.type);
    if (e.data.type == 'init') {
	sab = e.data.sab;
	console.log('worker: sab[0]=');
	console.log(new Uint8Array(sab)[0]);
	buffer = new Uint8Array(sab);
	buffer[0] = 142;
	buffer[1] = 143;
	console.log('worker: sab[0]=');
	console.log(new Uint8Array(sab)[0]);
    } else if (e.data.type == 'print') {
	buffer = new Uint8Array(sab);
	console.log("worker: global buffer");
	console.log(buffer[0]);
	console.log("worker: temp buffer");
	console.log(new Uint8Array(sab)[0]);
    } else if (e.data.type == 'main-activewait') {
	postMessage({type: 'set0-activewait'});
	var i = 0;
	while (i < 100000) {
	    var buffer = new Uint8Array(sab);
	    if (Atomics.load(buffer, 0) == 255) {
		console.log("worker: got 255 in the middle of running 'main' - communication OK");
		break;
	    }
	    console.log(buffer[0]);
	    i++;
	}
	console.log(buffer[0]);
	console.log("worker: end main");
	postMessage({type: 'print', sab: sab});
    } else if (e.data.type == 'main-futexwait') {
	postMessage({type: 'set0-futexwait'});
	var buffer = new Int32Array(sab);
	buffer[0] = 123;
	var status = Atomics.wait(buffer, 0, 123);
	console.log("worker: notified: " + status + " value=" + buffer[0]);
	console.log("worker: got " + buffer[0] + " in the middle of running 'main' - communication OK");
	console.log(buffer[0]);
	console.log("worker: end main");
	postMessage({type: 'print', sab: sab});
    }
}
