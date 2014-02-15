//
//  RDSGetEntity.m
//  RESTDataServer
//
//  Created by Douglas Pedley on 1/31/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import "RDSFetchRequest.h"
#import "RDSEntityDescription.h"

@implementation RDSFetchRequest

-(id)initWithRequest:(HTTPMessage *)request connection:(HTTPConnection *)connection method:(NSString *)method URI:(NSString *)path
{
    self = [super initWithRequest:request connection:connection method:method URI:path];
    
    if (self)
    {
        if ([self.requestParameters count]==1)
        {
            self.entityID = [self.requestParameters objectAtIndex:0];
        }
    }
    return self;
    
}

+ (instancetype)request:(HTTPMessage *)request connection:(HTTPConnection *)connection URI:(NSString *)path
{
    RDSFetchRequest *req = [[self alloc] initWithRequest:request connection:connection method:@"GET" URI:path];

    NSLog(@"Get request: %@ %@", req.entityName, req.requestParameters?req.requestParameters:@"");
    
    return req;
}

- (NSData *)dataResponse
{
    NSString *entityName = nil;
    NSString *entityID = nil;
    NSString *entityIDAttribute = nil;

    if (self.schemaView)
    {
        entityName = @"RDSEntityDescription";
        entityID = self.entityName;
        entityIDAttribute = @"name";
    }
    else
    {
        entityName = self.entityName;
        entityID = self.entityID;
        RDSEntityDescription *entitySettings = [RDSCoreDataStack schemaForEntityNamed:entityName];
        if (!entitySettings)
        {
            DDLogInfo(@"no data for %@", entityName);
            return nil;
        }
        entityIDAttribute = entitySettings.idAttribute;
        
        
    }
    
    // Core data interaction
    NSManagedObjectContext *context = self.coreData.managedObjectContext;
    
    if (!context)
    {
        DDLogInfo(@"No context for: %@", self.entityName);
        return nil;
    }
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    // Description
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
    
    if (!entityDescription)
        return nil;
    
    [request setEntity:entityDescription];

    BOOL returnArray = YES;
    if (entityID && ![entityID isEqualToString:@""])
    {
        returnArray = NO;
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
    }
    else
    {
        // Return an array of them?
        [request setFetchLimit:20];
    }
    
    __block NSArray *results = nil;
    __block NSError *error = nil;
    [context performBlockAndWait:^{
        results = [context executeFetchRequest:request error:&error];
    }];
    
    if ([results count] > 0)
    {
        NSMutableArray *responseArray = [NSMutableArray array];
        for (NSManagedObject *resObject in results)
        {
            NSDictionary *dict = [self dictionaryFromManagedObject:resObject];
            [responseArray addObject:dict];
        }
        
        NSError *error = nil;
        NSData *data = nil;
        if (returnArray)
        {
            data = [NSJSONSerialization dataWithJSONObject:responseArray options:0 error:&error];
        }
        else
        {
            data = [NSJSONSerialization dataWithJSONObject:[responseArray objectAtIndex:0] options:0 error:&error];
        }
        
        return data;
    }
    
    return nil;
}

@end
