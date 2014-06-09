//
//  YOUAutoComplete.m
//  YONAutoComplete
//
//  Created by Yonat Sharon on 5/6/14.
//  Copyright (c) 2014 Yonat Sharon. All rights reserved.
//

#import "YONAutoComplete.h"

@interface YONAutoComplete ()

@property (nonatomic, strong) NSMutableArray *matchingCompletions;
@property (nonatomic, weak) UITextField* textField;
@property (nonatomic, assign) CGRect maxFrame;
@property (nonatomic, strong) UITapGestureRecognizer *tap;

@end

@implementation YONAutoComplete

#pragma mark - View Layout

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

#pragma mark - Item Selection

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

#pragma mark - Appearance

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

#pragma mark - File I/O

- (NSString *)completionsFilePath
{
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *filePath = [[documentsDirectory stringByAppendingPathComponent:self.completionsFileName] stringByAppendingPathExtension:@"txt"];
    return filePath;
}

- (BOOL)isBundelUpdated:(NSString *)bundledFilePath
{
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:bundledFilePath error:nil];
    if (nil != attributes) {
        NSString *key = [@"Date-" stringByAppendingString:self.completionsFileName];
        NSDate* updated = attributes.fileModificationDate;
        NSDate* lastUpdate = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        if (nil == lastUpdate || NSOrderedSame != [updated compare:lastUpdate]) {
            [[NSUserDefaults standardUserDefaults] setObject:updated forKey:key];
            return YES;
        }
    }

    return  NO;
}

- (void)readCompletionsFromFile
{
    if (self.completionsFileName.length == 0) self.completionsFileName = @"completions";
    NSError *error;
    NSString *completionsString = nil;
    NSString *bundledCompletionsString = nil;

    if (!self.freezeCompletionsFile) { // read user completions list
        NSString *filePath = [self completionsFilePath];
        completionsString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    }

    // read bundled completions list
    NSString *bundledFile = [[NSBundle mainBundle] pathForResource:self.completionsFileName ofType:@"txt"];
    if (nil == completionsString || [self isBundelUpdated:bundledFile]) {
        bundledCompletionsString = [NSString stringWithContentsOfFile:bundledFile encoding:NSUTF8StringEncoding error:&error];
        bundledCompletionsString = [bundledCompletionsString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (0 == completionsString.length) {
            completionsString = bundledCompletionsString;
            bundledCompletionsString = nil;
        }
    }

    self.completions = completionsString ? [completionsString componentsSeparatedByString:@"\n"] : @[];

    // integrate completions from updated bundle
    if (bundledCompletionsString.length > 0) {
        NSMutableArray *bundledCompletions = [[bundledCompletionsString componentsSeparatedByString:@"\n"] mutableCopy];
        [bundledCompletions removeObjectsInArray:self.completions];
        self.completions = [self.completions arrayByAddingObjectsFromArray:bundledCompletions];
    }
}

#pragma mark - Finding Matches

- (void)resetCompletions
{
    self.text = nil;
    self.matchingCompletions = nil;
    [self updateFrame];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // read completions list
    if (self.completions) return; // completions are supplied by client
    [self readCompletionsFromFile];
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
    NSMutableAttributedString *completionsList = [NSMutableAttributedString new];

    // styles for paragraph and matches
    UIFontDescriptor *boldDescriptior = [self.font.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    UIFont *boldFont = [UIFont fontWithDescriptor:boldDescriptior size:self.font.pointSize];
    NSMutableParagraphStyle *paraStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paraStyle.paragraphSpacing = self.font.pointSize / 3;

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

    [completionsList addAttribute:NSParagraphStyleAttributeName value:paraStyle range:NSMakeRange(0, completionsList.length)];

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

#pragma mark - Ending

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];

    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self resetCompletions];

    // add textField.text to completions and give it highest priority
    if (!self.freezeCompletionsFile) {
        NSUInteger i = [self.completions indexOfObject:textField.text];
        if (0 != i) { // put textField.text at the top
            NSMutableArray *newCompletions = [self.completions mutableCopy];
            if (NSNotFound != i) { // remove previous entry
                [newCompletions removeObjectAtIndex:i];
            }
            [newCompletions insertObject:textField.text atIndex:0];
            [newCompletions removeObject:@""];
            NSString *completionsString = [newCompletions componentsJoinedByString:@"\n"];
            [completionsString writeToFile:[self completionsFilePath] atomically:NO encoding:NSUTF8StringEncoding error:NULL];
        }
    }

    // forward the action
    [textField sendActionsForControlEvents:UIControlEventEditingDidEndOnExit];
}


@end
