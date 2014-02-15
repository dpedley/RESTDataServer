//
//  RDSPostEntity.h
//  RESTDataServer
//
//  Created by Douglas Pedley on 1/31/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import "RDSRequest.h"

@interface RDSCreateRequest : RDSRequest

@property (nonatomic, copy) NSString *entityID;

+ (instancetype)request:(HTTPMessage *)request connection:(HTTPConnection *)connection URI:(NSString *)path;

@end
