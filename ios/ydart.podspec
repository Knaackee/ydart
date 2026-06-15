Pod::Spec.new do |s|
  s.name             = 'ydart'
  s.version          = '0.1.0'
  s.summary          = 'Flutter Android/iOS bindings for yrs.'
  s.description      = 'Flutter mobile FFI bindings for yrs (y-crdt), the Rust port of Yjs.'
  s.homepage         = 'https://github.com/Knaackee/ydart'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'ydart contributors' => 'maintainers@example.com' }
  s.source           = { :path => '.' }
  s.platform         = :ios, '13.0'
  s.vendored_frameworks = 'Frameworks/libyrs.xcframework'
end
