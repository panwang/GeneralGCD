//
//  PWMainViewController.h
//  GeneralGCD
//
//  Created by WANG on 6/11/15.
//  Copyright (c) 2015 WANG. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PWMainViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *gcdBtu;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextField *textField;

@property (nonatomic, strong)NSString* newName NS_RETURNS_NOT_RETAINED;

@end
