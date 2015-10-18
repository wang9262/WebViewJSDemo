//
//  WebViewJavascriptBridge.m
//  WebViewJavascriptBridge
//
//  Created by Vong on 15/10/10.
//  Copyright © 2015年 Vong. All rights reserved.
//

#import "WebViewJavascriptBridge.h"

typedef NSDictionary WVJBMessage;

@interface WebViewJavascriptBridge ()

@property (weak, nonatomic) UIWebView *webView;
@property (weak, nonatomic) id<UIWebViewDelegate> webViewDelegate;
@property (assign, nonatomic) NSInteger uniqueId;
@property (assign, nonatomic) NSUInteger numRequestsLoading;
@property (strong, nonatomic) NSMutableArray* startupMessageQueue;
@property (strong, nonatomic) NSMutableDictionary* responseCallbacks;
@property (strong, nonatomic) NSMutableDictionary* messageHandlers;
@property (strong, nonatomic) WVJBHandler messageHandler;

@end

#ifdef DEBUG
#define WVJBLog(x, ...) NSLog(@"%s %d: " x, __FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define WVJBLog(x, ...)
#endif

@implementation WebViewJavascriptBridge

#pragma mark - LifeCycle

- (void)dealloc
{
    self.webView.delegate = nil;
    self.webView = nil;
    self.webViewDelegate = nil;
    self.startupMessageQueue = nil;
    self.responseCallbacks = nil;
    self.messageHandlers = nil;
    self.messageHandler = nil;
}

+ (instancetype)bridgeForWebView:(UIWebView *)webView
                         handler:(WVJBHandler)handler
{
    return [self bridgeForWebView:webView
                  webViewDelegate:nil
                          handler:handler];
}

+ (instancetype)bridgeForWebView:(UIWebView *)webView
                 webViewDelegate:(id<UIWebViewDelegate>)webViewDelegate
                         handler:(WVJBHandler)messageHandler
{
    WebViewJavascriptBridge* bridge = [[WebViewJavascriptBridge alloc] init];
    [bridge platformSpecificSetup:webView
                  webViewDelegate:webViewDelegate
                          handler:messageHandler];
    [bridge reset];
    return bridge;
}

#pragma mark - Public

static bool logging = false;
+ (void)enableLogging
{
    logging = true;
}

- (void)send:(id)data
{
    [self send:data responseCallback:nil];
}

- (void)send:(id)data responseCallback:(WVJBResponseCallback)responseCallback
{
    [self sendData:data responseCallback:responseCallback handlerName:nil];
}

- (void)callHandler:(NSString *)handlerName
{
    [self callHandler:handlerName data:nil responseCallback:nil];
}

- (void)callHandler:(NSString *)handlerName data:(id)data
{
    [self callHandler:handlerName data:data responseCallback:nil];
}

- (void)callHandler:(NSString *)handlerName
               data:(id)data
   responseCallback:(WVJBResponseCallback)responseCallback
{
    [self sendData:data responseCallback:responseCallback handlerName:handlerName];
}

- (void)registerHandler:(NSString *)handlerName handler:(WVJBHandler)handler
{
    self.messageHandlers[handlerName] = [handler copy];
}

- (void)reset
{
    self.startupMessageQueue = [NSMutableArray array];
    self.responseCallbacks = [NSMutableDictionary dictionary];
    self.uniqueId = 0;
}

#pragma mark - Private

- (void)sendData:(id)data
responseCallback:(WVJBResponseCallback)responseCallback
     handlerName:(NSString*)handlerName
{
    NSMutableDictionary* message = [NSMutableDictionary dictionary];
    
    if (data) {
        message[@"data"] = data;
    }
    
    if (responseCallback) {
        NSString* callbackId = [NSString stringWithFormat:@"objc_.cb_.%ld", ++self.uniqueId];
        self.responseCallbacks[callbackId] = [responseCallback copy];
        message[@"callbackId"] = callbackId;
    }
    
    if (handlerName) {
        message[@"handlerName"] = handlerName;
    }
    [self queueMessage:message];
}

- (void)queueMessage:(WVJBMessage*)message
{
    if (self.startupMessageQueue) {
        [self.startupMessageQueue addObject:message];
    } else {
        [self dispatchMessage:message];
    }
}

- (void)dispatchMessage:(WVJBMessage*)message
{
    NSString *messageJSON = [self serializeMessage:message];
    [self log:@"SEND" json:messageJSON];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    NSString *command = @"WebViewJavascriptBridge._handleMessageFromObjC('%@');";
    NSString* javascriptCommand = [NSString stringWithFormat:command, messageJSON];
    if ([[NSThread currentThread] isMainThread]) {
        [self.webView stringByEvaluatingJavaScriptFromString:javascriptCommand];
    } else {
        __strong UIWebView* strongWebView = self.webView;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [strongWebView stringByEvaluatingJavaScriptFromString:javascriptCommand];
        });
    }
}

