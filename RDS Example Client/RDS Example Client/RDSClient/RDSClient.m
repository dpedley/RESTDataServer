//
//  RDSClient.m
//  RDS Example Client
//
//  Created by Douglas Pedley on 2/1/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import "RDSClient.h"

typedef void(^RDSClientJSONObjectCompletion)(BOOL postSuccess, id jsonObject);

typedef void(^RDSURLRequestOperationCompletion)();

@interface RDSURLRequest : NSObject

@property (nonatomic, copy) RDSURLRequestOperationCompletion completion;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) NSObject <NSCopying, NSFastEnumeration>*responseObject;
@property (nonatomic, strong) NSDictionary *errorDictionary;
@property (nonatomic, strong) NSMutableURLRequest *request;

+(instancetype)postData:(NSData *)jsonData toURL:(NSURL *)theURL completion:(RDSClientJSONObjectCompletion)completion;
+(instancetype)getURL:(NSURL *)theURL completion:(RDSClientJSONObjectCompletion)completion;

@end

@implementation RDSURLRequest

+(instancetype)postData:(NSData *)jsonData toURL:(NSURL *)theURL completion:(RDSClientJSONObjectCompletion)completion
{
    __block RDSURLRequest *urlRequest = [[self alloc] init];
    
    RDSURLRequestOperationCompletion done = ^() {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion((urlRequest.responseObject!=nil), urlRequest.responseObject);
        });
    };
    
    urlRequest.completion = done;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:theURL];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:jsonData];
    
    urlRequest.request = request;
    [NSURLConnection connectionWithRequest:request delegate:urlRequest];
    
    return urlRequest;
}

+(instancetype)putData:(NSData *)jsonData toURL:(NSURL *)theURL completion:(RDSClientJSONObjectCompletion)completion
{
    __block RDSURLRequest *urlRequest = [[self alloc] init];
    
    RDSURLRequestOperationCompletion done = ^() {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion((urlRequest.responseObject!=nil), urlRequest.responseObject);
        });
    };
    
    urlRequest.completion = done;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:theURL];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:jsonData];
    
    urlRequest.request = request;
    [NSURLConnection connectionWithRequest:request delegate:urlRequest];
    
    return urlRequest;
}

+(instancetype)getURL:(NSURL *)theURL completion:(RDSClientJSONObjectCompletion)completion
{
    __block RDSURLRequest *urlRequest = [[self alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *fetchedData = [NSData dataWithContentsOfURL:theURL];
        if (fetchedData)
        {
            NSLog(@"fetched json: %@", [[NSString alloc] initWithData:fetchedData encoding:NSASCIIStringEncoding]);
            NSError *error = nil;
            [urlRequest processResponseObject:[NSJSONSerialization JSONObjectWithData:fetchedData options:0 error:&error]];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion((urlRequest.responseObject!=nil), urlRequest.responseObject);
        });
    });
    return urlRequest;
}

