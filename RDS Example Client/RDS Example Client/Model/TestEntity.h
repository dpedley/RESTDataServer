//
//  TestEntity.h
//  RESTDataServer
//
//  Created by Douglas Pedley on 1/31/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface TestEntity : NSManagedObject

@property (nonatomic, retain) NSNumber * testFloat;
@property (nonatomic, retain) NSNumber * testID;
@property (nonatomic, retain) NSString * testName;

+(NSString *)idAttribute;

@end
