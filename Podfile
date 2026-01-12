# Uncomment the next line to define a global platform for your project
 platform :ios, '12.0'
workspace 'TangSengDaoDaoiOS.xcworkspace'

post_install do |installer|
    # 填写你自己的开发者团队的team id
    dev_team = "H8PU463W68"
    project = installer.aggregate_targets[0].user_project
    project.targets.each do |target|
        target.build_configurations.each do |config|
            if dev_team.empty? and !config.build_settings['DEVELOPMENT_TEAM'].nil?
                dev_team = config.build_settings['DEVELOPMENT_TEAM']
            end
        end
    end
    
    # Fix bundle targets' 'Signing Certificate' to 'Sign to Run Locally'
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
              config.build_settings['DEVELOPMENT_TEAM'] = dev_team
            end
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
            config.build_settings['ENABLE_BITCODE'] = 'NO'
            config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
        end
    end
    
    # Add PrivacyInfo.xcprivacy files for third-party SDKs that require privacy manifests
    # Apple requires privacy manifests for commonly used third-party SDKs (ITMS-91061)
    # According to Apple: The PrivacyInfo.xcprivacy file must be in the framework bundle root
    # For use_frameworks!, we use a Run Script build phase to copy the file to framework root
    privacy_manifest_content = <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
    	<key>NSPrivacyAccessedAPITypes</key>
    	<array/>
    	<key>NSPrivacyCollectedDataTypes</key>
    	<array/>
    	<key>NSPrivacyTrackingDomains</key>
    	<array/>
    	<key>NSPrivacyTracking</key>
    	<false/>
    </dict>
    </plist>
    XML
    
    # List of SDKs that require privacy manifests according to Apple's requirements
    sdk_names = ['AFNetworking', 'FMDB', 'MBProgressHUD', 'SDWebImage', 'Starscream', 'Toast']
    
    sdk_names.each do |sdk_name|
        # Create PrivacyInfo.xcprivacy file in the SDK directory
        sdk_path = File.join(installer.sandbox.root, sdk_name, 'PrivacyInfo.xcprivacy')
        File.write(sdk_path, privacy_manifest_content)
        puts "✅ Created PrivacyInfo.xcprivacy for #{sdk_name}"
        
        # Find the corresponding target and add a Run Script build phase to copy file to framework root
        # Note: Some SDKs may have different target names (e.g., "Starscream-framework" instead of "Starscream")
        installer.pods_project.targets.each do |target|
            # Match target name exactly or if it starts with SDK name followed by "-"
            if target.name == sdk_name || target.name.start_with?("#{sdk_name}-")
                privacy_file_path = File.join(installer.sandbox.root, sdk_name, 'PrivacyInfo.xcprivacy')
                if File.exist?(privacy_file_path)
                    # Find or create Run Script phase
                    script_phase = target.build_phases.find { |phase| 
                        phase.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) && 
                        phase.name == "Copy Privacy Manifest"
                    }
                    
                    # Use PODS_ROOT to find the privacy manifest file
                    privacy_file_path_var = "${PODS_ROOT}/#{sdk_name}/PrivacyInfo.xcprivacy"
                    script_content = <<~SCRIPT
                    # Copy PrivacyInfo.xcprivacy to framework bundle root
                    # This script must run after the framework is built
                    PRIVACY_FILE="#{privacy_file_path_var}"
                    # For frameworks built by CocoaPods, the output path is typically:
                    # ${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}/${PRODUCT_NAME}.framework
                    # But we need to check multiple possible locations
                    FRAMEWORK_DIR1="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}/${PRODUCT_NAME}.framework"
                    FRAMEWORK_DIR2="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.framework"
                    FRAMEWORK_DIR3="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/${PRODUCT_NAME}.framework"
                    
                    # Determine which framework directory exists
                    if [ -d "$FRAMEWORK_DIR1" ]; then
                        FRAMEWORK_DIR="$FRAMEWORK_DIR1"
                    elif [ -d "$FRAMEWORK_DIR2" ]; then
                        FRAMEWORK_DIR="$FRAMEWORK_DIR2"
                    elif [ -d "$FRAMEWORK_DIR3" ]; then
                        FRAMEWORK_DIR="$FRAMEWORK_DIR3"
                    else
                        # Fallback: use the most common location
                        FRAMEWORK_DIR="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}/${PRODUCT_NAME}.framework"
                    fi
                    
                    # Debug output
                    echo "🔍 Copying PrivacyInfo.xcprivacy for ${PRODUCT_NAME}"
                    echo "   Source: $PRIVACY_FILE"
                    echo "   Framework: $FRAMEWORK_DIR"
                    
                    if [ ! -f "$PRIVACY_FILE" ]; then
                        echo "❌ Error: PrivacyInfo.xcprivacy not found at $PRIVACY_FILE"
                        exit 1
                    fi
                    
                    if [ ! -d "$FRAMEWORK_DIR" ]; then
                        echo "❌ Error: Framework directory not found at $FRAMEWORK_DIR"
                        exit 1
                    fi
                    
                    # Try to copy to Contents/Resources first (macOS style framework)
                    # If Contents/Resources doesn't exist, copy to framework root (iOS style framework)
                    if [ -d "$FRAMEWORK_DIR/Contents/Resources" ]; then
                        # macOS style framework: Framework.framework/Contents/Resources/
                        DEST_PATH="$FRAMEWORK_DIR/Contents/Resources/PrivacyInfo.xcprivacy"
                        echo "   Using macOS style: Contents/Resources/"
                    else
                        # iOS style framework: Framework.framework/ (root)
                        DEST_PATH="$FRAMEWORK_DIR/PrivacyInfo.xcprivacy"
                        echo "   Using iOS style: framework root"
                    fi
                    
                    cp "$PRIVACY_FILE" "$DEST_PATH"
                    if [ $? -eq 0 ]; then
                        echo "✅ Successfully copied PrivacyInfo.xcprivacy to ${PRODUCT_NAME}.framework"
                        echo "   Final location: $DEST_PATH"
                    else
                        echo "❌ Error: Failed to copy PrivacyInfo.xcprivacy"
                        exit 1
                    fi
                    SCRIPT
                    
                    if script_phase.nil?
                        # Create new Run Script build phase
                        script_phase = target.project.new(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
                        script_phase.name = "Copy Privacy Manifest"
                        script_phase.shell_script = script_content
                        script_phase.shell_path = "/bin/sh"
                        # Don't set run_only_for_deployment_postprocessing - use default
                        # Insert as the last build phase (after Resources) to ensure framework is built first
                        target.build_phases << script_phase
                        puts "✅ Added Run Script phase to #{target.name} to copy PrivacyInfo.xcprivacy"
                    else
                        # Update existing script to use correct path
                        script_phase.shell_script = script_content
                        puts "✅ Updated Run Script phase for #{target.name} to use correct path"
                    end
                    
                    # Save the project to ensure changes are persisted
                    target.project.save
                end
            end
        end
    end
end


abstract_target 'TangSengDaoDaoiOSBase' do
  
#  pod 'lottie-ios', '~> 2.5.3'
  pod 'Socket.IO-Client-Swift'
  pod 'SSZipArchive', '~> 2.2.3'
  pod 'SocketRocket'
  pod 'Aspects'
  pod 'ReactiveObjC'

  target 'TangSengDaoDaoiOS' do
    project 'TangSengDaoDaoiOS.xcodeproj'
    
  use_frameworks!
  pod 'YBImageBrowser/NOSD', :git=>'https://github.com/tangtaoit/YBImageBrowser.git'
  pod 'YYImage/WebP', :git => 'https://github.com/tangtaoit/YYImage.git'
  pod 'AsyncDisplayKit', :git => 'https://github.com/tangtaoit/AsyncDisplayKit.git'
  pod 'librlottie', :git => 'https://github.com/tangtaoit/librlottie.git'
  
  pod 'WuKongIMSDK',  :path => './Modules/WuKongIMiOSSDK'   ## WuKongBase 基础工具包  源码地址 https://github.com/WuKongIM/WuKongIMiOSSDK
#  pod 'WuKongIMSDK',  :path => '../../../wukongIM/iOS/WuKongIMiOSSDK'
#  pod  'WuKongIMSDK', '~> 1.0.2' ## 源码地址 https://github.com/WuKongIM/WuKongIMiOSSDK
  pod 'WuKongBase',  :path => './Modules/WuKongBase'   ## WuKongBase 基础工具包
  pod 'WuKongLogin', :path => './Modules/WuKongLogin'  ##  登录模块
  pod 'WuKongContacts', :path => './Modules/WuKongContacts'  ## 联系人模块
  pod 'WuKongDataSource', :path => './Modules/WuKongDataSource'  ## 数据源
  pod 'WuKongGroupManager', :path => './Modules/WuKongGroupManager'  ## 群管理
  pod 'WuKongMoment', :path => './Modules/WuKongMoment'  ## Monment
  pod 'WuKongRTC', :path => './Modules/WuKongRTC'  ## RTC
  pod 'WuKongSmallVideo', :path => './Modules/WuKongSmallVideo'  ## 视频
  end
  
end


