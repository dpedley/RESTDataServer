//
//  Entity.m
//  RESTDataServer
//
//  Created by Douglas Pedley on 1/31/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import "RDSEntityDescription.h"


@implementation RDSEntityDescription

@dynamic idAttribute;
@dynamic name;

+(NSString *)entityName
{
    return @"RDSEntityDescription";
}

@end
