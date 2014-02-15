//
//  RDSConnection.m
//  RESTDataServer
//
//  Created by Douglas Pedley on 1/30/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import "RDSConnection.h"
#import "HTTPMessage.h"
#import "HTTPDataResponse.h"
#import "DDNumber.h"
#import "RDSRequest.h"
#import "RDSFetchRequest.h"
#import "RDSCreateRequest.h"
#import "RDSDeleteRequest.h"
#import "RDSUpdateRequest.h"
#import "RDSJSONResponse.h"

// Log levels : off, error, warn, info, verbose
// Other flags: trace
static const int httpLogLevel = HTTP_LOG_LEVEL_WARN; // | HTTP_LOG_FLAG_TRACE;

@implementation RDSConnection

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
	HTTPLogTrace();

	// TODO: inspect paths to disallow if they are available.
	if ([method isEqualToString:@"POST"])
	{
        return requestContentLength < 5000;
	}
	if ([method isEqualToString:@"DELETE"])
    {
        return YES;
    }
	if ([method isEqualToString:@"PUT"])
    {
        return YES;
    }
    
	return [super supportsMethod:method atPath:path];
}

- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path
{
	HTTPLogTrace();
	
	// Inform HTTP server that we expect a body to accompany a POST request
	
	if([method isEqualToString:@"POST"])
		return YES;
	
	return [super expectsRequestBodyFromMethod:method atPath:path];
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	HTTPLogTrace();
	
    if ([path isEqualToString:@"/favicon.ico"])
    {
        return [super httpResponseForMethod:method URI:path];
    }

	if ([method isEqualToString:@"GET"])
    {
        RDSFetchRequest *getRequest = [RDSFetchRequest request:request connection:self URI:path];
        
        NSData *data = [getRequest dataResponse];
        
        if (!data)
        {
            return [RDSJSONResponse withJSONString:@"{\"error\":{\"code\":400,\"message\":\"Not Found\"}}"];
        }
		return [RDSJSONResponse withJSONData:data];
    }
	else if ([method isEqualToString:@"POST"])
	{
		HTTPLogVerbose(@"%@[%p]: postContentLength: %qu", THIS_FILE, self, requestContentLength);
		
        RDSCreateRequest *postRequest = [RDSCreateRequest request:request connection:self URI:path];
        
        NSData *data = [postRequest dataResponse];
        
        if (!data)
        {
            return [RDSJSONResponse withJSONString:@"{\"error\":{\"code\":400,\"message\":\"Not Found\"}}"];
        }
		return [RDSJSONResponse withJSONData:data];
	}
	else if ([method isEqualToString:@"PUT"])
    {
        RDSUpdateRequest *updateRequest = [RDSUpdateRequest request:request connection:self URI:path];
        
        NSData *data = [updateRequest dataResponse];
        
        if (!data)
        {
            return [RDSJSONResponse withJSONString:@"{\"error\":{\"code\":400,\"message\":\"Not Found\"}}"];
        }
		return [RDSJSONResponse withJSONData:data];
    }
	else if ([method isEqualToString:@"DELETE"])
    {
        RDSDeleteRequest *deleteRequest = [RDSDeleteRequest request:request connection:self URI:path];
        
        NSData *data = [deleteRequest dataResponse];
        
        if (!data)
        {
            return [RDSJSONResponse withJSONString:@"{\"error\":{\"code\":400,\"message\":\"Not Found\"}}"];
        }
		return [RDSJSONResponse withJSONData:data];
    }
    
	return [super httpResponseForMethod:method URI:path];
}

- (void)prepareForBodyWithSize:(UInt64)contentLength
{
	HTTPLogTrace();
	
	// If we supported large uploads,
	// we might use this method to create/open files, allocate memory, etc.
}

- (void)processBodyData:(NSData *)postDataChunk
{
	HTTPLogTrace();
	
	// Remember: In order to support LARGE POST uploads, the data is read in chunks.
	// This prevents a 50 MB upload from being stored in RAM.
	// The size of the chunks are limited by the POST_CHUNKSIZE definition.
	// Therefore, this method may be called multiple times for the same POST request.
	
	BOOL result = [request appendData:postDataChunk];
	if (!result)
	{
		HTTPLogError(@"%@[%p]: %@ - Couldn't append bytes!", THIS_FILE, self, THIS_METHOD);
	}
}

@end
