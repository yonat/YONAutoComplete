
Pod::Spec.new do |s|

  s.name         = "YONAutoComplete"
  s.version      = "1.3.4"
  s.summary      = "Add auto-completion to a UITextField"

  s.description  = <<-DESC
Simplest auto-complete:  
just create a `YONAutoComplete` object and assign it as the delegate of a `UITextField`:

```objective-c
    YONAutoComplete *autoComplete = [YONAutoComplete new];
    textField.delegate = autoComplete;
```

The user can either choose from the list of completions, or type a new value that will be added to the list automatically.
                   DESC

  s.homepage     = "https://github.com/yonat/YONAutoComplete"
  s.screenshots  = "http://ootips.org/yonat/wp-content/uploads/2014/06/YONAutoComplete.png"

  s.license      = { :type => "MIT", :file => "LICENSE.txt" }

  s.author             = { "Yonat Sharon" => "yonat@ootips.org" }

  s.platform     = :ios, "9.0"

  s.source       = { :git => "https://github.com/yonat/YONAutoComplete.git", :tag => s.version }

  s.source_files  = "*.{h,m}"
  s.exclude_files = "YONAutoComplete", "YONAutoComplete.xcodeproj"
  s.resource_bundles = {s.name => ['PrivacyInfo.xcprivacy']}

  s.requires_arc = true

end
