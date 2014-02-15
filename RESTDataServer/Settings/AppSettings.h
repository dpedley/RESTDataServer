//
//  AppSettings.h
//  RESTDataServer
//
//  Created by Douglas Pedley on 1/30/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDSEntityDescription.h"

@interface AppSettings : NSManagedObject

@property (nonatomic, retain) NSString * basePath;

@end
