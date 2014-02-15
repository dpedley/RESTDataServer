//
//  RDSJSONResponse.h
//  RESTDataServer
//
//  Created by Douglas Pedley on 1/31/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import "HTTPDataResponse.h"

@interface RDSJSONResponse : HTTPDataResponse

+(instancetype)withJSONData:(NSData *)jsonData;
+(instancetype)withJSONString:(NSString *)jsonString;

@end
