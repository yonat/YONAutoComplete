//
//  ViewController.m
//  YONAutoComplete
//
//  Created by Yonat Sharon on 5/6/14.
//  Copyright (c) 2014 Yonat Sharon. All rights reserved.
//

#import "ViewController.h"
#import "YONAutoComplete.h"

@interface ViewController ()
@property (nonatomic, strong) YONAutoComplete *autoComplete;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 320, 24)];
    [self.view addSubview:textField];
    textField.center = self.view.center;
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.text = @"Lorem ipsum dolor sit amet, tempor.";

    self.autoComplete = [YONAutoComplete new];
    textField.delegate = self.autoComplete;

    [textField becomeFirstResponder];
}

@end