-(void)processResponseObject:(id)responseObject
{
    if ([responseObject isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *responseDictionary = responseObject;
        NSDictionary *errorDict = [responseObject objectForKey:@"error"];
        if (!errorDict || ![errorDict isKindOfClass:[NSDictionary class]])
        {
            self.responseObject = responseObject;
        }
        else // Just in case the data response has the same format, look for an error code also.
        {
            if (![errorDict objectForKey:@"code"])
            {
                self.responseObject = responseObject;
            }
            else
            {
                self.errorDictionary = responseDictionary;
            }
        }
    }
    else if ([responseObject isKindOfClass:[NSArray class]])
    {
        self.responseObject = responseObject;
    }
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"got something: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    if (!self.responseData)
    {
        self.responseData = [NSMutableData data];
    }
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSError *error = nil;
    [self processResponseObject:[NSJSONSerialization JSONObjectWithData:self.responseData options:0 error:&error]];
    if (self.completion)
        self.completion();
}

@end

@interface RDSClient ()

- (NSString *)attributeValueClassNameFromType:(NSAttributeType)attributeType;
- (NSAttributeType)attributeTypeFromString:(NSString *)attributeTypeString;

@end

@implementation RDSClient

static NSMutableDictionary *clientsByURL = nil;
+(instancetype)clientToServer:(NSURL *)baseURL
{
    // These are potentially locally cached by baseURL
    if (!clientsByURL)
    {
        clientsByURL = [[NSMutableDictionary alloc] init];
    }
    
    NSString *urlKey = [baseURL absoluteString];
    RDSClient *theClient = [clientsByURL objectForKey:urlKey];
    
    if (!theClient)
    {
        theClient = [[RDSClient alloc] init];
        theClient.baseURL = [baseURL copy];
        [clientsByURL setObject:theClient forKey:urlKey];
    }
    
    return theClient;
}

#pragma mark - Register Class

-(void)registerClass:(Class)aManagedObjectClass usingDescription:(NSEntityDescription *)entityDescription completion:(RDSClientRegisterCompletion)completion
{
    __block NSString *aManagedObjectClassName = [aManagedObjectClass description];
    NSString *aManagedObjectSchemaName = [NSString stringWithFormat:@"{%@}", aManagedObjectClassName];
    
    // First fetch the baseURL/{aManagedObjectClass} schema to see if it exists
    NSURL *newURL = [self.baseURL URLByAppendingPathComponent:aManagedObjectSchemaName];
    
    __block RDSURLRequest *postRequest = nil;
    
    [RDSURLRequest getURL:newURL completion:^(BOOL success, id jsonObject) {
        if ([jsonObject isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *responseDict = jsonObject;
            if ([responseDict[@"name"] isEqualToString:aManagedObjectClassName])
            {
                // Success
                completion(YES, responseDict);
                return;
            }
        }

        // If we get here, we must need to register this class.
        NSDictionary *schemaDictionary = [self schemaDictionaryFromDescription:entityDescription];
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:schemaDictionary options:0 error:&error];
        postRequest = [RDSURLRequest postData:jsonData toURL:newURL completion:^(BOOL postSuccess, id jsonPostObject) {
            if (postSuccess && [jsonPostObject isKindOfClass:[NSDictionary class]]) {
                NSDictionary *postResponseDictionary = jsonPostObject;
                completion(YES, postResponseDictionary);
                return;
            }
            
            completion(NO, nil);
        }];
    }];
}

#pragma mark - Fetch Methods

-(void)allObjectsOfClass:(Class)aManagedObjectClass completion:(RDSClientFetchArrayCompletion)completion
{
    NSString *aManagedObjectClassName = [aManagedObjectClass description];
    if (![aManagedObjectClass isSubclassOfClass:[NSManagedObject class]])
    {
        NSLog(@"class needs to be subclass of NSManagedObject: %@", aManagedObjectClassName);
        completion(nil);
        return;
    }

    NSURL *newURL = [self.baseURL URLByAppendingPathComponent:aManagedObjectClassName];
    [RDSURLRequest getURL:newURL completion:^(BOOL success, id jsonObject) {
        NSArray *responseArray = nil;
        
        NSManagedObjectContext *saveContext = [NSManagedObjectContext MR_rootSavingContext];
        
        if ([jsonObject isKindOfClass:[NSArray class]])
        {
            responseArray = [self managedObjects:aManagedObjectClass mappedFromArrayOfDictionaries:jsonObject usingContext:saveContext];
        }
        else if ([jsonObject isKindOfClass:[NSDictionary class]])
        {
            NSManagedObject *managedObject = [self managedObject:aManagedObjectClass mappedFrom:jsonObject usingContext:saveContext];
            responseArray = [NSArray arrayWithObject:managedObject];
        }
        completion([NSArray arrayWithArray:responseArray]);
    }];
}

-(void)objectOfClass:(Class)aManagedObjectClass withAttribute:(NSString *)attributeName matchingValue:(NSString *)value completion:(RDSClientFetchCompletion)completion
{
    [self objectOfClassByName:[aManagedObjectClass description] withAttribute:attributeName matchingValue:value completion:completion];
}

-(void)objectOfClassByName:(NSString *)aManagedObjectClassName withAttribute:(NSString *)attributeName matchingValue:(NSString *)value completion:(RDSClientFetchCompletion)completion
{
    NSURL *newURL = [[self.baseURL URLByAppendingPathComponent:aManagedObjectClassName]
                                    URLByAppendingPathComponent:[NSString stringWithFormat:@"%@=%@", attributeName, value]];
    [RDSURLRequest getURL:newURL completion:^(BOOL success, id jsonObject) {
        NSManagedObject *responseObject = nil;
        if ([jsonObject isKindOfClass:[NSArray class]])
        {
            responseObject = [(NSArray *)jsonObject objectAtIndex:0];
        }
        else if ([jsonObject isKindOfClass:[NSManagedObject class]])
        {
            responseObject = jsonObject;
        }
        completion(responseObject);
    }];
}

-(void)objectOfClass:(Class)aManagedObjectClass withID:(NSString *)idValue completion:(RDSClientFetchCompletion)completion
{
    [self objectOfClassByName:[aManagedObjectClass description] withID:idValue completion:completion];
}

-(void)objectOfClassByName:(NSString *)aManagedObjectClassName withID:(NSString *)idValue completion:(RDSClientFetchCompletion)completion
{
    NSURL *newURL = [[self.baseURL URLByAppendingPathComponent:aManagedObjectClassName]
                                    URLByAppendingPathComponent:idValue];
    [RDSURLRequest getURL:newURL completion:^(BOOL success, id jsonObject) {
        NSManagedObject *responseObject = nil;
        if ([jsonObject isKindOfClass:[NSArray class]])
        {
            responseObject = [(NSArray *)jsonObject objectAtIndex:0];
        }
        else if ([jsonObject isKindOfClass:[NSManagedObject class]])
        {
            responseObject = jsonObject;
        }
        completion(responseObject);
    }];
}

#pragma mark - Create Update Methods

-(void)createObject:(NSManagedObject *)managedObject completion:(RDSClientCreateCompletion)completion
{
    NSURL *newURL = [self.baseURL URLByAppendingPathComponent:[[managedObject class] description]];
    NSDictionary *objectDict = [self dictionaryFromObject:managedObject];
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:objectDict options:0 error:&error];
    [RDSURLRequest postData:jsonData toURL:newURL completion:^(BOOL postSuccess, id jsonObject) {
        if (postSuccess)
        {
            NSLog(@"create response: %@", jsonObject);
        }
        completion(postSuccess, jsonObject);
    }];
}

