Pod::Spec.new do |s|
  s.name             = 'jivosdk'
  s.version          = '0.2.0'
  s.summary          = "JivoSDK Plugin"
  s.description      = "Flutter plugin that bridges to JivoSDK"
  s.homepage         = "https://github.com/JivoChat"
  s.license          = { :file => "../LICENSE" }
  s.author           = { "Stan Potemkin" => "potemkin@jivosite.com" }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'JivoSDK'
  s.platform = :ios, '11.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_versions = ['5.5', '5.6', '5.7', '5.8', '5.9']
end
