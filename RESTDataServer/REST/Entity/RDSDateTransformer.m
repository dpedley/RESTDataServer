//
//  RDSDateTransformer.m
//  RESTDataServer
//
//  Created by Douglas Pedley on 2/24/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import "RDSDateTransformer.h"

@implementation RDSDateTransformer


+ (Class)transformedValueClass
{
    return [NSDate class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

NSDateFormatter *_dateFmt = nil;
- (id)reverseTransformedValue:(id)value
{
    if (!_dateFmt)
    {
        _dateFmt = [[NSDateFormatter alloc] init];
    }
    NSLog(@"rValue: %@ %@", value, [_dateFmt dateFromString:value]);
    return (value == nil) ? nil : [_dateFmt dateFromString:value];
}

- (id)transformedValue:(id)value
{
    if (!_dateFmt)
    {
        _dateFmt = [[NSDateFormatter alloc] init];
    }
    return (value == nil) ? nil : [value stringValue];
}

@end
