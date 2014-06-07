//
//  YOUAutoComplete.h
//  YONAutoComplete
//
//  Created by Yonat Sharon on 5/6/14.
//  Copyright (c) 2014 Yonat Sharon. All rights reserved.
//

// if you want to be able to get the user-modified completions file, add to your app.plist the key UIFileSharingEnabled (Application supports iTunes file sharing)

#import <UIKit/UIKit.h>

@interface YONAutoComplete : UITextView <UITextFieldDelegate>

@property (nonatomic, strong) NSString *completionsFileName; // fileName.txt is a simple text file, one completion per line. Defaults to @"completions"
@property (nonatomic, assign) BOOL freezeCompletionsFile; // if NO, user chosen values are automatically added to completions file
@property (nonatomic, strong) NSArray *completions; // for supplying completions programmatically, instead of from a file

@end
