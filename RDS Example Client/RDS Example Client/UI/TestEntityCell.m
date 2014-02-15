//
//  TestEntityCell.m
//  RDS Example Client
//
//  Created by Douglas Pedley on 2/1/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import "TestEntityCell.h"
#import "TestEntity.h"

@interface TestEntityCell ()

@property (nonatomic, weak) IBOutlet UILabel *testLabel0;
@property (nonatomic, weak) IBOutlet UILabel *testLabel1;
@property (nonatomic, weak) IBOutlet UILabel *testLabel2;

@end

@implementation TestEntityCell

-(void)configureWithTestEntity:(TestEntity *)testEntity
{
    NSLog(@"Configure TE: %@ %@ %@", testEntity.testName, testEntity.testFloat, testEntity.testID);
    self.testLabel0.text = [testEntity.testID stringValue];
    self.testLabel1.text = testEntity.testName;
    self.testLabel2.text = [testEntity.testFloat stringValue];
}

@end
