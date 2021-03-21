//
//  WQAAjaxHookString.m
//  WQAWebviewComponent
//
//  Created by 王庆安 on 2021/3/19.
//

#import "WQAAjaxHookString.h"

NSString * WQAAjaxHookString_js() {
    #define __wvjb_js_func__(x) #x
    
    static NSString * preprocessorJSCode = @__wvjb_js_func__(
    (function (factory) {
        typeof define === 'function' && define.amd ? define(factory) :
        factory();
    }(function () { 'use strict';

        var realXhr = 'RealXMLHttpRequest';
        var hookAjax = function (proxy) {
            window[realXhr] = window[realXhr] || XMLHttpRequest;
            XMLHttpRequest = function () {
                var xhr = new window[realXhr]();
                for (var attr in xhr) {
                    var type = '';
                    try {
                        type = typeof xhr[attr];
                    }
                    catch (e) { }
                    if (type === 'function') {
                        this[attr] = hookFunction(attr);
                    }
                    else {
                        Object.defineProperty(this, attr, {
                            get: getterFactory(attr),
                            set: setterFactory(attr),
                            enumerable: true
                        });
                    }
                }
                this.xhr = xhr;
            };

            function getterFactory(attr) {
                return function () {
                    var v = this.hasOwnProperty(attr + '_')
                        ? this[attr + '_']
                        : this.xhr[attr];
                    var attrGetterHook = (proxy[attr] || {})['getter'];
                    return (attrGetterHook && attrGetterHook(v, this)) || v;
                };
            }

            function setterFactory(attr) {
                return function (v) {
                    var xhr = this.xhr;
                    var that = this;
                    var hook = proxy[attr];
                    if (typeof hook === 'function') {
                        xhr[attr] = function () {
                            proxy[attr](that) || v.apply(xhr, arguments);
                        };
                    }
                    else {
                        var attrSetterHook = (hook || {})['setter'];
                        v = (attrSetterHook && attrSetterHook(v, that)) || v;
                        try {
                            xhr[attr] = v;
                        }
                        catch (e) {
                            this[attr + '_'] = v;
                        }
                    }
                };
            }
            function hookFunction(fun) {
                return function () {
                    var args = [].slice.call(arguments);
                    if (proxy[fun] && proxy[fun].call(this, args, this.xhr)) {
                        return;
                    }
                    return this.xhr[fun].apply(this.xhr, args);
                };
            }
            return window[realXhr];
        };

        var isAndroid = /(Android)/i.test(navigator.userAgent);
        function postMessageToNative(invokeRequestHeader) {
            isAndroid
                ? window.bgo_bridge.postMessageToNative(invokeRequestHeader)
                : window.webkit.messageHandlers.postMessageToNative.postMessage(invokeRequestHeader);
        }
        function fakePost(params) {
            var postRequest = {
                jsonrpc: '2.0',
                id: params.postId,
                method: 'onAjaxHookPost',
                params: JSON.stringify(params)
            };
            postMessageToNative(JSON.stringify(postRequest));
        }
        var waitingXhrs = new Object();
        window.waitingXhrs = waitingXhrs;
        window.ajaxHookPostCallback = function (response) {
            var invokeResponse = JSON.parse(response);
            var id = invokeResponse.id;
            if (waitingXhrs[id]) {
                var xhr = waitingXhrs[id];
                xhr.send();
                delete waitingXhrs[id];
            }
            return;
        };

        var count = 1;
        var postId = +new Date() + "-" + count++;
        hookAjax({
            open: function (_a, xhr) {
                var method = _a[0], url = _a[1];
                if (method.toLocaleLowerCase() === "post") {
                    xhr.isFakePost = true;
                    xhr.postUrl = url;
                    postId = +new Date() + "-" + count++;
                }
            },
            send: function (args, xhr) {
                if (xhr.isFakePost) {
                    xhr.setRequestHeader("postId", postId);
                    fakePost({
                        url: xhr.postUrl,
                        body: args[0],
                        postId: postId
                    });
                    waitingXhrs[postId] = xhr;
                    return true;
                }
            }
        });

    }));

    ); // END preprocessorJSCode

    #undef __wvjb_js_func__
    return preprocessorJSCode;
};
