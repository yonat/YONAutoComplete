#
#  Be sure to run `pod spec lint YONAutoComplete.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "YONAutoComplete"
  s.version      = "1.0.0"
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
  s.social_media_url   = "http://twitter.com/yonatsharon"

  s.platform     = :ios, "5.0"

  s.source       = { :git => "https://github.com/yonat/YONAutoComplete.git", :commit => "1d4e00d3f370d34d6c2388560812c2770892a995", :tag => "1.0.0" }

  s.source_files  = "*.{h,m}"
  s.exclude_files = "YONAutoComplete", "YONAutoComplete.xcodeproj"

  s.requires_arc = true

end
