Pod::Spec.new do |s|
  s.name                = "YZYMD5"
  s.version             = "1.0.4"
  s.summary             = "Compute MD5 hash of string or file with small memory usage, implemented in pure Swift, support iOS and MacOS"
  s.description         = <<-DESC
                        Compute MD5 hash of string or file with small memory usage, implemented in pure Swift, support iOS and MacOS.
                        DESC
  s.homepage            = "https://boyknight.github.io/YZYMD5/"
  s.license             = "MIT"
  s.author              = { "Yang Zhi Yong" => "14497294@qq.com" }
  s.source              = { :git => "https://github.com/boyknight/YZYMD5", :tag => s.version.to_s }
  s.swift_version       = '4.2'
  s.source_files        = 'Sources/**/*'
  s.ios.deployment_target     = "9.0"
  #s.osx.deployment_target     = "10.10"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target    = "9.0"
end
