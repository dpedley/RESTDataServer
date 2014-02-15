//
//  RDSRequest.h
//  RESTDataServer
//
//  Created by Douglas Pedley on 1/30/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HTTPConnection;
@class HTTPMessage;

typedef enum
{
    RDSRequestMethod_Fetch = 0,
    RDSRequestMethod_Create,
    RDSRequestMethod_Update,
    RDSRequestMethod_Delete
} RDSRequestMethod;

@class RDSCoreDataStack;

@interface RDSRequest : NSObject

@property (nonatomic, readonly) RDSCoreDataStack *coreData;
@property (nonatomic, copy) NSString *entityName;
@property (nonatomic, strong) NSArray *requestParameters;
@property (nonatomic, assign) BOOL schemaView;

- (id)initWithRequest:(HTTPMessage *)request connection:(HTTPConnection *)connection method:(NSString *)method URI:(NSString *)path;
+ (instancetype)request:(HTTPMessage *)request connection:(HTTPConnection *)connection method:(NSString *)method URI:(NSString *)path;

- (NSData *)dataResponse;
- (NSString *)attributeValueClassNameFromType:(NSAttributeType)attributeType;
- (NSAttributeType)attributeTypeFromString:(NSString *)attributeTypeString;
- (NSString *)typeStringFromAttribute:(NSAttributeDescription *)attributeDescription;
-(NSDictionary *)dictionaryFromManagedObject:(NSManagedObject *)managedObject;

@end
