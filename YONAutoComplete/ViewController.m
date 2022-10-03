//
//  ViewController.m
//  YONAutoComplete
//
//  Created by Yonat Sharon on 5/6/14.
//  Copyright (c) 2014 Yonat Sharon. All rights reserved.
//

#import "ViewController.h"
#import "YONAutoComplete.h"

@interface ViewController () <UITextFieldDelegate>
@property (nonatomic, strong) YONAutoComplete *autoComplete;
@property (nonatomic, strong) UITextField *textField;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(10, 50, 300, 24)];
    [self.view addSubview:self.textField];
    self.textField.borderStyle = UITextBorderStyleRoundedRect;
    self.textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//    self.textField.text = @"Lorem ipsum dolor sit amet, tempor.";
    self.textField.clearButtonMode = UITextFieldViewModeWhileEditing;

    self.autoComplete = [YONAutoComplete new];
    self.textField.delegate = self.autoComplete;
    self.autoComplete.completionsFileName = @"other";
    self.autoComplete.maxCompletions = 7;

    self.autoComplete.textFieldDelegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.textField becomeFirstResponder];
}

- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string
{
    NSLog(@"textField replacementString: %@", string);
    return YES;
}

@end
