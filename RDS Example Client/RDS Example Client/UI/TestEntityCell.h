//
//  TestEntityCell.h
//  RDS Example Client
//
//  Created by Douglas Pedley on 2/1/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TestEntity;

@interface TestEntityCell : UITableViewCell

-(void)configureWithTestEntity:(TestEntity *)testEntity;

@end
