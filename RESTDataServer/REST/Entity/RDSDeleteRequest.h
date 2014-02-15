//
//  RDSDeleteRequest.h
//  RESTDataServer
//
//  Created by Douglas Pedley on 2/9/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import "RDSRequest.h"

@interface RDSDeleteRequest : RDSRequest

@property (nonatomic, copy) NSString *entityID;

+ (instancetype)request:(HTTPMessage *)request connection:(HTTPConnection *)connection URI:(NSString *)path;

@end
