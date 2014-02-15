//
//  RDSMasterViewController.h
//  RDS Example Client
//
//  Created by Douglas Pedley on 1/31/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RDSDetailViewController;

@interface RDSMasterViewController : UITableViewController

@property (strong, nonatomic) RDSDetailViewController *detailViewController;

@end
