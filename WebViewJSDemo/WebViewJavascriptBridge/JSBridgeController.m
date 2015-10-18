//
//  JSBridgeController.m
//  WebViewJSDemo
//
//  Created by Vong on 15/10/10.
//  Copyright © 2015年 Vong. All rights reserved.
//

#import "JSBridgeController.h"
#import "WebViewJavascriptBridge.h"

@interface JSBridgeController ()<UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic, strong) WebViewJavascriptBridge *bridge;

@end

@implementation JSBridgeController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.parentViewController.title = NSStringFromClass([self class]);
    self.bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView
                                            webViewDelegate:self
                                                    handler:^(id data, WVJBResponseCallback responseCallback) {
                                                        [self showAlertWithData:data];
                                                        if (responseCallback) {
                                                            responseCallback(@"消息来自 OC");
                                                        }
        
    }];
    [self.bridge registerHandler:@"testObjcCallback"
                         handler:^(id data, WVJBResponseCallback responseCallback) {
                             [self showAlertWithData:data];
                             if (responseCallback) {
                                 responseCallback(@"OC：已调用testObjcCallback");
                             }
    }];
    [self.bridge callHandler:@"testJavascriptHandler" data:@"OC 调用 JS Handler"];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"ExampleApp"
                                                         ofType:@"html"];
    NSString *htmlStr = [NSString stringWithContentsOfFile:filePath
                                             encoding:NSUTF8StringEncoding
                                                error:nil];
    [self.webView loadHTMLString:htmlStr baseURL:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showAlertWithData:(id)data
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:[NSString stringWithFormat:@"%@",data]
                                                   delegate:nil
                                          cancelButtonTitle:@"确定"
                                          otherButtonTitles:nil];
    [alert show];
}

@end
