//
//  YOUAutoComplete.m
//
//  Created by Yonat Sharon on 5/6/14.
//

#import "YONAutoComplete.h"

@interface UIView (mxcl)
- (UIViewController *)parentViewController;
@end

@implementation UIView (mxcl)
- (UIViewController *)parentViewController {
    if (@available(iOS 10.0, *)) {
        UIResponder *responder = self;
        while ([responder isKindOfClass:[UIView class]])
        responder = [responder nextResponder];
        return (UIViewController *)responder;
    } else {
        return nil;
    }
}
@end


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
    CGSize newSize = self.text.length && !self.shouldHideCompletions ? [self sizeThatFits:CGSizeMake(maxWidth, MAXFLOAT)] : CGSizeZero;
    CGRect newFrame = _maxFrame;
    if (self.superview == self.textField.superview) {
        newFrame.size = CGSizeMake(MAX(newSize.width, maxWidth), MIN(newSize.height, CGRectGetHeight(_maxFrame)));
    } else { // show completions above textField
        newFrame.size = CGSizeMake(MAX(newSize.width, maxWidth), newSize.height);
        newFrame.origin = [self.superview convertPoint:self.textField.superview.bounds.origin fromView:self.textField.superview];
        newFrame.origin.y -= newFrame.size.height;
    }
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
    _maxFrame = [self.superview convertRect:self.textField.frame fromView:self.textField.superview];
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

- (void)useTextFieldFont
{
    self.font = [UIFont fontWithName:self.textField.font.fontName size:0.9*self.textField.font.pointSize];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    self.textField = textField;
    self.editable = NO;
    self.dataDetectorTypes = UIDataDetectorTypeNone;

    UIView *parentView = textField.superview;
    if (@available(iOS 10.0, *)) {
        if ([NSStringFromClass(textField.class) containsString:@"AlertController"]) {
            UIViewController *parentVC = textField.parentViewController;
            while (![parentVC isKindOfClass:UIAlertController.class]) {
                parentVC = parentVC.view.superview.parentViewController;
            }
            parentView = parentVC.view;
        }
    }
    if (nil == self.superview) {
        [parentView addSubview:self];
    }
    [self adjustMaxFrame:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustMaxFrame:) name:UIKeyboardDidShowNotification object:nil];

    // style same as textField, only smaller and paler
    self.textAlignment = textField.textAlignment;
    [self useTextFieldFont];
    self.textColor = [textField.textColor colorWithAlphaComponent:0.75];
    UIColor *textFieldBackgroundColor = textField.backgroundColor != nil ? textField.backgroundColor : UIColor.whiteColor;
    self.backgroundColor = [textFieldBackgroundColor colorWithAlphaComponent:0.75];
    self.layer.borderColor = [self.textColor colorWithAlphaComponent:0.25].CGColor;
    self.layer.borderWidth = 0.25;

    // respond to taps
    if (nil == self.tap) {
        self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:self.tap];
    }

    // read completions list
    if (!self.completions) {
        [self readCompletionsFromFile];
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

- (BOOL)isBundleUpdated:(NSString *)bundledFilePath
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
    if (nil == completionsString || [self isBundleUpdated:bundledFile]) {
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

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    [self useTextFieldFont];

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
    UIFontDescriptor *boldDescriptor = [self.font.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    UIFont *boldFont = [UIFont fontWithDescriptor:boldDescriptor size:self.font.pointSize];
    NSMutableParagraphStyle *paraStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paraStyle.paragraphSpacing = self.font.pointSize / 3;
    [completionsList addAttribute:NSParagraphStyleAttributeName value:paraStyle range:NSMakeRange(0, completionsList.length)];

    // find completions
    __block NSString *bestCompletion = nil;
    __block NSAttributedString *newLine = [[NSAttributedString alloc] initWithString:@"\n"];
    if (nil == self.matchingCompletions) self.matchingCompletions = [self.completions mutableCopy];
    for (NSUInteger i = self.matchingCompletions.count; i > 0; --i) {
        NSString *completion = self.matchingCompletions[i-1];
        NSRange range = [completion rangeOfString:newText options:NSCaseInsensitiveSearch];
        if (NSNotFound == range.location) {
            [self.matchingCompletions removeObjectAtIndex:i-1];
        }
        else {
            if (range.location == 0) {
                bestCompletion = completion;
            }
            NSMutableAttributedString *match = [[NSMutableAttributedString alloc] initWithString:completion];
            [match addAttribute:NSFontAttributeName value:self.font range:NSMakeRange(0, match.length)];
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
    if (self.shouldHideCompletions) return YES;
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

- (BOOL)shouldHideCompletions {
    return (self.maxCompletions > 0 && self.maxCompletions < self.matchingCompletions.count);
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
}

@end