-(void)updateObject:(NSManagedObject *)managedObject completion:(RDSClientUpdateCompletion)completion
{
    NSURL *newURL = [self.baseURL URLByAppendingPathComponent:[[managedObject class] description]];
    NSDictionary *objectDict = [self dictionaryFromObject:managedObject];
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:objectDict options:0 error:&error];
    [RDSURLRequest putData:jsonData toURL:newURL completion:^(BOOL putSuccess, id jsonObject) {
        if (putSuccess)
        {
            NSLog(@"create response: %@", jsonObject);
        }
        completion(putSuccess, jsonObject);
    }];
}

#pragma mark - Utilities

- (NSString *)attributeValueClassNameFromType:(NSAttributeType)attributeType
{
    switch (attributeType)
    {
        case NSInteger16AttributeType:
        case NSInteger32AttributeType:
        case NSInteger64AttributeType:
        case NSDecimalAttributeType:
        case NSDoubleAttributeType:
        case NSFloatAttributeType:
        case NSBooleanAttributeType:
            return @"NSNumber";
            break;
            
        case NSStringAttributeType:
            return @"NSString";
            break;
            
        case NSDateAttributeType:
            return @"NSDate";
            break;
            
        case NSBinaryDataAttributeType:
            return @"NSData";
            break;
            
        default:
            break;
    }
    return @"NSUnknown";
}

- (NSAttributeType)attributeTypeFromString:(NSString *)attributeTypeString
{
    if ([attributeTypeString isEqualToString:@"NSInteger16"])
    {
        return NSInteger16AttributeType;
    }
    else if ([attributeTypeString isEqualToString:@"NSInteger32"])
    {
        return NSInteger32AttributeType;
    }
    else if ([attributeTypeString isEqualToString:@"NSInteger64"])
    {
        return NSInteger64AttributeType;
    }
    else if ([attributeTypeString isEqualToString:@"NSDecimal"])
    {
        return NSDecimalAttributeType;
    }
    else if ([attributeTypeString isEqualToString:@"NSDouble"])
    {
        return NSDoubleAttributeType;
    }
    else if ([attributeTypeString isEqualToString:@"NSFloat"])
    {
        return NSFloatAttributeType;
    }
    else if ([attributeTypeString isEqualToString:@"NSString"])
    {
        return NSStringAttributeType;
    }
    else if ([attributeTypeString isEqualToString:@"NSBoolean"])
    {
        return NSBooleanAttributeType;
    }
    else if ([attributeTypeString isEqualToString:@"NSDate"])
    {
        return NSDateAttributeType;
    }
    else if ([attributeTypeString isEqualToString:@"NSBinaryData"])
    {
        return NSBinaryDataAttributeType;
    }
    
    return NSUndefinedAttributeType;
}

