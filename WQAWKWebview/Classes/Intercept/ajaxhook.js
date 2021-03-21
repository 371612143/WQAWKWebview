/**
  * fake-post v1.0.8
  * (c) 2019-present feikerwu
  */
(function (factory) {
    typeof define === 'function' && define.amd ? define(factory) :
    factory();
}(function () { 'use strict';

    var realXhr = 'RealXMLHttpRequest';
    //Call this function will override the `XMLHttpRequest` object
    var hookAjax = function (proxy) {
        // Avoid double hook
        window[realXhr] = window[realXhr] || XMLHttpRequest;
        XMLHttpRequest = function () {
            var xhr = new window[realXhr]();
            // We shouldn't hook XMLHttpRequest.prototype because we can't
            // guarantee that all attributes are on the prototype。
            // Instead, hooking XMLHttpRequest instance can avoid this problem.
            for (var attr in xhr) {
                var type = '';
                try {
                    type = typeof xhr[attr]; // May cause exception on some browser
                }
                catch (e) { }
                if (type === 'function') {
                    // hook methods of xhr, such as `open`、`send` ...
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
        // Generate getter for attributes of xhr
        function getterFactory(attr) {
            return function () {
                var v = this.hasOwnProperty(attr + '_')
                    ? this[attr + '_']
                    : this.xhr[attr];
                var attrGetterHook = (proxy[attr] || {})['getter'];
                return (attrGetterHook && attrGetterHook(v, this)) || v;
            };
        }
        // Generate setter for attributes of xhr; by this we have an opportunity
        // to hook event callbacks （eg: `onload`） of xhr;
        function setterFactory(attr) {
            return function (v) {
                var xhr = this.xhr;
                var that = this;
                var hook = proxy[attr];
                if (typeof hook === 'function') {
                    // hook  event callbacks such as `onload`、`onreadystatechange`...
                    xhr[attr] = function () {
                        proxy[attr](that) || v.apply(xhr, arguments);
                    };
                }
                else {
                    //If the attribute isn't writable, generate proxy attribute
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
        // Hook methods of xhr.
        function hookFunction(fun) {
            return function () {
                var args = [].slice.call(arguments);
                if (proxy[fun] && proxy[fun].call(this, args, this.xhr)) {
                    return;
                }
                return this.xhr[fun].apply(this.xhr, args);
            };
        }
        // Return the real XMLHttpRequest
        return window[realXhr];
    };

    var isAndroid = /(Android)/i.test(navigator.userAgent);
    /**
     * 通知客户端调用某个方法
     * @param {*} invokeRequestHeader rpc协议的请求头
     */
    function postMessageToNative(invokeRequestHeader) {
        isAndroid
            ? window.bgo_bridge.postMessageToNative(invokeRequestHeader)
            : window.webkit.messageHandlers.postMessageToNative.postMessage(invokeRequestHeader);
    }
    /* 发送post请求 */
    function fakePost(params) {
        var postRequest = {
            jsonrpc: '2.0',
            id: params.postId,
            method: 'onAjaxHookPost',
            params: JSON.stringify(params)
        };
        postMessageToNative(JSON.stringify(postRequest));
    }
    /**
     * 正在等待的请求
     */
    var waitingXhrs = new Object();
    window.waitingXhrs = waitingXhrs;
    /**
     * 接收到参数请求之后再去发送请求
     */
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
