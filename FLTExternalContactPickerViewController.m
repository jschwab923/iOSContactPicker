//
//  FLTExternalContactPickerViewController.m
//  Felt Photos
//
//  Created by Jeff Schwab on 11/30/18.
//  Copyright © 2018 Felt. All rights reserved.
//

@import Contacts;

#import "FLTExternalContactPickerViewController.h"
#import "FLTExternalContactTableViewCell.h"

#import "FLTContact+CoreDataClass.h"

@interface FLTExternalContactPickerViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchResultsUpdating>

@property (weak, nonatomic) IBOutlet UITableView *contactTableView;
@property (strong, nonatomic) UISearchController *searchController;

@property (strong, nonatomic) NSMutableOrderedSet<NSMutableDictionary *> *sortedContacts;
@property (strong, nonatomic) NSMutableOrderedSet<NSMutableDictionary *> *allContacts;

@property (strong, nonatomic) NSMutableSet<CNContact *> *selectedContacts;

@property (weak, nonatomic) IBOutlet UIButton *selectAllButton;

@end

@implementation FLTExternalContactPickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [FLTContact iosDeviceContacts].then(^ (NSArray<CNContact *> *contacts) {
        if (contacts.count) {
            
            [self sortContacts:contacts];
            
            self.selectedContacts = [NSMutableSet new];
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self.contactTableView reloadData];
            });
        }
    });
    self.contactTableView.tableHeaderView = self.searchController.searchBar;
}

- (void)sortContacts:(NSArray *)contacts
{
    self.sortedContacts = [NSMutableOrderedSet new];
    for (CNContact *contact in contacts) {
        NSString *sortName = contact.givenName ?: contact.nickname ?: contact.familyName;
        if (sortName.length) {
            NSString *currentLetter = [[sortName substringToIndex:sortName.length - (sortName.length - 1)] uppercaseString];
            NSMutableDictionary *contactsForLetter = [self.sortedContacts filteredOrderedSetUsingPredicate:[NSPredicate predicateWithFormat:@"title LIKE %@", currentLetter]].firstObject;
            if (!contactsForLetter) {
                contactsForLetter = [NSMutableDictionary new];
                contactsForLetter[@"title"] = currentLetter;
                contactsForLetter[@"contacts"] = [NSMutableArray new];
                
                [self.sortedContacts addObject:contactsForLetter];
            }
            [contactsForLetter[@"contacts"] addObject:contact];
        }
    }
    [self.sortedContacts sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
    
    if (!self.allContacts) {
        self.allContacts = self.sortedContacts;
    }
}

- (IBAction)tappedContinue:(id)sender
{
    [self dismissSearchController];
    [self dismissViewControllerAnimated:YES completion:^{
        if ([self.pickerDelegate respondsToSelector:@selector(didSelectExternalContacts:)]) {
            [self.pickerDelegate didSelectExternalContacts:self.selectedContacts];
        }
    }];
}

- (IBAction)tappedCancel:(id)sender
{
    [self dismissSearchController];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)tappedSelectAll:(UIButton *)selectAllButton
{
    NSString *currentTitle = [selectAllButton titleForState:UIControlStateNormal];
    if ([currentTitle containsString:@"Unselect"]) {
        [self.selectedContacts removeAllObjects];
        [selectAllButton setTitle:@"Select All" forState:UIControlStateNormal];
    } else {
        for (NSArray *contacts in [self.allContacts valueForKey:@"contacts"]) {
            [self.selectedContacts addObjectsFromArray:contacts];
        }
        [selectAllButton setTitle:@"Unselect All" forState:UIControlStateNormal];
    }
    [self.contactTableView reloadData];
}

- (UISearchController *)searchController
{
    // Ensure search controller does not already exist
    if (nil != _searchController) {
        return _searchController;
    }
    
    // Create Search Controller
    _searchController =
    [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.dimsBackgroundDuringPresentation = NO;
    _searchController.searchResultsUpdater = self;
    [_searchController.searchBar sizeToFit];
    _searchController.searchBar.returnKeyType = UIReturnKeyDone;
    
    return _searchController;
}

- (void)dismissSearchController
{
    if (self.searchController.active) {
        self.searchController.active = NO;
    }
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString* trimmedSearchText =
    [self.searchController.searchBar.text stringByTrimmingCharactersInSet:
     [NSCharacterSet whitespaceCharacterSet]];
    
    // Determine if the search results should be shown
    BOOL showSearchResults = self.searchController.active &&
    [trimmedSearchText length] > 0;
    
    if (showSearchResults) {
        NSMutableArray *filteredContacts = [NSMutableArray new];
        for (NSDictionary *contactInfo in self.allContacts) {
            NSArray *contacts = contactInfo[@"contacts"];
            for (CNContact *contact in contacts) {
                NSString *name = [NSString stringWithFormat:@"%@%@%@", contact.givenName ?: @"", contact.nickname ?: @"", contact.familyName ?: @""];
                if ([name containsString:trimmedSearchText]) {
                    [filteredContacts addObject:contact];
                }
            }
        }
        [self sortContacts:filteredContacts];
    } else {
        self.sortedContacts = self.allContacts;
    }
    
    [self.contactTableView reloadData];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 75;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sortedContacts.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.sortedContacts[section][@"contacts"] count];
}

- (FLTExternalContactTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"ExternalContactCell";
    FLTExternalContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    CNContact *contact = [self contactForIndexPath:indexPath];
    [cell setContact:contact];
    
    [cell setButtonSelected:[self.selectedContacts containsObject:contact]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLTExternalContactTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell setSelected:NO]; // Set selected to no so we handle all selection in this method.
    
    CNContact *contact = [self contactForIndexPath:indexPath];
    if ([self.selectedContacts containsObject:contact]) {
        [self.selectedContacts removeObject:contact];
    } else {
        [self.selectedContacts addObject:contact];
    }
    [cell setButtonSelected:[self.selectedContacts containsObject:contact]];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.sortedContacts[section][@"title"];
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [self.sortedContacts valueForKey:@"title"];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return index;
}

- (CNContact *)contactForIndexPath:(NSIndexPath *)indexPath
{
    return self.sortedContacts[indexPath.section][@"contacts"][indexPath.row];
}

@end
