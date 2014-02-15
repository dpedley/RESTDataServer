//
//  RDSEntityTableView.m
//  RESTDataServer
//
//  Created by Douglas Pedley on 2/11/14.
//  Copyright (c) 2014 dpedley.com. All rights reserved.
//

#import "RDSEntityTableView.h"
#import "RDSNumberTransformer.h"

@interface RDSEntityTableView ()

@property (nonatomic, weak) IBOutlet NSButton *addButton;
@property (nonatomic, weak) IBOutlet NSButton *duplicateButton;
@property (nonatomic, weak) IBOutlet NSButton *deleteButton;

@end

@implementation RDSEntityTableView

-(void)registerForCoreDataChanges
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RDSCoreDataStack entityNamed:^NSString *{ return self.entityController.entityName; }
                          dataChanged:^(NSNotification *aNotification) {
                              [self.entityController.managedObjectContext mergeChangesFromContextDidSaveNotification:aNotification];
                              [self.entityController fetch:self.entityController.entityName];
                              [self reloadData];
                              [self setNeedsDisplay];
                          }];
    });
}

-(void)awakeFromNib
{
    self.delegate = self;
    self.dataSource = self;
    self.deleteButton.hidden = YES;
    [self.deleteButton setEnabled:NO];
    self.addButton.hidden = YES;
    [self registerForCoreDataChanges];
}

-(void)tableSelectEntity:(NSString *)entityName
{
    NSArray *currentColumns = [[self tableColumns] copy];
    for (NSTableColumn *column in currentColumns)
    {
        [self removeTableColumn:column];
    }
    
    if (!entityName)
    {
        self.deleteButton.hidden = YES;
        [self.deleteButton setEnabled:NO];
        self.addButton.hidden = YES;
        self.entityController.entityName = nil;
        self.entityController.managedObjectContext = nil;
        return;
    }
    
    // Enable UI
    
    self.deleteButton.hidden = NO;
    self.addButton.hidden = NO;
    
    // Load table
    
    RDSCoreDataStack *stack = [RDSCoreDataStack saveEntityName:entityName];
    NSManagedObjectContext *context = stack.managedObjectContext;
    
    if (context)
    {
        self.entityController.managedObjectContext = context;
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
        
        if (entityDescription)
        {
            NSMutableArray *sortDescriptors = [NSMutableArray array];
            for (NSPropertyDescription *propertyDescription in entityDescription)
            {
                if ([propertyDescription isKindOfClass:[NSAttributeDescription class]])
                {
                    NSMutableDictionary *options = [NSMutableDictionary dictionaryWithDictionary:
                                                    @{
                                                      NSCreatesSortDescriptorBindingOption: [NSNumber numberWithBool:YES],
                                                      NSNullPlaceholderBindingOption: propertyDescription.name
                                                      }];
                    switch (((NSAttributeDescription *)propertyDescription).attributeType)
                    {
                        case NSInteger16AttributeType:
                        case NSInteger32AttributeType:
                        case NSInteger64AttributeType:
                        case NSDecimalAttributeType:
                        case NSDoubleAttributeType:
                        case NSFloatAttributeType:
                        case NSBooleanAttributeType:
                        {
                            RDSNumberTransformer *numberTransformer = [[RDSNumberTransformer alloc] init];
                            [options addEntriesFromDictionary: @{
                                        NSValueTransformerNameBindingOption: @"RDSNumberTransformer",
                                        NSValueTransformerBindingOption: numberTransformer
                                        }];
                        }
                            break;
                            
                        case NSStringAttributeType:
                            break;
                            
                        case NSDateAttributeType:
                            break;
                            
                        case NSBinaryDataAttributeType:
                            break;
                            
                        default:
                            break;
                    }
                    NSTableColumn *tableColumn = [[NSTableColumn alloc] initWithIdentifier:propertyDescription.name];
                    tableColumn.headerCell = [[NSTableHeaderCell alloc] initTextCell:propertyDescription.name];
                    [tableColumn bind:NSValueBinding
                             toObject:self.entityController
                          withKeyPath:[@"arrangedObjects." stringByAppendingString:propertyDescription.name]
                              options:options];
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:tableColumn.identifier ascending:YES selector:@selector(compare:)];
                    [tableColumn setSortDescriptorPrototype:sortDescriptor];
                    [sortDescriptors addObject:sortDescriptor];
                    [self addTableColumn:tableColumn];
                }
            }
            
            [self.entityController setAutomaticallyPreparesContent:YES];
            [self.entityController setAutomaticallyRearrangesObjects:YES];
            [self.entityController setEditable:YES];
            [self.entityController setEntityName:entityName];
            [self.entityController prepareContent];
            [self.entityController fetch:entityName];
        }
    }
    self.stack = stack;
    
    [self reloadData];
}

-(void)textDidEndEditing:(NSNotification *)notification
{
    [super textDidEndEditing:notification];
    if ([self.entityController.managedObjectContext hasChanges])
    {
        NSError *error = nil;
        [self.entityController.managedObjectContext save:&error];
    }
}

- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    [self.entityController setSortDescriptors:self.sortDescriptors];
    [self.entityController rearrangeObjects];
    [aTableView reloadData];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    if (self.selectedRow>=0)
    {
        [self.deleteButton setEnabled:YES];
    }
    else
    {
        [self.deleteButton setEnabled:NO];
    }
}

#pragma mark - Actions

-(IBAction)duplicateRow:(id)sender
{
    if (self.selectedRow<0)
        return;
    
    NSManagedObject *selectedObject = [self.entityController.arrangedObjects objectAtIndex:self.selectedRow];
    NSManagedObjectContext *context = self.stack.managedObjectContext;
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:self.entityController.entityName inManagedObjectContext:context];
    NSManagedObject *newObject = [[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:context];
    if (newObject)
    {
        NSArray *keys = [[[selectedObject entity] attributesByName] allKeys];
        NSDictionary *dict = [selectedObject dictionaryWithValuesForKeys:keys];
        [newObject setValuesForKeysWithDictionary:dict];
        [self.stack saveAndNotifyBlocks];
    }
}

-(IBAction)addRow:(id)sender
{
    NSManagedObjectContext *context = self.stack.managedObjectContext;
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:self.entityController.entityName inManagedObjectContext:context];
    NSManagedObject *newObject = [[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:context];
    if (newObject)
    {
        [self.stack saveAndNotifyBlocks];
    }
}

-(IBAction)deleteRow:(id)sender
{
    if (self.selectedRow<0)
        return;
    
    NSManagedObject *selectedObject = [self.entityController.arrangedObjects objectAtIndex:self.selectedRow];
    NSManagedObjectContext *context = self.stack.managedObjectContext;
    [context deleteObject:selectedObject];
    [self.stack saveAndNotifyBlocks];
}

@end
