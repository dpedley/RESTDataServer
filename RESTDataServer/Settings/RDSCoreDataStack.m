//
//  RDSCoreDataStack.m
//  RESTDataServer
//
//  Created by Douglas Pedley on 2/6/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import "RDSCoreDataStack.h"

@interface RDSCoreDataStack ()

@property (nonatomic, copy) NSString *entityName;

@end

@implementation RDSCoreDataStack

static NSMutableArray *_entityBlocks = nil;

+(void)entityNamed:(RDSCoreDataStackEntityNameBlock)nameBlock dataChanged:(RDSCoreDataStackBlock)changeBlock
{
    if (!_entityBlocks)
    {
        _entityBlocks = [[NSMutableArray alloc] init];
    }
    
    [_entityBlocks addObject:@{
                               @"name" : [nameBlock copy],
                               @"change" : [changeBlock copy]
                               }];
}

// TODO: save vs read
+(instancetype)readOnlyAppSettings
{
    return [self forAppSettings];
}

+(instancetype)saveAppSettings
{
    return [self forAppSettings];
}

+(instancetype)readOnlyEntityName:(NSString *)entityName
{
    return [self byEntityName:entityName];
}

+(instancetype)saveEntityName:(NSString *)entityName
{
    return [self byEntityName:entityName];
}

+(instancetype)forAppSettings
{
    RDSCoreDataStack *newStack = [[self alloc] init];
    newStack.entityName = @"RDSEntityDescription";
    NSBundle *bundle = [NSBundle bundleForClass:[[[NSApplication sharedApplication] delegate] class]];
    newStack.managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:bundle]];
    
    return newStack;
}

+(instancetype)byEntityName:(NSString *)entityName
{
    RDSCoreDataStack *newStack = [[self alloc] init];
    newStack.entityName = entityName;
    return newStack;
}

+(void)removeStorageForEntityName:(NSString *)entityName
{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSURL *deleteURL = [[self storageURL] URLByAppendingPathComponent:[entityName stringByAppendingString:@".sqlite"]];
    NSError *error = nil;
    if ([fileMgr fileExistsAtPath:[deleteURL path]])
    {
        [fileMgr removeItemAtURL:deleteURL error:&error];
    }
    deleteURL = [[self storageURL] URLByAppendingPathComponent:[entityName stringByAppendingString:@".sqlite-shm"]];
    if ([fileMgr fileExistsAtPath:[deleteURL path]])
    {
        [fileMgr removeItemAtURL:deleteURL error:&error];
    }
    deleteURL = [[self storageURL] URLByAppendingPathComponent:[entityName stringByAppendingString:@".sqlite-wal"]];
    if ([fileMgr fileExistsAtPath:[deleteURL path]])
    {
        [fileMgr removeItemAtURL:deleteURL error:&error];
    }
    deleteURL = [[self storageURL] URLByAppendingPathComponent:[entityName stringByAppendingString:@".entity"]];
    if ([fileMgr fileExistsAtPath:[deleteURL path]])
    {
        [fileMgr removeItemAtURL:deleteURL error:&error];
    }
}

- (NSURL *)coreDataURL
{
    return [[[self class] storageURL] URLByAppendingPathComponent:[self.entityName stringByAppendingString:@".sqlite"]];
}

// Returns the URL to the application's Documents directory.
+ (NSURL *)storageURL
{
    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *rdsURL = [appSupportURL URLByAppendingPathComponent:@"RESTDataServer"];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BOOL isDir;
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        if (![fileMgr fileExistsAtPath:[rdsURL path] isDirectory:&isDir])
        {
            NSError *error = nil;
            [fileMgr createDirectoryAtURL:rdsURL withIntermediateDirectories:YES attributes:nil error:&error];
        }
    });
    
    return rdsURL;
}

- (NSURL *)entityURL
{
    return [[[self class] storageURL] URLByAppendingPathComponent:[self.entityName stringByAppendingString:@".entity"]];
}

#pragma mark - Notifications

