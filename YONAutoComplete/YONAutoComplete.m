//
//  YOUAutoComplete.m
//  YONAutoComplete
//
//  Created by Yonat Sharon on 5/6/14.
//  Copyright (c) 2014 Yonat Sharon. All rights reserved.
//

#import "YONAutoComplete.h"

@interface YONAutoComplete ()

@property (nonatomic, strong) NSMutableArray *completions;
@property (nonatomic, weak) UITextField* textField;
@property (nonatomic, assign) CGRect maxFrame;
@property (nonatomic, strong) UITapGestureRecognizer *tap;

@end

@implementation YONAutoComplete

- (void)updateFrame
{
    CGFloat maxWidth = CGRectGetWidth(_maxFrame);
    CGSize newSize = self.text.length ? [self sizeThatFits:CGSizeMake(maxWidth, MAXFLOAT)] : CGSizeZero;
    CGRect newFrame = _maxFrame;
    newFrame.size = CGSizeMake(MAX(newSize.width, maxWidth), MIN(newSize.height, CGRectGetHeight(_maxFrame)));
    self.frame = newFrame;
}

- (void)adjustMaxFrame:(NSNotification *)note
{
    CGFloat maxHeight = 0;
    if (nil != note) {
        // find keyboard frame
        NSDictionary *info = note.userInfo;
        NSValue *keyboardFrameValue = info[UIKeyboardFrameEndUserInfoKey];
        CGRect keyboardFrame = [self convertRect:keyboardFrameValue.CGRectValue fromView:nil];
        maxHeight = CGRectGetMinY(keyboardFrame);
    }

    // update maxFrame
    _maxFrame = self.textField.frame;
    _maxFrame.origin.y += _maxFrame.size.height;
    _maxFrame.size.height = maxHeight;

    [self updateFrame];
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

    [textField.superview addSubview:self];
    [self adjustMaxFrame:nil];

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
    // TODO: read list of completions (in bg thread?)
    self.completions = @[@"First", @"Second", @"Third", @"Fourth", @"The fifth symphony has very long endings, that just go on and on and on...", @"Sixth", @"Seven is a lucky number", @"end!"];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // TODO: add textField.text to completions and give it highest priority
    // TODO: hide view
    // TODO: notify client
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (string.length == 0 && range.length > 0) return YES; // user deleting selection

    // find completions
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSPredicate *containsNewText = [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] %@", newText];
    NSArray *matchingCompletions = [self.completions filteredArrayUsingPredicate:containsNewText];

    // TODO: mark each completion bold where newText is

    // update completions list
    self.text = [matchingCompletions componentsJoinedByString:@"\n"];
    [self updateFrame];
    if (0 == matchingCompletions.count) return YES;

    // find best completion
    NSUInteger bestCompletionIdx = [matchingCompletions indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        NSString *completion = obj;
        NSRange range = [completion rangeOfString:newText options:NSCaseInsensitiveSearch|NSAnchoredSearch];
        return range.location == 0;
    }];
    if (NSNotFound == bestCompletionIdx) return YES;
    NSString *bestCompletion = matchingCompletions[bestCompletionIdx];

    // put best completion in textField as selection
    textField.text = bestCompletion;
    UITextPosition *beginning = [textField beginningOfDocument];
    UITextPosition *selStart = [textField positionFromPosition:beginning offset:newText.length];
    UITextPosition *selEnd = [textField positionFromPosition:beginning offset:bestCompletion.length];
    textField.selectedTextRange = [textField textRangeFromPosition:selStart toPosition:selEnd];
    return NO;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    // TODO: clear completions
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];

    return YES;
}


@end
