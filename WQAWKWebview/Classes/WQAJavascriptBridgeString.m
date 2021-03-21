//
//  WQAJavascriptBridgeString.m
//  WQAWebviewComponent
//
//  Created by 王庆安 on 2021/3/19.
//

#import "WQAJavascriptBridgeString.h"

NSString *WQAJavascriptBridgeString(void) {
    #define __wvjb_js_func__(x) #x

    static NSString * preprocessorJSCode = @__wvjb_js_func__(
                                                             (function (factory) {
                                                                 typeof define === 'function' && define.amd ? define(factory) : factory();
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
                                                                 
                                                                 (function testcode() {
                                                                     console.log('start original api test');
                                                                     if (!(window.webkit && window.webkit.messageHandlers))
                                                                         return;
                                                                     
                                                                     window.wqaJsBridge.invokeMethod("DeviceInfo", {}, window.wqaJsBridge.globalCallBack);
                                                                     window.wqaJsBridge.invokeMethod("caniuse", {}, window.wqaJsBridge.globalCallBack);
                                                                     window.wqaJsBridge.invokeMethod("sdkVersion", {}, window.wqaJsBridge.globalCallBack);
                                                                     window.wqaJsBridge.invokeMethod("Clipboard", {mode:'readText'}, window.wqaJsBridge.globalCallBack);
                                                                     window.wqaJsBridge.invokeMethod("Clipboard", {mode:'writeText', textValue:'Clipboard'}, window.wqaJsBridge.globalCallBack);
                                                                     window.wqaJsBridge.invokeMethod("onAjaxHookPost", {}, window.wqaJsBridge.globalCallBack);
                                                                     window.wqaJsBridge.invokeMethod("DeviceInfoBlock", {}, window.wqaJsBridge.globalCallBack);

                                                                     window.webkit.messageHandlers.DeviceInfo.postMessage({});
                                                                     window.webkit.messageHandlers.DeviceInfoBlock.postMessage({});
                                                                     window.webkit.messageHandlers.DeviceInfoBlock.postMessage([]);
                                                                     window.webkit.messageHandlers.DeviceInfoBlock.postMessage(1);
                                                                     window.webkit.messageHandlers.DeviceInfoBlock.postMessage(1.3);
                                                                     window.webkit.messageHandlers.DeviceInfoBlock.postMessage('c');
                                                                   })();
                                                             }));




    );//end

    #undef __wvjb_js_func__
    return preprocessorJSCode;
}
