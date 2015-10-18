//
//  TestModel.m
//  Test
//
//  Created by Vong on 15/10/10.
//  Copyright © 2015年 Vong. All rights reserved.
//

#import "TestModel.h"

@implementation TestModel

- (NSString *)description
{
    NSString *str = [NSString stringWithFormat:@"TestModel With testString: %@,and numberStr:%@",
                                                self.testString,self.numberStr];
    return str;
}

- (void)modelTest
{
    NSLog(@"modelTest!!!");
}

- (void)test
{
    NSLog(@"Test!!!");
}

@end
