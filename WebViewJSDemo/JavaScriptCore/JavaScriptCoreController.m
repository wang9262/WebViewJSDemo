//
//  WebViewController.m
//  Test
//
//  Created by Vong on 15/10/10.
//  Copyright © 2015年 Vong. All rights reserved.
//

#import "JavaScriptCoreController.h"
#import "TestModel.h"
#import <objc/runtime.h>

@interface JavaScriptCoreController ()<UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic, strong) UITextField *textField;

@end

@implementation JavaScriptCoreController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSURL *path = [[NSBundle mainBundle] URLForResource:@"test" withExtension:@"html"];
    NSString *html = [NSString stringWithContentsOfURL:path encoding:NSUTF8StringEncoding error:nil];
    [self.webView loadHTMLString:html baseURL:nil];
    
//    测试协议
    TestModel *model = [[TestModel alloc] init];
    model.testString = @"test string";
    model.numberStr = @"123";
    JSContext *context = [[JSContext alloc] initWithVirtualMachine:[[JSVirtualMachine alloc] init]];
    context[@"model"] = model;
    JSValue *modelValue = context[@"model"];
    NSLog(@"model: %@",model);
    NSLog(@"model JSValue: %@",modelValue);
    model.numberStr = @"456";
    [context evaluateScript:@"model.testString = \"anotoher test\";model.numberStr = \"567\""];
    NSLog(@"model: %@",model);
    NSLog(@"model JSValue: %@",modelValue);

    [context evaluateScript:@"model.modelTest()"];
    JSValue *unknowValue = [context evaluateScript:@"model.test()"];
    NSLog(@"unknowValue :%@",unknowValue);
    
    // 给系统类添加 JSExport 协议
    class_addProtocol([UITextField class], @protocol(TestJSDelegate));
    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(100, 200, 100, 30)];
    self.textField.text = @"123";
    self.textField.backgroundColor = [UIColor cyanColor];
    [self.view addSubview:self.textField];
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateText) userInfo:nil repeats:YES];
    [timer fire];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	JSContext *context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    context[@"objcObject"] = self;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	
}

- (void)testDemo
{
    NSLog(@"test!!!");
}

- (void)testWithName:(NSString *)name age:(NSNumber *)age
{
    NSLog(@"name:%@,age:%@",name,age);
}

- (void)testRenameMethod:(NSString *)name age:(NSNumber *)age
{
	NSLog(@"Rename Method ---> name:%@,age:%@",name,age);
}

- (void)updateText
{
    JSContext *context = [[JSContext alloc] init];
    context[@"textField"] = self.textField;
    NSString *script = @"var num = parseInt(textField.text, 10);"
    "++num;"
    "textField.text = num;";
    [context evaluateScript:script];
}

@end
