//
//  FLTExternalContactTableViewCell.m
//  Felt Photos
//
//  Created by Jeff Schwab on 11/30/18.
//  Copyright © 2018 Felt. All rights reserved.
//

#import "FLTExternalContactTableViewCell.h"

@interface FLTExternalContactTableViewCell ()

@property (weak, nonatomic) IBOutlet UIButton *selectionButton;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *sublabel;
@property (weak, nonatomic) IBOutlet UILabel *rightLabel;

@end

@implementation FLTExternalContactTableViewCell

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.nameLabel.text = nil;
    self.sublabel.text = nil;
    self.rightLabel.text = nil;
}

- (void)setContact:(CNContact *)contact
{
    NSString *fullName = [NSString stringWithFormat:@"%@ %@", contact.givenName, contact.familyName];
    NSMutableAttributedString *contactName = [[NSMutableAttributedString alloc] initWithString:fullName attributes:@{NSForegroundColorAttributeName:[UIColor grayColor]}];
    [contactName addAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:self.nameLabel.font.pointSize]} range:[fullName rangeOfString:contact.givenName]];
    [contactName addAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:self.nameLabel.font.pointSize]} range:[fullName rangeOfString:contact.familyName]];
    self.nameLabel.attributedText = contactName;
    
    if (contact.postalAddresses.count) {
        CNLabeledValue *homeAddressValue = [contact.postalAddresses filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"label LIKE %@", CNLabelHome]].firstObject;
        if (!homeAddressValue) {
            homeAddressValue = contact.postalAddresses.firstObject;
        }
        CNPostalAddress *homeAddress = homeAddressValue.value;
        CNPostalAddressFormatter *formatter = [[CNPostalAddressFormatter alloc] init];
        self.sublabel.font = [UIFont systemFontOfSize:self.sublabel.font.pointSize];
        self.sublabel.textColor = [UIColor grayColor];
        self.sublabel.text = [[formatter stringFromPostalAddress:homeAddress] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    }
    
    if (contact.birthday) {
        self.rightLabel.font = [UIFont systemFontOfSize:self.rightLabel.font.pointSize];
        self.rightLabel.textColor = [UIColor grayColor];
        NSDate *date = contact.birthday.date;
        self.rightLabel.text = [NSString stringWithFormat:@"Birthday: %@ %li%@", [date shortMonthString], date.day, date.year > 1900 ? [NSString stringWithFormat:@", %li", date.year] : @""];
    }
}

- (void)setButtonSelected:(BOOL)selected
{
    self.selectionButton.selected = selected;
}

@end
