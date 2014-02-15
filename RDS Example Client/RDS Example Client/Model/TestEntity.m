//
//  TestEntity.m
//  RESTDataServer
//
//  Created by Douglas Pedley on 1/31/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import "TestEntity.h"


@implementation TestEntity

@dynamic testFloat;
@dynamic testID;
@dynamic testName;

+(NSString *)idAttribute
{
    return @"testID";
}

@end
