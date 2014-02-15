//
//  RDSEntityDescription.h
//  RESTDataServer
//
//  Created by Douglas Pedley on 1/31/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface RDSEntityDescription : NSManagedObject

@property (nonatomic, retain) NSString * idAttribute;
@property (nonatomic, retain) NSString * name;

@end
