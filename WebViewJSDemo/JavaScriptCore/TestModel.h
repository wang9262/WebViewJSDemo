//
//  TestModel.h
//  Test
//
//  Created by Vong on 15/10/10.
//  Copyright © 2015年 Vong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@protocol TestModelDelegate <JSExport>

@property (nonatomic, copy) NSString *testString;
- (void)modelTest;


@end

@interface TestModel : NSObject <TestModelDelegate>

@property (nonatomic, copy) NSString *testString;
@property (nonatomic, copy) NSString *numberStr;

@end
