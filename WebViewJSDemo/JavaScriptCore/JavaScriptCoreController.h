//
//  WebViewController.h
//  Test
//
//  Created by Vong on 15/10/10.
//  Copyright © 2015年 Vong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>

@protocol TestJSDelegate <JSExport>

- (void)testDemo;
- (void)testWithName:(NSString *)name age:(NSNumber *)age;
JSExportAs(testRename,
           - (void)testRenameMethod:(NSString *)name age:(NSNumber *)age
           );
@property (nonatomic, copy) NSString *text;

@end

@interface JavaScriptCoreController : UIViewController <TestJSDelegate>

@property (nonatomic, copy) NSString *text;

@end
