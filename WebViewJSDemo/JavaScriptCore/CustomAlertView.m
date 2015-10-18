//
//  CustomAlertView.m
//  WebViewDemo
//
//  Created by Vong on 15/10/10.
//  Copyright © 2015年 Vong. All rights reserved.
//

#import "CustomAlertView.h"

@interface CustomAlertView ()<UIAlertViewDelegate>

@property (strong, nonatomic) JSContext *ctxt;
@property (strong, nonatomic) JSManagedValue *successHandler;
@property (strong, nonatomic) JSManagedValue *failureHandler;

@end

@implementation CustomAlertView

- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
            success:(JSValue *)successHandler
            failure:(JSValue *)failureHandler
            context:(JSContext *)context {
    
    self = [super initWithTitle:title
                        message:message
                       delegate:self
              cancelButtonTitle:@"No"
              otherButtonTitles:@"Yes", nil];
    
    if (self) {
        _ctxt = context;
        
        _successHandler = [JSManagedValue managedValueWithValue:successHandler];
        // A JSManagedValue by itself is a weak reference. You convert it into a conditionally retained
        // reference, by inserting it to the JSVirtualMachine using addManagedReference:withOwner:
        [context.virtualMachine addManagedReference:_successHandler withOwner:self];
        
        _failureHandler = [JSManagedValue managedValueWithValue:failureHandler];
        [context.virtualMachine addManagedReference:_failureHandler withOwner:self];
    }
    return self;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == self.cancelButtonIndex) {
        JSValue *function = [self.failureHandler value];
        [function callWithArguments:@[]];
    } else {
        JSValue *function = [self.successHandler value];
        [function callWithArguments:@[]];
    }
    
    // 此时由于 alert 被销毁，所以需要调用该方法来告知 JSVirtualMachine，之前建立的引用不再存在
    [self.ctxt.virtualMachine removeManagedReference:_failureHandler withOwner:self];
    [self.ctxt.virtualMachine removeManagedReference:_successHandler withOwner:self];
}

@end
