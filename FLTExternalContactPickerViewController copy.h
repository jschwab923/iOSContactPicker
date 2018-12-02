//
//  FLTExternalContactPickerViewController.h
//  Felt Photos
//
//  Created by Jeff Schwab on 11/30/18.
//  Copyright © 2018 Felt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FLTExternalContactPickerDelegate <NSObject>

- (void)didSelectExternalContacts:(NSSet<CNContact *> *)externalContacts;

@end

@interface FLTExternalContactPickerViewController : UIViewController

@property (unsafe_unretained, nonatomic) id<FLTExternalContactPickerDelegate> pickerDelegate;

@end
