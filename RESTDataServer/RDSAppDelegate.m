//
//  RDSAppDelegate.m
//  RESTDataServer
//
//  Created by Douglas Pedley on 1/30/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import "RDSAppDelegate.h"
#import "HTTPServer.h"
#import "RDSEntityTableView.h"

// Log levels: off, error, warn, info, verbose
int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface RDSAppDelegate ()

@property (nonatomic, strong, readwrite) HTTPServer *server;

@end

@implementation RDSAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    // Configure our logging framework.
	// To keep things simple and fast, we're just going to log to the Xcode console.
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
	    
	// Initalize our http server
	HTTPServer *httpServer = [[HTTPServer alloc] init];
	
	// Tell the server to broadcast its presence via Bonjour.
	// This allows browsers such as Safari to automatically discover our service.
	[httpServer setType:@"_http._tcp."];
	
	// Normally there's no need to run our server on any specific port.
	// Technologies like Bonjour allow clients to dynamically discover the server's port at runtime.
	// However, for easy testing you may want force a certain port so you can just hit the refresh button.
	[httpServer setPort:41771];
	
	// We're going to extend the base HTTPConnection class with our RDSConnection class.
	// This allows us to do all kinds of customizations.
	[httpServer setConnectionClass:[RDSConnection class]];
	
	// Serve files from our embedded Web folder
	NSString *webPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Web"];
	DDLogInfo(@"Setting document root: %@", webPath);
	
	[httpServer setDocumentRoot:webPath];
	
	
	NSError *error = nil;
	if(![httpServer start:&error])
	{
		DDLogError(@"Error starting HTTP Server: %@", error);
	}
    
    self.server = httpServer;

    self.entities = [RDSCoreDataStack schemata];
}

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "com.dpedley.RESTDataServer" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"com.dpedley.RESTDataServer"];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    return NSTerminateNow;
}

-(void)awakeFromNib
{
    DDLogInfo(@"Awaker from nib");
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RDSCoreDataStack entityNamed:^NSString *{ return @"RDSEntityDescription"; }
                          dataChanged:^(NSNotification *aNotification) {
                              NSArray *newSchemata = [RDSCoreDataStack schemata];
                              __block BOOL selectedEntityWasDeleted = YES;
                              [newSchemata enumerateObjectsUsingBlock:^(RDSEntityDescription *obj, NSUInteger idx, BOOL *stop) {
                                  if ([obj.name isEqualToString:self.entityTable.entityController.entityName])
                                  {
                                      selectedEntityWasDeleted = NO;
                                      *stop = YES;
                                  }
                              }];
                              if (selectedEntityWasDeleted)
                              {
                                  [self.entityTable tableSelectEntity:nil];
                                  self.entityTableContainer.hidden = YES;
                              }
                              self.entities = newSchemata;
                          }];
    });
    self.entityTableContainer.hidden = YES;
}

-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    if (row<[self.entities count])
    {
        RDSEntityDescription *entity = [self.entities objectAtIndex:row];
        [self.entityTable tableSelectEntity:entity.name];
        self.entityTableContainer.hidden = NO;
        return YES;
    }
    
    return NO;
}

#pragma mark - NSWindowDelegate Methods

#pragma mark Undo Manager

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return self.entityTable.stack.managedObjectContext.undoManager;
}

@end
