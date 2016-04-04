
Pod::Spec.new do |s|
  s.name         = "ZCCale"
  s.version      = "2.0.0"
  s.summary      = "customizable date range picker"
  s.description  = <<-DESC
                    Fully customizable date range picker
                   DESC
  s.homepage     = "https://github.com/zuo305/ZCCale"
  
  s.license      = 'MIT'
  s.author       = { "zuo305" => "johnzuo305@gmail.com" }
  s.social_media_url = "https://twitter.com/johnzuo305"
  s.source       = { :git => "https://github.com/zuo305/ZCCale.git", :tag => '2.0.0' }

  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source_files = "GLCalendarView/Sources/**/*.{h,m}"
  s.resources = [
    "GLCalendarView/Sources/**/*.{png}",
    "GLCalendarView/Sources/**/*.{storyboard,xib}",
  ]
  
  s.frameworks = 'Foundation', 'UIKit'
end