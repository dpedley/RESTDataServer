//
//  RDSEntityTableView.h
//  RESTDataServer
//
//  Created by Douglas Pedley on 2/11/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RDSEntityTableView : NSTableView <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) IBOutlet NSArrayController *entityController;
@property (nonatomic, strong) RDSCoreDataStack *stack;

-(void)tableSelectEntity:(NSString *)entityName;

@end
