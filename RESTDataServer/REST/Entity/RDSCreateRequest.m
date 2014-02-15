//
//  RDSPostEntity.m
//  RESTDataServer
//
//  Created by Douglas Pedley on 1/31/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import "RDSCreateRequest.h"
#import "HTTPMessage.h"
#import "RDSCoreDataStack.h"

@interface RDSCreateRequest ()

@property (nonatomic, strong) NSManagedObject *createdObject;
@property (nonatomic, strong) NSArray *createdObjects;

@end

@implementation RDSCreateRequest

-(id)initWithRequest:(HTTPMessage *)request connection:(HTTPConnection *)connection method:(NSString *)method URI:(NSString *)path
{
    self = [super initWithRequest:request connection:connection method:method URI:path];
    if (self)
    {
        NSString *entityName = nil;
        
        if (self.schemaView)
        {
            entityName = @"RDSEntityDescription";
        }
        else
        {
            entityName = self.entityName;
        }
        
        NSData *postData = [request body];
        if (postData)
        {
            NSError *error = nil;
            id postObject = [NSJSONSerialization JSONObjectWithData:postData options:0 error:&error];
            
            if (postObject)
            {
                if ([postObject isKindOfClass:[NSDictionary class]])
                {
                    NSDictionary *postDictionary = postObject;
                    DDLogInfo(@"postDictionary: %@", postDictionary);
                    
                    // Is this a new schema?
                    if (self.schemaView)
                    {
                        NSArray *schemaDicts = [postDictionary objectForKey:@"schema"];
                        NSEntityDescription *newEntityDescription = [[NSEntityDescription alloc] init];
                        newEntityDescription.name = self.entityName;
                        if (schemaDicts && [schemaDicts isKindOfClass:[NSArray class]])
                        {
                            NSMutableArray *schemaProperties = [NSMutableArray array];
                            for (NSDictionary *schemaDictionary in schemaDicts)
                            {
                                NSString *propertyName = [schemaDictionary objectForKey:@"name"];
                                NSString *propertyType = [schemaDictionary objectForKey:@"type"];
                                NSAttributeType attributeType = [self attributeTypeFromString:propertyType];
                                NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
                                attribute.name = propertyName;
                                attribute.attributeType = attributeType;
                                attribute.Optional = YES;
                                attribute.Transient = NO;
                                attribute.attributeValueClassName = [self attributeValueClassNameFromType:attributeType];
                                [schemaProperties addObject:attribute];
                            }
                            [newEntityDescription setProperties:schemaProperties];
                        }
                        
                        // Lets write the entity description to a file.
                        RDSCoreDataStack *newStack = [RDSCoreDataStack saveEntityName:self.entityName];
                        NSURL *entityDescriptionURL = [newStack entityURL];
                        NSMutableData *entityDescriptionData = [[NSMutableData alloc] init];
                        NSKeyedArchiver *keyedArchiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:entityDescriptionData];
                        [newEntityDescription encodeWithCoder:keyedArchiver];
                        [keyedArchiver finishEncoding];
                        [entityDescriptionData writeToURL:entityDescriptionURL atomically:YES];
                        newStack.entityDescription = newEntityDescription;
                        
                        NSManagedObject *insertedObject = [[NSManagedObject alloc] initWithEntity:newEntityDescription insertIntoManagedObjectContext:newStack.managedObjectContext];
                        [newStack.managedObjectContext save:&error];
                        DDLogInfo(@"insertedObject: %@", insertedObject);
                        
                        [newStack.managedObjectContext deleteObject:insertedObject];
                        [newStack saveAndNotifyBlocks];
                    }
                    
                    __block NSManagedObject *insertedObject = nil;
                    
                    NSManagedObjectContext *saveContext = self.coreData.managedObjectContext;
                    
                    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:entityName inManagedObjectContext:saveContext];
                    
                    if (!entityDescription)
                    {
                        DDLogError(@"no entity description: %@", entityName);
                    }
                    else
                    {
                        insertedObject = [[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:saveContext];
                        
                        if (insertedObject)
                        {
                            NSArray *allKeys = [postDictionary allKeys];
                            for (NSString *key in allKeys)
                            {
                                id theObject = [postDictionary objectForKey:key];
                                
                                if ([theObject isKindOfClass:[NSArray class]])
                                {
                                    // TODO: an array of subobjects
                                }
                                else if ([theObject isKindOfClass:[NSDictionary class]])
                                {
                                    // TODO: a subobject
                                }
                                else
                                {
                                    @try {
                                        [insertedObject setValue:[postDictionary objectForKey:key] forKey:key];
                                    }
                                    @catch (NSException *exception) {
                                        DDLogCError(@"Field mapping error key/entity: %@/%@", key, entityName);
                                    }
                                    @finally {
                                    }
                                }
                            }
                            
                            [self.coreData saveAndNotifyBlocks];
                            self.createdObject = insertedObject;
                        }
                    }
                }
            }
        }
    }
    return self;
}

+ (instancetype)request:(HTTPMessage *)request connection:(HTTPConnection *)connection URI:(NSString *)path
{
    RDSCreateRequest *req = [[self alloc] initWithRequest:request connection:connection method:@"POST" URI:path];
    
    NSLog(@"Post request: %@ %@", req.entityName, req.requestParameters);
    
    return req;
}

/**
 *  Post Entity this is a db create entry, it will fail 
 *  if the entityID exists. (TODO:)
 *
 *  @return valid json data.
 */
- (NSData *)dataResponse
{
    NSData *data = nil;
    
    if (self.createdObject)
    {
        NSManagedObject *resObject = self.createdObject;
        NSDictionary *dict = [self dictionaryFromManagedObject:resObject];
        NSError *error = nil;
        data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    }
    else if (self.createdObjects)
    {
        NSMutableArray *responseArray = [NSMutableArray array];
        for (NSManagedObject *resObject in self.createdObjects)
        {
            NSDictionary *dict = [self dictionaryFromManagedObject:resObject];
            [responseArray addObject:dict];
        }
        
        NSError *error = nil;
        data = [NSJSONSerialization dataWithJSONObject:responseArray options:0 error:&error];
    }
    
    return data;
}

@end
