Pod::Spec.new do |s|
  s.name             = "SCPStoreKitManager"
  s.version          = File.read('VERSION')
  s.summary          = "Block based store kit manager for In-App Purchase on iOS7 with receipt validation."
  s.description      = <<-DESC
                       Block based store kit manager for In-App Purchase for iOS7 with receipt validation. Please note that you must have iTunes Connect set up correctly with some IAPs already. The example App has no visual feed back to the user but you can follow it's progress via the console. The app can only work on a iDevice and can not be ran in a simulator.
                       DESC
  s.homepage         = "https://github.com/steprescott/SCPStoreKitManager"
  s.license          = 'MIT'
  s.author           = { "Ste Prescott" => "github@ste.me" }
  s.source           = { :git => "https://github.com/steprescott/SCPStoreKitManager.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/ste_prescott'

  # s.platform     = :ios, '7.0'
  # s.ios.deployment_target = '7.0'
  s.requires_arc = true

  s.source_files = 'Classes/**/*.h'

  s.public_header_files = 'Classes/{SCPStoreKitManager.h, SCPStoreKitReceiptValidator/Receipts/*.h, SCPStoreKitReceiptValidator/*.h, Categories/*.h}'
  s.frameworks = 'StoreKit'
end