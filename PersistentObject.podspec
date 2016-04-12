Pod::Spec.new do |s|
  s.name = "PersistentObject"
  s.version = "0.2.1"
  s.summary = "Simplifies object persistence in Swift."

  s.homepage = "https://github.com/mattcomi/PersistentObject"  
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = { "Matt Comi" => "mattcomi@gmail.com" }

  s.source = { :git => "https://github.com/mattcomi/PersistentObject.git", :tag => "#{s.version}"} 
  s.source_files = "PersistentObject/*.{swift}"
  s.requires_arc = true
  
  s.platform = :ios
  s.ios.deployment_target = '9.0'
end