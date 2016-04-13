Pod::Spec.new do |s|
  s.name = "PersistentObject"
  s.version = "0.3.1"
  s.summary = "Simple object persistence in Swift."

  s.homepage = "https://github.com/mattcomi/PersistentObject"  
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = { "Matt Comi" => "mattcomi@gmail.com" }

  s.source = { :git => "https://github.com/mattcomi/PersistentObject.git", :tag => "#{s.version}"} 
  s.source_files = "PersistentObject/*.{swift}"
  s.requires_arc = true
  
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
end