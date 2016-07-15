
Pod::Spec.new do |s|

  s.name         = "SZPullToRefresh"

  s.version      = "0.0.5"

  s.summary      = "pull to refresh"

  s.homepage     = "https://github.com/chenshengzhi/SZPullToRefresh"

  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.author       = { "陈圣治" => "csz2136@163.com" }

  s.platform     = :ios, "6.0"

  s.source       = { :git => "https://github.com/chenshengzhi/SZPullToRefresh.git", :tag => s.version.to_s }

  s.source_files = "SZPullToRefresh/*.{h,m}"

  s.requires_arc = true

end
