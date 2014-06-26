**YONAutoComplete - Add auto-completion to a UITextField**

<img src="http://ootips.org/yonat/wp-content/uploads/2014/06/YONAutoComplete.png">

Simplest auto-complete:  
just create a `YONAutoComplete` object and assign it as the delegate of a `UITextField`:

      YONAutoComplete *autoComplete = [YONAutoComplete new];
      textField.delegate = autoComplete;

The user can either choose from the list of completions, or type a new value that will be added to the list automatically.

**Customiztion:**

- Use pre-assembled completions list from a text file, by setting the property `completionsFileName`
- Programmatically set completions list, by setting the property `completions`
- Don't add user-typed values to the completions list, by setting the property `freezeCompletionsFile`
