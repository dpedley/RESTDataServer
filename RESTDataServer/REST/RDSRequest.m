//
//  RDSRequest.m
//  RESTDataServer
//
//  Created by Douglas Pedley on 1/30/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import "RDSRequest.h"
#import "RDSEntityDescription.h"
#import "RDSCoreDataStack.h"

@interface RDSRequest ()

@property (nonatomic, copy) NSString *path;
@property (nonatomic, assign) RDSRequestMethod method;

@end

@implementation RDSRequest

#pragma mark - Initialization

static NSString *__basePath = nil;
- (id)initWithRequest:(HTTPMessage *)request connection:(HTTPConnection *)connection method:(NSString *)method URI:(NSString *)encodedPath
{
    NSString *path = [encodedPath stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
          
    if (!__basePath)
    {
        AppSettings *appSettings = [RDSCoreDataStack settings];
        __basePath = [[NSString alloc] initWithString:(appSettings.basePath)?appSettings.basePath:@"/"];
    }
    
    NSRange basePathRange = [path rangeOfString:__basePath options:NSAnchoredSearch];
    
    if (basePathRange.location==NSNotFound)
        return nil;
    
    NSString *parsedPath = [path stringByReplacingCharactersInRange:basePathRange withString:@""];
    NSArray *components = [parsedPath componentsSeparatedByString:@"/"];
    
    // There is no such thing as a homepage
    if (components.count==0)
        return nil;
    
    // Okay lets create ourselves
    self = [super init];
    if (self) {
        if ([method isEqualToString:@"GET"])
            self.method = RDSRequestMethod_Fetch;
        else if ([method isEqualToString:@"POST"])
            self.method = RDSRequestMethod_Create;
        else if ([method isEqualToString:@"PUT"])
            self.method = RDSRequestMethod_Update;
        else if ([method isEqualToString:@"DELETE"])
            self.method = RDSRequestMethod_Delete;
        
        NSString *entityName = [components objectAtIndex:0];
        if ([[entityName substringToIndex:1] isEqualToString:@"{"] && [[entityName substringFromIndex:entityName.length-1] isEqualToString:@"}"])
        {
            self.schemaView = YES;
            if (self.method==RDSRequestMethod_Create)
                _coreData = [RDSCoreDataStack saveAppSettings];
            else
                _coreData = [RDSCoreDataStack readOnlyAppSettings];
            entityName = [entityName substringWithRange:NSMakeRange(1, entityName.length-2)];
        }
        else
        {
            if (self.method==RDSRequestMethod_Create)
                _coreData = [RDSCoreDataStack saveEntityName:entityName];
            else
                _coreData = [RDSCoreDataStack readOnlyEntityName:entityName];
        }
        self.entityName = entityName;
        
        if (components.count>1)
            self.requestParameters = [components subarrayWithRange:NSMakeRange(1, components.count - 1)];
        
    }
    return self;

    

    return self;
}

- (NSData *)dataResponse
{
    // No Standard Response
    return nil;
}


+ (instancetype)request:(HTTPMessage *)request connection:(HTTPConnection *)connection method:(NSString *)method URI:(NSString *)path
{
    return [[self alloc] initWithRequest:request connection:connection method:method URI:path];
}

#pragma mark - Utilities

- (NSDateFormatter *)standardDateFormatter
{
    static NSDateFormatter *__standardDateFormatter = nil;
    if (!__standardDateFormatter)
    {
        __standardDateFormatter = [[NSDateFormatter alloc] init];
    }
    
    return __standardDateFormatter;
}

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

-(NSValue *)translateValue:(NSValue *)value forAttribute:(NSAttributeDescription *)attribute
{
    switch (attribute.attributeType)
    {
            // These types don't need translation
        case NSInteger16AttributeType:
        case NSInteger32AttributeType:
        case NSInteger64AttributeType:
        case NSDecimalAttributeType:
        case NSDoubleAttributeType:
        case NSFloatAttributeType:
        case NSBooleanAttributeType:
        case NSStringAttributeType:
            return value;
            break;
            
        case NSDateAttributeType:
        {
            // Convert a string to a date
            if ([value isKindOfClass:[NSString class]])
            {
                NSString *dateString = (NSString *)value;
                return [[self standardDateFormatter] dateFromString:dateString];
            }
        }
            break;
            
        case NSBinaryDataAttributeType:
        {
            NSAssert(YES, @"need to do base64 translation here.");
        }
            break;
            
        default:
            break;
    }
    
    NSLog(@"weird attribute: %@", attribute);
    return nil;
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

-(NSDictionary *)dictionaryFromManagedObject:(NSManagedObject *)managedObject
{
    NSArray *keys = [[[managedObject entity] attributesByName] allKeys];
    NSDictionary *dict = [managedObject dictionaryWithValuesForKeys:keys];
    
    if (self.schemaView)
    {
        NSMutableArray *schemaArray = [NSMutableArray array];
        RDSCoreDataStack *schemaStack = [RDSCoreDataStack readOnlyEntityName:self.entityName];
        NSEntityDescription *schemaDescription = [NSEntityDescription entityForName:self.entityName inManagedObjectContext:schemaStack.managedObjectContext];
        for (NSPropertyDescription *propertyDescription in schemaDescription)
        {
            if ([propertyDescription isKindOfClass:[NSAttributeDescription class]])
            {
                NSAttributeDescription *attributeDescription = (NSAttributeDescription *)propertyDescription;
                [schemaArray addObject:@{
//                                                @"className": attributeDescription.attributeValueClassName,
                                         @"name": attributeDescription.name,
                                         @"type": [self typeStringFromAttribute:attributeDescription]
                                         }];
            }
            
        }
        NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:dict];
        [newDict setObject:schemaArray forKey:@"schema"];
        dict = [NSDictionary dictionaryWithDictionary:newDict];
    }
    return dict;
}

@end

