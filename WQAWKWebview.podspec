#
# Be sure to run `pod lib lint WQAWKWebview.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#


# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

Pod::Spec.new do |s|
  s.name         = "WQAWKWebview"
  s.version      = "2.1.1"
  s.summary      = "A WKWebview Bridge and offline plan"
  s.description  = "A WKWebview Bridge and offline plan."
  s.homepage     = "https://github.com/371612143/WQAWKWebview"
  s.license = 'Copyright © 2021 matthew. All rights reserved.'
  s.author       = { "wqa" => "a371612143@qq.com" }
  s.source       = { :git => "https://github.com/371612143/WQAWKWebview.git", :tag => s.version }
  
  s.ios.deployment_target = '11.0'
  s.static_framework = true
  s.requires_arc = true
  s.default_subspecs = 'Webview'

  s.subspec 'Webview' do |ss|
      ss.source_files = 'WQAWKWebview/Classes/bridge/*', 'WQAWKWebview/Classes/*.{h,m}'
      ss.public_header_files = 'WQAWKWebview/Classes/bridge/*.h', 'WQAWKWebview/Classes/*.{h}'
  end

  s.subspec 'Intercept' do |ss|
    ss.source_files = 'WQAWKWebview/Classes/Intercept/*'
    ss.public_header_files = 'WQAWKWebview/Classes/Intercept/*.h'
  end

  s.dependency 'AFNetworking', '~> 4.0'
end
  
  # s.resource_bundles = {
  #   'WQAWKWebview' => ['WQAWKWebview/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'

