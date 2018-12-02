//
//  FLTExternalContactTableViewCell.h
//  Felt Photos
//
//  Created by Jeff Schwab on 11/30/18.
//  Copyright © 2018 Felt. All rights reserved.
//

@import Contacts;
#import <UIKit/UIKit.h>

@interface FLTExternalContactTableViewCell : UITableViewCell

- (void)setContact:(CNContact *)contact;
- (void)setButtonSelected:(BOOL)selected;

@end
