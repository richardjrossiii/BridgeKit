// NOTE: This is NOT a normal JS file.
// It is meant to be included directly into an objective-c source file.
// As such, you can't put just anything in this file.
#define STRINGIFY(data) @#data

static NSString *const __BridgeKit_JS_String = STRINGIFY(
	// BridgeKit.js
    // A simple, flexible, and extensible way to send messages back and forth with a UIWebView.
    // Supports multiple requests per execution period, callbacks, synchronous requests,
    // and AJAX integration.
    (function(window) {
        function isSVGDocument() {
            // SVGs change how we have to embed iframes,
            // so we need a way to check if the document is SVG or not.
            // I currently don't know of a better way than this, as
            // there is no standard way to get the MIME type of a page
            // through HTML.
            return (document.documentElement.tagName.toLowerCase() === 'svg');
        }

        function BridgeKitMutex() {
            // WARNING: This is some evil hacking right here.
            // JS executed through 'stringByEvaluatingJavascriptString:'
            // is actaully executed on a separate thread from the normal
            // JS runtime, making it possible to wait on that other thread to set a value in the DOM.
            // I don't reccomend doing this for much other than this,
            // but it is possible, and we're going to leverage it.
            // fetch a unique id and use that
            this.id = BridgeKitMutex.usedIds++;
     
            // literally, all this will do is hold data that will be returned, nothing more.
            this.mutexElement = document.createElementNS('http://www.richardjrossiii.com/2013/bridgekit/mutex', 'mutex');
            this.mutexElement.setAttribute('id', '__bridgekit_mutex_' + this.id);

            document.documentElement.appendChild(this.mutexElement);
     
            this.wait = function(timeout) {
                // basically, because javascript doesn't have a 'sleep' function,
                // we're going to use a while loop to simply wait out the time period, or until our mutex gives us data.
                var start = Date.now();
                var result = null;
                // wait for the timeout, or for us to be notified
                while (true) {
                    if (this.mutexElement.getAttribute('data-notified')) {
                        result = decodeURIComponent(this.mutexElement.getAttribute('data-result'));
                        break;
                    }
                    if ((Date.now() - start) > timeout) break;
                }
     
                document.documentElement.removeChild(this.mutexElement);
     
                return result;
            };
        }
     
        BridgeKitMutex.usedIds = 0;
        BridgeKitMutex.notify = function(id, data) {
            // get the mutex in question
            var mutexElement = document.getElementById('__bridgekit_mutex_' + id);
     
            // if the mutex doesn't exist, we can't notify it
            if (mutexElement === null) {
                return;
            }
     
            // set the results, and the notified attribute on the target
            mutexElement.setAttribute('data-result', encodeURIComponent(data));
            mutexElement.setAttribute('data-notified', true);
        };

        function BridgeKit() {
            // this is an array of function objects (or a javascript string to exec),
            // that are called with arbitrary parameters by objective-c.
            // They can be passed when sending, or simply 'hooked up' with a method call.
            this.callbacks = [];
            var urlScheme = "";
            
            // This is how we message back to objective-c.
            // Like 95% of solutions, it does involve a URL.
            function sendMessage(msgName, args) {
                // encode the arguments
                for (var i = 0; i < args.length; i++) {
                    args[i] = encodeURIComponent(JSON.stringify(args[i]));
                }

                var url = urlScheme + "://";
                url += encodeURIComponent(msgName);
                url += "/";
                url += encodeURIComponent(args.join('/'));

                // first, create an iframe. We MUST specify the namespace here for this to work,
                // as SVG screw with that, making iframes unrecognized by the browser.
                var iframe = document.createElementNS('http://www.w3.org/1999/xhtml', 'iframe');
                iframe.setAttribute('src', url);
                var iframeContainer = iframe;
                if (isSVGDocument()) {
                    // special hackery for SVGs. They require a <foreignObject> tag to hold the iframe.
                    iframeContainer = document.createElementNS('http://www.w3.org/2000/svg', 'foreignObject');
                    var body = document.createElementNS('http://www.w3.org/1999/xhtml', 'body');
                    iframeContainer.appendChild(body);
                    body.appendChild(iframe);
                }
     
                // to send the message, we add the iframe,
                // which triggers a 'shouldLoadRequest' method
                // to objective-c.
                document.documentElement.appendChild(iframeContainer);
     
                // because the page shouldn't return any content,
                // we can simply remove the child element and be fine.
                document.documentElement.removeChild(iframeContainer);
            }
     
            this.registerEvent = function(event, callback) {
                this.callbacks.push(callback);
                sendMessage('registerEvent/' + (this.callbacks.length - 1), [event]);
            };
     
            this.registerNativeEvent = function(event, callback) {
                this.callbacks.push(callback);
                sendMessage('registerNativeEvent/' + (this.callbacks.length - 1), [event]);
            };
     
            this.sendSynchronousRequest = function(request, parameters) {
                var mutex = new BridgeKitMutex();
     
                this.sendAsynchronousRequest('synchronous/' + request, parameters, function(results) {
                    BridgeKitMutex.notify(mutex.id, results);
                });
     
                // Default timeout: 1 second
                return mutex.wait(1000);
            };
     
            this.sendAsynchronousRequest = function(request, parameters, callback) {
                this.callbacks.push(callback);
                sendMessage('request/' + (this.callbacks.length - 1), [ request, parameters ]);
            };
     
            this.setUrlScheme = function(newScheme) {
                urlScheme = newScheme;
            };
        }
     
        window.BridgeKit = new BridgeKit();
        window.BridgeKitMutex = BridgeKitMutex;
        window.BK = window.BridgeKit;
    })(window);
);