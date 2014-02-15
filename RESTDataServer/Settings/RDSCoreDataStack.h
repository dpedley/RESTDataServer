//
//  RDSCoreDataStack.h
//  RESTDataServer
//
//  Created by Douglas Pedley on 2/6/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSString *(^RDSCoreDataStackEntityNameBlock)();
typedef void(^RDSCoreDataStackBlock)( NSNotification *changeNotification );

@class RDSEntityDescription;
@class AppSettings;

@interface RDSCoreDataStack : NSObject

@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSEntityDescription *entityDescription;

+ (NSURL *)storageURL;
- (NSURL *)entityURL;
- (NSURL *)coreDataURL;

- (void)saveAndNotifyBlocks;

+(instancetype)readOnlyAppSettings;
+(instancetype)saveAppSettings;
+(instancetype)readOnlyEntityName:(NSString *)entityName;
+(instancetype)saveEntityName:(NSString *)entityName;

+(void)removeStorageForEntityName:(NSString *)entityName;

+(void)entityNamed:(RDSCoreDataStackEntityNameBlock)nameBlock dataChanged:(RDSCoreDataStackBlock)changeBlock;

+(RDSEntityDescription *)schemaForEntityNamed:(NSString *)entityName;
+(NSArray *)schemata;

+(AppSettings *)settings;

@end
