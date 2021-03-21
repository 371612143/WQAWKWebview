

(function (factory) {
    typeof define === 'function' && define.amd ? define(factory) :
    factory();
}(function () {
    window.wqaJsBridge = {
        invokeMethod : invokeMethod,
        postMessageByNative : postMessageByNative,
        globalCallBack : globalCallBack
    };
    var jsCallbackHandlers = {};
    function invokeMethod(method, params = {}, handler) {
        let cbid = method + Math.random().stringify;
        jsCallbackHandlers[cbid] = handler;
        const dic = { jsonrpc: "2.0", id: cbid, method: method, params: JSON.stringify(params)};
        
        if (window.webkit && window.webkit.messageHandlers) {
            window.webkit.messageHandlers.postMessageToNative.postMessage(JSON.stringify(dic))
        }
    };

    function postMessageByNative(message) {
       obj = JSON.parse(message);
       if (obj.id && jsCallbackHandlers[obj.id]) {
            jsCallbackHandlers[obj.id](obj);
       }
   };

   function globalCallBack(obj) {
        if (obj.error) {
            window.wqaJsBridge.invokeMethod("showJascriptRunError", {name:obj.name}, null);
        }
   };
}));
  




(function() {
  console.log('start original api test');
  if (!(window.webkit && window.webkit.messageHandlers))
      return;
  window.webkit.messageHandlers.DeviceInfo.postMessage({});
  window.webkit.messageHandlers.DeviceInfoBlock.postMessage({});
  window.webkit.messageHandlers.DeviceInfoBlock.postMessage([]);
  window.webkit.messageHandlers.DeviceInfoBlock.postMessage(1);
  window.webkit.messageHandlers.DeviceInfoBlock.postMessage(1.3);
  window.webkit.messageHandlers.DeviceInfoBlock.postMessage('c');
})();


