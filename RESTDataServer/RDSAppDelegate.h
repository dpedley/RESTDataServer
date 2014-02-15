//
//  RDSAppDelegate.h
//  RESTDataServer
//
//  Created by Douglas Pedley on 1/30/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RDSEntityTableView;

@interface RDSAppDelegate : NSObject <NSApplicationDelegate, NSTableViewDelegate, NSWindowDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, strong) NSArray *entities;
@property (nonatomic, weak) IBOutlet RDSEntityTableView *entityTable;
@property (nonatomic, weak) IBOutlet NSView *entityTableContainer;

@property (nonatomic, strong, readonly) HTTPServer *server;

@end