- (NSString *)typeStringFromAttribute:(NSAttributeDescription *)attributeDescription
{
    switch (attributeDescription.attributeType)
    {
        case NSInteger16AttributeType:
            return @"NSInteger16";
            break;
            
        case NSInteger32AttributeType:
            return @"NSInteger32";
            break;
            
        case NSInteger64AttributeType:
            return @"NSInteger64";
            break;
            
        case NSDecimalAttributeType:
            return @"NSDecimal";
            break;
            
        case NSDoubleAttributeType:
            return @"NSDouble";
            break;
            
        case NSFloatAttributeType:
            return @"NSFloat";
            break;
            
        case NSStringAttributeType:
            return @"NSString";
            break;
            
        case NSBooleanAttributeType:
            return @"NSBoolean";
            break;
            
        case NSDateAttributeType:
            return @"NSDate";
            break;
            
        case NSBinaryDataAttributeType:
            return @"NSBinaryData";
            break;
            
        default:
            break;
    }
    return @"Unknown";
}

#pragma mark - Managed Object Mapping

-(NSDictionary *)dictionaryFromObject:(NSManagedObject *)managedObject
{
    NSArray *keys = [[[managedObject entity] attributesByName] allKeys];
    return [managedObject dictionaryWithValuesForKeys:keys];
}

-(NSDictionary *)schemaDictionaryFromDescription:(NSEntityDescription *)schemaDescription
{
    NSMutableArray *schemaArray = [NSMutableArray array];
    if (schemaDescription)
    {
        for (NSPropertyDescription *propertyDescription in schemaDescription)
        {
            if ([propertyDescription isKindOfClass:[NSAttributeDescription class]])
            {
                NSAttributeDescription *attributeDescription = (NSAttributeDescription *)propertyDescription;
                [schemaArray addObject:@{
                                         //                                                 @"className": attributeDescription.attributeValueClassName,
                                         @"name": attributeDescription.name,
                                         @"type": [self typeStringFromAttribute:attributeDescription]
                                         }];
            }
            
        }
    }
    
    return @{
             @"name": schemaDescription.name,
             //             @"idAttribute": @"",
             @"schema": schemaArray
             };
    
}

-(NSManagedObject *)managedObject:(Class)aManagedObjectClass mappedFrom:(NSDictionary *)dictionary usingContext:(NSManagedObjectContext *)context
{
    if (![aManagedObjectClass isSubclassOfClass:[NSManagedObject class]])
    {
        return nil;
    }
    
    NSManagedObject *anObject = nil;
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:[aManagedObjectClass description] inManagedObjectContext:context];
    // Check to see if the class has a idAttribute
    if ([aManagedObjectClass respondsToSelector:@selector(idAttribute)])
    {
        NSString *idAttribute = [(Class <RDSClientIDAttributeProtocol>)aManagedObjectClass idAttribute];
        NSValue *value = [dictionary valueForKey:idAttribute];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDescription];
        [request setPredicate:[NSPredicate predicateWithFormat:@"%K = %@", idAttribute, value]];
        [request setFetchLimit:1];
        __block NSArray *results = nil;
        [context performBlockAndWait:^{
            
            NSError *error = nil;
            
            results = [context executeFetchRequest:request error:&error];
        }];
        
        if (results && [results count]>0)
        {
            NSLog(@"Updating object: %@", dictionary);
            anObject = [results objectAtIndex:0];
        }
    }
    
    if (!anObject)
    {
        NSLog(@"Adding object: %@", dictionary);
        anObject = (NSManagedObject *)[[aManagedObjectClass alloc] initWithEntity:entityDescription
                                                   insertIntoManagedObjectContext:context];
    }
    NSArray *allKeys = [dictionary allKeys];
    for (NSString *key in allKeys)
    {
        @try {
            [anObject setValue:[dictionary objectForKey:key] forKey:key];
        }
        @catch (NSException *exception) {
            NSLog(@"Field mapping error key/entity: %@/%@", key, [anObject class]);
        }
        @finally {
        }
    }
    return anObject;
}

-(NSArray *)managedObjects:(Class)aManagedObjectClass mappedFromArrayOfDictionaries:(NSArray *)arrayOfDictionaries usingContext:(NSManagedObjectContext *)context;
{
    if (![aManagedObjectClass isSubclassOfClass:[NSManagedObject class]])
    {
        return nil;
    }
    
    NSMutableArray *theObjects = [NSMutableArray array];
    
    for (NSDictionary *aDict in arrayOfDictionaries)
    {
        [theObjects addObject:[self managedObject:aManagedObjectClass mappedFrom:aDict usingContext:context]];
    }
    
    return [NSArray arrayWithArray:theObjects];
}

@end
