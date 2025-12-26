#
# Be sure to run `pod lib lint WuKongRTC.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WuKongRTC'
  s.version          = '0.1.0'
  s.summary          = 'A short description of WuKongRTC.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/3895878/WuKongRTC'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'tangtaoit' => 'tt@wukong.ai' }
  s.source           = { :git => 'https://github.com/tangtaoit/WuKongRTC.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '12.0'
  
  s.libraries = 'c++', 'stdc++'
  
  s.vendored_frameworks = 'WuKongRTC/RTC/framework/WebRTC.framework','WuKongRTC/RTC/framework/OWT.framework'
  
  # Socket.IO C++ 客户端静态库
  s.vendored_libraries = 'WuKongRTC/RTC/lib/libsioclient_tls_no_verification.a'
  s.preserve_paths = 'WuKongRTC/RTC/lib/libsioclient_tls_no_verification.a'

  s.source_files = 'WuKongRTC/Classes/**/*'
  
  s.frameworks = 'UIKit', 'AVFoundation', 'AudioToolbox', 'VideoToolbox', 'CoreMedia', 'CoreVideo'
  
  s.pod_target_xcconfig = {
    'ENABLE_BITCODE' => 'NO',
    'OTHER_LDFLAGS' => ['-ObjC', '-ld64', '-lc++', '-lstdc++'], # -ld64 为了解决在xcode15上报错, -lc++ 和 -lstdc++ 链接C++标准库
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++11',
    'CLANG_CXX_LIBRARY' => 'libc++',
    'LIBRARY_SEARCH_PATHS' => '$(PODS_TARGET_SRCROOT)/WuKongRTC/RTC/lib' # 确保链接器能找到静态库
  }
  
  s.resource_bundles = {
    'WuKongRTC_images' => ['WuKongRTC/Assets/Images.xcassets'],
    'WuKongRTC_resources' => ['WuKongRTC/Assets/Others']
  }
  s.resources = ['WuKongRTC/Assets/Lang']

  s.dependency 'WuKongBase'
  s.dependency 'Socket.IO-Client-Swift'  # OWT framework 可能需要 Socket.IO 客户端
end
