//
//  RDSClient.h
//  RDS Example Client
//
//  Created by Douglas Pedley on 2/1/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@protocol RDSClientIDAttributeProtocol <NSObject>

+(NSString *)idAttribute;

@end

typedef void(^RDSClientRegisterCompletion)(BOOL success, NSDictionary *schema);
typedef void(^RDSClientFetchCompletion)(NSManagedObject *managedObject);
typedef void(^RDSClientFetchArrayCompletion)(NSArray *arrayOfManagedObjects);
typedef void(^RDSClientCreateCompletion)(BOOL success, NSDictionary *responseDictionary);
typedef void(^RDSClientUpdateCompletion)(BOOL success, NSDictionary *responseDictionary);

@interface RDSClient : NSObject

@property (nonatomic, strong) NSURL *baseURL;

+(instancetype)clientToServer:(NSURL *)baseURL;

/**
 *  registerClass will check to see if the server has a schema
 *  available for aManagedObjectClass, if not, it will create
 *  the schema on the server.
 *
 *  @param aManagedObjectClass subclass of a managed object
 *  @param entityDescription the classes entity
 */
-(void)registerClass:(Class)aManagedObjectClass usingDescription:(NSEntityDescription *)entityDescription completion:(RDSClientRegisterCompletion)completion;

/**
 *  These are the Fetch Methods
 */
-(void)allObjectsOfClass:(Class)aManagedObjectClass completion:(RDSClientFetchArrayCompletion)completion;
-(void)objectOfClass:(Class)aManagedObjectClass withAttribute:(NSString *)attributeName matchingValue:(NSString *)value completion:(RDSClientFetchCompletion)completion;
-(void)objectOfClass:(Class)aManagedObjectClass withID:(NSString *)idValue completion:(RDSClientFetchCompletion)completion;

/**
 *  Create and Update Methods
 */
-(void)createObject:(NSManagedObject *)managedObject completion:(RDSClientCreateCompletion)completion;
-(void)updateObject:(NSManagedObject *)managedObject completion:(RDSClientUpdateCompletion)completion;

@end