- (void)flushMessageQueue
{
    NSString *command = @"WebViewJavascriptBridge._fetchQueue();";
    NSString *messageQueueString = [self.webView stringByEvaluatingJavaScriptFromString:command];
    
    id messages = [self deserializeMessageJSON:messageQueueString];
    if (![messages isKindOfClass:[NSArray class]]) {
        WVJBLog(@"Invalid %@ received: %@", [messages class], messages);
        return;
    }
    for (WVJBMessage* message in messages) {
        if (![message isKindOfClass:[WVJBMessage class]]) {
            WVJBLog(@"Invalid %@ received: %@", [message class], message);
            continue;
        }
        [self log:@"RCVD" json:message];
        
        NSString* responseId = message[@"responseId"];
        if (responseId) {
            WVJBResponseCallback responseCallback = self.responseCallbacks[responseId];
            responseCallback(message[@"responseData"]);
            [self.responseCallbacks removeObjectForKey:responseId];
        } else {
            WVJBResponseCallback responseCallback = NULL;
            NSString* callbackId = message[@"callbackId"];
            if (callbackId) {
                responseCallback = ^(id responseData) {
                    if (responseData == nil) {
                        responseData = [NSNull null];
                    }
                    
                    WVJBMessage* msg = @{ @"responseId":callbackId,
                                          @"responseData":responseData
                                          };
                    [self queueMessage:msg];
                };
            } else {
                responseCallback = ^(id ignoreResponseData) {
                    // Do nothing
                };
            }
            
            WVJBHandler handler;
            if (message[@"handlerName"]) {
                handler = self.messageHandlers[message[@"handlerName"]];
            } else {
                handler = self.messageHandler;
            }
            
            if (!handler) {
                [NSException raise:@"WVJBNoHandlerException"
                            format:@"No handler for message from JS: %@", message];
            }
            
            handler(message[@"data"], responseCallback);
        }
    }
}

- (NSString *)serializeMessage:(id)message
{
    NSData *data = [NSJSONSerialization dataWithJSONObject:message options:0 error:nil];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSArray*)deserializeMessageJSON:(NSString *)messageJSON {
    NSData *data = [messageJSON dataUsingEncoding:NSUTF8StringEncoding];
    return [NSJSONSerialization JSONObjectWithData:data
                                           options:NSJSONReadingAllowFragments error:nil];
}

- (void)log:(NSString *)action json:(id)json {
    if (!logging) {
        return;
    }
    if (![json isKindOfClass:[NSString class]]) {
        json = [self serializeMessage:json];
    }
    if ([json length] > 500) {
        WVJBLog(@"WVJB %@: %@ [...]", action, [json substringToIndex:500]);
    } else {
        WVJBLog(@"WVJB %@: %@", action, json);
    }
}

- (void)platformSpecificSetup:(UIWebView *)webView
              webViewDelegate:(id<UIWebViewDelegate>)webViewDelegate
                      handler:(WVJBHandler)messageHandler
{
    self.messageHandler = messageHandler;
    self.webView = webView;
    self.webViewDelegate = webViewDelegate;
    self.messageHandlers = [NSMutableDictionary dictionary];
    self.webView.delegate = self;
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (webView != self.webView) { return; }
    
    self.numRequestsLoading--;
    NSString *command = @"typeof WebViewJavascriptBridge == 'object'";
    NSString *result = [webView stringByEvaluatingJavaScriptFromString:command];
    if (self.numRequestsLoading == 0 && ![result isEqualToString:@"true"]) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"WebViewJavascriptBridge"
                                                             ofType:@"js"];
        NSString *js = [NSString stringWithContentsOfFile:filePath
                                                 encoding:NSUTF8StringEncoding
                                                    error:nil];
        [webView stringByEvaluatingJavaScriptFromString:js];
    }
    
    if (self.startupMessageQueue) {
        for (id queuedMessage in self.startupMessageQueue) {
            [self dispatchMessage:queuedMessage];
        }
        self.startupMessageQueue = nil;
    }
    
    __strong typeof(self.webViewDelegate) strongDelegate = self.webViewDelegate;
    if (strongDelegate &&
        [strongDelegate respondsToSelector:@selector(webViewDidFinishLoad:)])
    {
        [strongDelegate webViewDidFinishLoad:webView];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if (webView != self.webView) { return; }
    
    self.numRequestsLoading--;
    
    __strong typeof(self.webViewDelegate) strongDelegate = self.webViewDelegate;
    SEL selector = @selector(webView:didFailLoadWithError:);
    BOOL shouldRespond = [strongDelegate respondsToSelector:selector];
    if (strongDelegate && shouldRespond) {
        [strongDelegate webView:webView didFailLoadWithError:error];
    }
}

           - (BOOL)webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request
            navigationType:(UIWebViewNavigationType)navigationType
{
    if (webView != self.webView) {
        return YES;
    }
    
    NSURL *url = [request URL];
    __strong typeof(self.webViewDelegate) strongDelegate = self.webViewDelegate;
    SEL selector = @selector(webView:shouldStartLoadWithRequest:navigationType:);
    BOOL shouldRespond = [strongDelegate respondsToSelector:selector];
    if ([[url scheme] isEqualToString:kCustomProtocolScheme]) {
        if ([[url host] isEqualToString:kQueueHasMessage]) {
            [self flushMessageQueue];
        } else {
            WVJBLog(@"Received unknown command %@://%@", kCustomProtocolScheme, [url path]);
        }
        return NO;
    } else if (strongDelegate && shouldRespond) {
        BOOL result = [strongDelegate webView:webView
                   shouldStartLoadWithRequest:request
                               navigationType:navigationType];
        return result;
    } else {
        return YES;
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    if (webView != self.webView) { return; }
    
    self.numRequestsLoading++;
    
    __strong typeof(self.webViewDelegate) strongDelegate = self.webViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [strongDelegate webViewDidStartLoad:webView];
    }
}

@end
