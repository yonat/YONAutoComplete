//
//  YOUAutoComplete.h
//
//  Created by Yonat Sharon on 5/6/14.
//

//  YONAutoComplete - Add auto-completion to a UITextField.
//
//  Usage:
//  Create a YONAutoComplete object and assign it as the delegate of a UITextField:
//      YONAutoComplete *autoComplete = [YONAutoComplete new];
//      textField.delegate = autoComplete;
//  Assign pre-assembled completions list by setting the property
//  completionsFileName or the property completions.
//
//  If you want to be able to get the user-modified completions file,
//  add to app.plist the key:
//      UIFileSharingEnabled (Application supports iTunes file sharing)

#import <UIKit/UIKit.h>

@interface YONAutoComplete : UITextView <UITextFieldDelegate>

/// completionsFileName.txt is a simple text file, one completion per line
@property (nonatomic, strong) NSString *completionsFileName; // Defaults to @"completions"

/// User chosen values are automatically added to the completions file, unless you freeze it
@property (nonatomic, assign) BOOL freezeCompletionsFile;

/// You can set the completions list programmatically, instead of from a file
@property (nonatomic, strong) NSArray *completions;

/// Don't auto-complete until the number of possible completions is maxCompletions or less (default is 0 = no limit)
@property (nonatomic, assign) NSInteger maxCompletions;

@end
