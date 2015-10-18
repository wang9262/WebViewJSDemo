//
//  WebKitController.m
//  WebViewJSDemo
//
//  Created by Vong on 15/10/10.
//  Copyright © 2015年 Vong. All rights reserved.
//

#import "WebKitController.h"
#import <WebKit/WebKit.h>

@interface WebKitController () <WKScriptMessageHandler>
@property (strong, nonatomic) WKWebView *webView;

@end

@implementation WebKitController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.parentViewController.title = NSStringFromClass([self class]);
    [self setupWebView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if ([message.name isEqualToString:@"sendMessageToNative"]) {
        [self showAlertWithData:message.body];
        NSString *scriptSource = @"console.log('Hi this is in JavaScript');";
        [self.webView evaluateJavaScript:scriptSource completionHandler:^(id obj, NSError * _Nullable error) {
            NSLog(@"");
        }];
    }
}

#pragma mark - Private

- (void)setupWebView
{
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    [self addUserScriptsToUserContentController:configuration.userContentController];
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
    CGRect frame = self.webView.frame;
    frame.origin = CGPointMake(0, 64);
    self.webView.frame = frame;
    [self.view addSubview:self.webView];
    NSURL *path = [[NSBundle mainBundle] URLForResource:@"testWekit" withExtension:@"html"];
    NSString *html = [NSString stringWithContentsOfURL:path encoding:NSUTF8StringEncoding error:nil];
    [self.webView loadHTMLString:html baseURL:nil];
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

- (void)addUserScriptsToUserContentController:(WKUserContentController *)userContentController
{
    [userContentController addScriptMessageHandler:self name:@"sendMessageToNative"];
}

@end