- (void)handleDataModelChange:(NSNotification *)note
{
    // Remove notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextDidSaveNotification
                                                  object:_managedObjectContext];
    @synchronized(_entityBlocks)
    {
        for (NSDictionary *entityBlockDict in _entityBlocks)
        {
            RDSCoreDataStackEntityNameBlock nameBlock = entityBlockDict[@"name"];
            if (nameBlock && [nameBlock() isEqualToString:self.entityName])
            {
                RDSCoreDataStackBlock changeBlock = entityBlockDict[@"change"];
                if (changeBlock)
                {
                    dispatch_async( dispatch_get_main_queue(), ^{ changeBlock(note); });
                }
            }
        }
    }
}

- (void)saveAndNotifyBlocks;
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDataModelChange:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:_managedObjectContext];
    NSError *error = nil;
    [self.managedObjectContext save:&error];
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil)
    {
        return _managedObjectContext;
    }
    
    if (!self.entityName)
    {
        return nil;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];

    	NSUndoManager *anUndoManager = [[NSUndoManager	alloc] init];
    	[_managedObjectContext setUndoManager:anUndoManager];
        
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil)
    {
        return _managedObjectModel;
    }
    
    if (!self.entityName)
    {
        return nil;
    }
    
    NSEntityDescription *entityDescription = self.entityDescription;
    
    if (!entityDescription)
    {
        NSURL *entityURL = [self entityURL];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:[entityURL path]])
        {
            NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:[NSData dataWithContentsOfURL:entityURL]];
            entityDescription = [[NSEntityDescription alloc] initWithCoder:unarchiver];
            [unarchiver finishDecoding];
            self.entityDescription = entityDescription;
        }
    }
    
    if (entityDescription)
    {
        _managedObjectModel = [[NSManagedObjectModel alloc] init];
        [_managedObjectModel setEntities:[NSArray arrayWithObject:entityDescription]];
    }
    
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil)
    {
        return _persistentStoreCoordinator;
    }
    
    if (!self.entityName)
    {
        return nil;
    }
    
    NSURL *storeURL = [self coreDataURL];
    
    NSError *error = nil;
    NSManagedObjectModel *momd = self.managedObjectModel;
    
    if (!momd)
    {
        return nil;
    }
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:momd];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

static RDSCoreDataStack *_rdsEntityStack = nil;
+(RDSEntityDescription *)schemaForEntityNamed:(NSString *)entityName
{
    if (!_rdsEntityStack)
    {
        _rdsEntityStack = [RDSCoreDataStack readOnlyAppSettings];
        [_rdsEntityStack performSelectorOnMainThread:@selector(managedObjectContext) withObject:nil waitUntilDone:YES];
    }
    
    RDSCoreDataStack *entityStack = _rdsEntityStack;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"RDSEntityDescription"];
    [request setFetchLimit:1];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", entityName];
    [request setPredicate:predicate];
    NSError *error = nil;
    NSArray *results = [entityStack.managedObjectContext executeFetchRequest:request error:&error];
    NSManagedObject *result = nil;
    if (results && [results count]>0)
        result = [results objectAtIndex:0];
    return (RDSEntityDescription *)result;
}

+(NSArray *)schemata
{
    if (!_rdsEntityStack)
    {
        _rdsEntityStack = [RDSCoreDataStack readOnlyAppSettings];
        [_rdsEntityStack performSelectorOnMainThread:@selector(managedObjectContext) withObject:nil waitUntilDone:YES];
    }
    
    RDSCoreDataStack *entityStack = _rdsEntityStack;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"RDSEntityDescription"];
    [request setFetchLimit:40]; // arbitrary limit
    NSError *error = nil;
    NSArray *results = [entityStack.managedObjectContext executeFetchRequest:request error:&error];
    if (results && [results count]>0)
        return results;
    return nil;
}

+(AppSettings *)settings
{
    if (!_rdsEntityStack)
    {
        _rdsEntityStack = [RDSCoreDataStack readOnlyAppSettings];
        [_rdsEntityStack performSelectorOnMainThread:@selector(managedObjectContext) withObject:nil waitUntilDone:YES];
    }
    
    RDSCoreDataStack *entityStack = _rdsEntityStack;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"AppSettings"];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *results = [entityStack.managedObjectContext executeFetchRequest:request error:&error];
    NSManagedObject *result = nil;
    if (results && [results count]>0)
        result = [results objectAtIndex:0];
    return (AppSettings *)result;
}

@end
