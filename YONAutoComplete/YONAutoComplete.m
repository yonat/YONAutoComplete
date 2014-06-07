//
//  YOUAutoComplete.m
//  YONAutoComplete
//
//  Created by Yonat Sharon on 5/6/14.
//  Copyright (c) 2014 Yonat Sharon. All rights reserved.
//

#import "YONAutoComplete.h"

@interface YONAutoComplete ()

@property (nonatomic, strong) NSArray *completions;
@property (nonatomic, strong) NSMutableArray *matchingCompletions;
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
    NSUInteger offset = 0;
    for (NSString *completion in self.matchingCompletions) {
        offset += completion.length + 1;
        if (charOffset <= offset) {
            // set the text of the field
            self.textField.text = completion;
            return;
        }
    }
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

    // TODO: add spacing between paragraphs

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

- (void)resetCompletions
{
    self.text = nil;
    self.matchingCompletions = nil;
    [self updateFrame];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (range.length > 0 || range.location < textField.text.length) { // deletion/overwrite
        [self resetCompletions];
        if (string.length == 0 && !textField.selectedTextRange.empty) { // user deleting selection
            return YES;
        }
    }

    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (newText.length == 0) return YES;

    // mark completions with bold
    UIFontDescriptor *boldDescriptior = [self.font.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    UIFont *boldFont = [UIFont fontWithDescriptor:boldDescriptior size:self.font.pointSize];
    NSMutableAttributedString *completionsList = [NSMutableAttributedString new];

    // find completions
    __block NSString *bestCompletion = nil;
    __block NSAttributedString *newLine = [[NSAttributedString alloc] initWithString:@"\n"];
    if (nil == self.matchingCompletions) self.matchingCompletions = [self.completions mutableCopy];
    for (NSUInteger i = self.matchingCompletions.count; i > 0; --i) {
        NSString *completion = self.completions[i-1];
        NSRange range = [completion rangeOfString:newText options:NSCaseInsensitiveSearch];
        if (NSNotFound == range.location) {
            [self.matchingCompletions removeObjectAtIndex:i-1];
        }
        else {
            if (range.location == 0) {
                bestCompletion = completion;
            }
            NSMutableAttributedString *match = [[NSMutableAttributedString alloc] initWithString:completion];
            [match addAttribute:NSFontAttributeName value:boldFont range:range];
            if (completionsList.length > 0) [completionsList insertAttributedString:newLine atIndex:0];
            [completionsList insertAttributedString:match atIndex:0];
        }
    }

    // update completions list
    self.attributedText = completionsList;
    [self updateFrame];

    // put best completion in textField as selection
    if (nil == bestCompletion) return YES;
    textField.text = bestCompletion;
    UITextPosition *beginning = [textField beginningOfDocument];
    UITextPosition *selStart = [textField positionFromPosition:beginning offset:newText.length];
    UITextPosition *selEnd = [textField positionFromPosition:beginning offset:bestCompletion.length];
    textField.selectedTextRange = [textField textRangeFromPosition:selStart toPosition:selEnd];
    return NO;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    [self resetCompletions];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];

    return YES;
}


@end
