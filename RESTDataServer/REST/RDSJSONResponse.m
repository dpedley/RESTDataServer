//
//  RDSJSONResponse.m
//  RESTDataServer
//
//  Created by Douglas Pedley on 1/31/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import "RDSJSONResponse.h"

@implementation RDSJSONResponse

+(instancetype)withJSONString:(NSString *)jsonString
{
    return [[self alloc] initWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
}

+(instancetype)withJSONData:(NSData *)jsonData
{
    return [[self alloc] initWithData:jsonData];
}

-(NSDictionary *)httpHeaders
{
    return @{@"Content-type": @"application/json"};
}

@end
