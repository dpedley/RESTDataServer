//
//  RDSNumberTransformer.m
//  RESTDataServer
//
//  Created by Douglas Pedley on 2/10/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import "RDSNumberTransformer.h"

@implementation RDSNumberTransformer

+ (Class)transformedValueClass
{
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

NSNumberFormatter *_numberFmt = nil;
- (id)reverseTransformedValue:(id)value
{
    if (!_numberFmt)
    {
        _numberFmt = [[NSNumberFormatter alloc] init];
    }
    return (value == nil) ? nil : [_numberFmt numberFromString:value];
}

- (id)transformedValue:(id)value
{
    if (!_numberFmt)
    {
        _numberFmt = [[NSNumberFormatter alloc] init];
    }
    return (value == nil) ? nil : [value stringValue];
}

@end
