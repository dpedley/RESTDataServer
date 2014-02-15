//
//  RDSMasterViewController.m
//  RDS Example Client
//
//  Created by Douglas Pedley on 1/31/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import "RDSMasterViewController.h"

#import "RDSDetailViewController.h"

#import "RDSClient.h"
#import "TestEntity.h"
#import "TestEntityCell.h"

@interface RDSMasterViewController ()
{
    NSMutableArray *_objects;
}

@property (nonatomic, strong) RDSClient *rds;
@end

@implementation RDSMasterViewController

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    self.detailViewController = (RDSDetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    _objects = [NSMutableArray array];
    
//    NSArray *testLoad = [TestEntity MR_findAll];
//    if (testLoad && [testLoad count]>0)
//    {
//        NSLog(@"testLoad");
//        [_objects addObjectsFromArray:testLoad];
//    }
//    else
    {
        NSLog(@"rdsLoad");
        RDSClient *rds = [RDSClient clientToServer:[NSURL URLWithString:@"http://127.0.0.1:41771/"]];
        NSManagedObjectContext *context = [NSManagedObjectContext MR_rootSavingContext];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"TestEntity" inManagedObjectContext:context];
        
        [rds registerClass:[TestEntity class]
          usingDescription:entity
                completion:^(BOOL success, NSDictionary *schema) {
                    NSLog(@"Class schema: %@", schema);
                    if (success) {
//                        [self createTestEntities];
                        [self loadTestEntities];
                    }
                }];
        self.rds = rds;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)createTestEntities
{
    NSManagedObjectContext *context = [NSManagedObjectContext MR_rootSavingContext];

    // We'll create a few, but not bother saving them, we're going to load from the server later instead.
    TestEntity *t1 = [TestEntity MR_createInContext:context];
    TestEntity *t2 = [TestEntity MR_createInContext:context];
    TestEntity *t3 = [TestEntity MR_createInContext:context];
    
    t1.testID = @(1); t1.testName = @"test1"; t1.testFloat = @(1.1f);
    t2.testID = @(2); t2.testName = @"test2"; t2.testFloat = @(2.2f);
    t3.testID = @(3); t3.testName = @"test3"; t3.testFloat = @(3.3f);
    
    [self.rds createObject:t1 completion:^(BOOL success, NSDictionary *responseDictionary) {
        if (success) {
            [self.rds createObject:t2 completion:^(BOOL success2, NSDictionary *responseDictionary) {
                if (success2) {
                    [self.rds createObject:t3 completion:^(BOOL success3, NSDictionary *responseDictionary) {
                        if (success3) {
                            NSLog(@"SUCCESS!!");
                        }
                    }];
                }
            }];
        }
    }];
}

-(void)loadTestEntities
{
        [self.rds allObjectsOfClass:[TestEntity class]
                    completion:^(NSArray *arrayOfManagedObjects) {
                        for (TestEntity *te in arrayOfManagedObjects)
                        {
                            NSLog(@"TE: %@ %@ %@", te.testName, te.testFloat, te.testID);
                        }
                        [_objects addObjectsFromArray:arrayOfManagedObjects];
                        [self.tableView reloadData];
                    }];
}

- (void)insertNewObject:(id)sender
{
//    if (!_objects) {
//        _objects = [[NSMutableArray alloc] init];
//    }
//    [_objects insertObject:[NSDate date] atIndex:0];
//    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
//    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TestEntityCell *cell = (TestEntityCell *)[tableView dequeueReusableCellWithIdentifier:@"TestEntityCell" forIndexPath:indexPath];

    [cell configureWithTestEntity:[_objects objectAtIndex:indexPath.row]];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        NSDate *object = _objects[indexPath.row];
        self.detailViewController.detailItem = object;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDate *object = _objects[indexPath.row];
        [[segue destinationViewController] setDetailItem:object];
    }
}

@end
