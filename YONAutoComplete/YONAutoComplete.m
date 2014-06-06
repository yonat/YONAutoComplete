//
//  YOUAutoComplete.m
//  YONAutoComplete
//
//  Created by Yonat Sharon on 5/6/14.
//  Copyright (c) 2014 Yonat Sharon. All rights reserved.
//

#import "YONAutoComplete.h"

@interface YONAutoComplete ()

@property (nonatomic, weak) UITextField* textField;
@property (nonatomic, assign) CGRect maxFrame;
@property (nonatomic, strong) UITapGestureRecognizer *tap;

@end

@implementation YONAutoComplete

- (void)adjustMaxFrame:(NSNotification *)note
{
    // find keyboard frame
    NSDictionary *info = note.userInfo;
    NSValue *keyboardFrameValue = info[UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrame = [self convertRect:keyboardFrameValue.CGRectValue fromView:nil];
    CGFloat maxHeight = CGRectGetMinY(keyboardFrame);

    // update maxFrame
    _maxFrame = self.textField.frame;
    _maxFrame.origin.y += _maxFrame.size.height;
    _maxFrame.size.height = maxHeight;

    // update frame
    CGFloat maxWidth = CGRectGetWidth(_maxFrame);
    CGSize newSize = [self sizeThatFits:CGSizeMake(maxWidth, MAXFLOAT)];
    CGRect newFrame = _maxFrame;
    newFrame.size = CGSizeMake(MAX(newSize.width, maxWidth), MIN(newSize.height, maxHeight));
    self.frame = newFrame;
}

- (void)handleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    // find tapped char
    CGPoint tapLocation = [gestureRecognizer locationInView:self];
    UITextPosition *tapPosition = [self closestPositionToPoint:tapLocation];
    NSInteger charOffset = [self offsetFromPosition:self.beginningOfDocument toPosition:tapPosition];

    // find tapped item
    NSString *allItems = self.text;
    NSRange startRange = [allItems rangeOfString:@"\n" options:NSBackwardsSearch|NSLiteralSearch range:NSMakeRange(0, charOffset)];
    if (NSNotFound == startRange.location) startRange = NSMakeRange(0, 0);
    NSRange endRange = [allItems rangeOfString:@"\n" options:NSLiteralSearch range:NSMakeRange(charOffset, allItems.length-charOffset)];
    if (NSNotFound == endRange.location) endRange = NSMakeRange(allItems.length, 0);
    NSUInteger itemLocation = startRange.location + startRange.length;
    NSUInteger itemLength = endRange.location - itemLocation;
    NSString *selectedItem = [allItems substringWithRange:NSMakeRange(itemLocation, itemLength)];
    // TODO: maybe just keep a table of offset->item

    // set the text of the field
    self.textField.text = selectedItem;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    self.textField = textField;
    self.editable = NO;
    self.dataDetectorTypes = UIDataDetectorTypeNone;

    // size same as textField width
    CGRect frame = textField.frame;
    frame.origin.y += frame.size.height;
    frame.size.height = 0;
    self.frame = self.maxFrame = frame;
    [textField.superview addSubview:self];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustMaxFrame:) name:UIKeyboardDidShowNotification object:nil];

    // style same as textField, only smaller and paler
    self.textAlignment = textField.textAlignment;
    self.font = [UIFont fontWithName:textField.font.fontName size:0.9*textField.font.pointSize];
    CGFloat r, g, b, a;
    r = g = b = 0; a = 1;
    [textField.textColor getRed:&r green:&g blue:&b alpha:&a];
    self.textColor = [UIColor colorWithRed:r green:g blue:b alpha:0.75*a];
    r = g = b = a = 1;
    [textField.backgroundColor getRed:&r green:&g blue:&b alpha:&a];
    self.backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:0.75*a];

    // respond to taps
    if (nil == self.tap) {
        self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:self.tap];
    }

    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // TODO: delete
    UITextPosition *start = [textField beginningOfDocument];
    UITextPosition *selStart = [textField positionFromPosition:start offset:2];
    UITextPosition *selEnd = [textField positionFromPosition:start offset:7];
    textField.selectedTextRange = [textField textRangeFromPosition:selStart toPosition:selEnd];

    // TODO: read list of completions (in bg thread?)
    self.text = @"First\nSecond\nThird\nFourth\nThe fifth symphony has very long endings, that just go on and on and on...\nSixth\nSeven is a lucky number\nend!";
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // TODO: add textField.text to completions and give it highest priority
    // TODO: hide view
    // TODO: notify client
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // TODO: set frame below textField and above keyboard
    self.frame = self.maxFrame;

    // TODO: find completion and resize view accordingly

    // TODO: mark each completion bold where textField.text is

    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];

    return YES;
}


@end
