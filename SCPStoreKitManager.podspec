Pod::Spec.new do |s|
  s.name             = 'SCPStoreKitManager'
  s.version          = '1.1.1'
  s.summary          = 'Block based store kit manager for In-App Purchase on iOS7 with receipt validation.'
  s.description      = <<-DESC
                       Block based store kit manager for In-App Purchase for iOS7 with receipt validation. Please note that you must have iTunes Connect set up correctly with some IAPs already. The example App has no visual feed back to the user but you can follow it's progress via the console. The app can only work on a iDevice and can not be ran in a simulator.
                       DESC
                       
  s.homepage         = 'https://github.com/steprescott/SCPStoreKitManager'
  s.license          = 'MIT'
  s.author           = { 'Ste Prescott' => 'github@ste.me' }
  s.source           = { :git => 'https://github.com/steprescott/SCPStoreKitManager.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/ste_prescott'

  s.requires_arc = true

  s.frameworks = 'StoreKit'
  s.default_subspec = 'Core'

  s.subspec 'Core' do |core|
    core.source_files = 'Classes/SCPStoreKitManager.{h,m}',
                        'Classes/Categories/NSError+SCPStoreKitManager.{h,m}'
  end

  s.subspec 'SCPStoreKitReceiptValidator' do |validator|
    validator.dependency 'SCPStoreKitManager/Core'
    validator.dependency 'OpenSSL', '~> 1.0.0'
    validator.source_files = 'Classes/SCPStoreKitReceiptValidator/**/*.{h,m}'
  end
end