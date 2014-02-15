//
//  RDSUpdateRequest.m
//  RESTDataServer
//
//  Created by Douglas Pedley on 2/9/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import "RDSUpdateRequest.h"
#import "HTTPMessage.h"
#import "RDSCoreDataStack.h"

@interface RDSUpdateRequest ()

@property (nonatomic, strong) NSManagedObject *updatedObject;

@end

@implementation RDSUpdateRequest

-(id)initWithRequest:(HTTPMessage *)request connection:(HTTPConnection *)connection method:(NSString *)method URI:(NSString *)path
{
    self = [super initWithRequest:request connection:connection method:method URI:path];
    if (self)
    {
        if ([self.requestParameters count]==1)
        {
            self.entityID = [self.requestParameters objectAtIndex:0];
        }
        
        // Is this a schema update? Not allowed
        if (self.schemaView)
        {
            DDLogInfo(@"PUT schema not allowed");
            return nil;
        }

        NSString *entityName = self.entityName;
        NSString *entityID = self.entityID;
        NSString *entityIDAttribute = nil;
        
        RDSEntityDescription *entitySettings = [RDSCoreDataStack schemaForEntityNamed:entityName];
        if (entitySettings)
        {
            entityIDAttribute = entitySettings.idAttribute;
        }
        
        if (entityID && ![entityID isEqualToString:@""] &&
            entityIDAttribute && ![entityIDAttribute isEqualToString:@""])
        {
            NSData *putData = [request body];
            if (putData)
            {
                NSError *error = nil;
                id updateObject = [NSJSONSerialization JSONObjectWithData:putData options:0 error:&error];
                
                if (updateObject)
                {
                    if ([updateObject isKindOfClass:[NSDictionary class]])
                    {
                        NSDictionary *updateDictionary = updateObject;
                        DDLogInfo(@"updateDictionary: %@", updateDictionary);
                        
                        __block NSManagedObject *updateObject = nil;
                        
                        NSManagedObjectContext *saveContext = self.coreData.managedObjectContext;
                        
                        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:entityName inManagedObjectContext:saveContext];
                        
                        if (!entityDescription)
                        {
                            DDLogError(@"no entity description: %@", entityName);
                        }
                        else
                        {
                            NSFetchRequest *request = [[NSFetchRequest alloc] init];

                            [request setEntity:entityDescription];
                            [request setFetchLimit:1];
                            
                            // Find out if it's a numeric or string id
                            NSAttributeDescription *idDescription = [entityDescription.propertiesByName objectForKey:entityIDAttribute];
                            if (idDescription.attributeType==NSStringAttributeType)
                            {
                                NSPredicate *idPredicate = [NSPredicate predicateWithFormat:[entityIDAttribute stringByAppendingString:@" == %@"], entityID];
                                [request setPredicate:idPredicate];
                            }
                            else
                            {
                                NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
                                NSNumber *idNumber = [fmt numberFromString:entityID];
                                NSPredicate *idPredicate = [NSPredicate predicateWithFormat:[entityIDAttribute stringByAppendingString:@" == %@"], idNumber];
                                [request setPredicate:idPredicate];
                            }
                            
                            __block NSArray *results = nil;
                            __block NSError *error = nil;
                            [saveContext performBlockAndWait:^{
                                results = [saveContext executeFetchRequest:request error:&error];
                            }];

                            if (results && [results count]>0)
                            {
                                updateObject = [results objectAtIndex:0];
                                if (updateObject)
                                {
                                    NSArray *allKeys = [updateDictionary allKeys];
                                    for (NSString *key in allKeys)
                                    {
                                        id theObject = [updateDictionary objectForKey:key];
                                        
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
                                                [updateObject setValue:[updateDictionary objectForKey:key] forKey:key];
                                            }
                                            @catch (NSException *exception) {
                                                DDLogCError(@"Field mapping error key/entity: %@/%@", key, entityName);
                                            }
                                            @finally {
                                            }
                                        }
                                    }
                                    
                                    [self.coreData saveAndNotifyBlocks];
                                    self.updatedObject = updateObject;
                                }
                            }
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
    RDSUpdateRequest *req = [[self alloc] initWithRequest:request connection:connection method:@"PUT" URI:path];
    
    NSLog(@"Put request: %@ %@", req.entityName, req.requestParameters);
    
    return req;
}

- (NSData *)dataResponse
{
    NSData *data = nil;
    
    if (self.updatedObject)
    {
        NSManagedObject *resObject = self.updatedObject;
        NSArray *keys = [[[resObject entity] attributesByName] allKeys];
        NSDictionary *dict = [resObject dictionaryWithValuesForKeys:keys];
        NSError *error = nil;
        data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    }
    
    return data;
}

@end
