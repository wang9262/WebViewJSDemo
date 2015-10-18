//
//  CustomAlertView.h
//  WebViewDemo
//
//  Created by Vong on 15/10/10.
//  Copyright © 2015年 Vong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface CustomAlertView : UIAlertView

- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
            success:(JSValue *)successHandler
            failure:(JSValue *)failureHandler
            context:(JSContext *)context;

@end
