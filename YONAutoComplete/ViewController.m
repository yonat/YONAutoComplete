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

    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(10, 20, 300, 24)];
    [self.view addSubview:textField];
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    textField.text = @"Lorem ipsum dolor sit amet, tempor.";
    textField.backgroundColor = [UIColor greenColor];

    self.autoComplete = [YONAutoComplete new];
    textField.delegate = self.autoComplete;

    [textField becomeFirstResponder];
}

@end
