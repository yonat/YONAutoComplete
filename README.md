## YONAutoComplete - Add auto-completion to a UITextField

<img src="http://ootips.org/yonat/wp-content/uploads/2014/06/YONAutoComplete.png">

Simplest auto-complete:  
just create a `YONAutoComplete` object and assign it as the delegate of a `UITextField`:

```objective-c
YONAutoComplete *autoComplete = [YONAutoComplete new];
textField.delegate = autoComplete;
```

The user can either choose from the list of completions, or type a new value that will be added to the list automatically.

### Customization

You can use pre-assembled completions list from a text file:

```objective-c
autoComplete.completionsFileName = @"SomeFileName";
```

Or set the completions list programmatically:

```objective-c
autoComplete.completions = @[@"First Item", @"Second Item"];
```

To prevent user-typed values from being added to the completions list:

```objective-c
autoComplete.freezeCompletionsFile = YES;
```

Limit number of completions shown:
```objective-c
    autoComplete.maxCompletions = 7;
```


## Installation

### CocoaPods:

```ruby
pod 'YONAutoComplete'
```
