//
//  WebViewJavascriptBridge.h
//  WebViewJavascriptBridge
//
//  Created by Vong on 15/10/10.
//  Copyright © 2015年 Vong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define kCustomProtocolScheme @"wvjbscheme"
#define kQueueHasMessage      @"__WVJB_QUEUE_MESSAGE__"

typedef void (^WVJBResponseCallback)(id responseData);
typedef void (^WVJBHandler)(id data, WVJBResponseCallback responseCallback);

@interface WebViewJavascriptBridge : NSObject<UIWebViewDelegate>

/**
 *  创建新的 bridge
 *
 *  @param webView         需要桥接的 webview
 *  @param webViewDelegate webview 的 delegate
 *  @param handler         默认消息处理 block
 */
+ (instancetype)bridgeForWebView:(UIWebView *)webView
                         handler:(WVJBHandler)handler;

/**
 *  @see bridgeForWebView: webViewDelegate: handler: resourceBundle:
 */
+ (instancetype)bridgeForWebView:(UIWebView *)webView
                 webViewDelegate:(id<UIWebViewDelegate>)webViewDelegate
                         handler:(WVJBHandler)handler;

- (void)send:(id)message;

/**
 *  发送消息给 JS
 *
 *  @param message          消息内容
 *  @param responseCallback 消息发送后 JS 的回调
 */
- (void)send:(id)message responseCallback:(WVJBResponseCallback)responseCallback;

/**
 *  注册一个 handler 供 JS 的 callHandler 调用
 *  JS 调用时 handler 需使用相同名称
 *
 *  @param handlerName 名称
 *  @param handler     JS 回调 block
 */
- (void)registerHandler:(NSString*)handlerName
                handler:(WVJBHandler)handler;

/**
 *  调用 JS 已注册的 handler
 *
 *  @param handlerName      名称
 *  @param data             传递给 JS 的数据
 *  @param responseCallback JS 收到消息的回调
 */
- (void)callHandler:(NSString*)handlerName
               data:(id)data
   responseCallback:(WVJBResponseCallback)responseCallback;

/**
 *  @see callHandler: data: responseCallback:
 */
- (void)callHandler:(NSString*)handlerName;

/**
 *  @see callHandler: data: responseCallback:
 */
- (void)callHandler:(NSString*)handlerName data:(id)data;

- (void)reset;
+ (void)enableLogging;

@end
