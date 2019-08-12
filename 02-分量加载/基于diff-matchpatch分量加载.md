
纯RN项目在实际开发过程中很少见，大多数原有项目嵌套RN，经常针对是某个页面或模块用一个RN包，这时候就存在多个RN包问题，每个RN包中都包含了一些基础的common代码，这部分代码体积大约有700KB左右，随着包的个数增加，重复的common代码将会越来越多，这样当时是我们不想看到的结果，这时候就需要用到拆分包的方案。

目前主流的拆分包方案大致有3种
- 基于google-diff-match-patch来实现，打一个空View的包生成common包，再打一个包含业务代码的包生成全量包，然后对比全量包和common生成diff包即业务包。
- 打一个空View包，并在View中添加一个监听方法，用打包工具生成business包及对应id，原生代码加载完成business后，发送消息给空View，空View加载渲染business。
- 基于metro直接打包生成common和business包。

这里我们先演示下google-diff-match-patch的diff拆分包方案

首先我们新建一个iOS项目，并生成配置下pod
```pod
# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

require_relative '../node_modules/@react-native-community/cli-platform-ios/native_modules'

target 'RNSplitePack' do
  # Uncomment the next line if you're using Swift or would like to use dynamic frameworks
  # use_frameworks!

  # Pods for RNSplitePack
  pod 'React', :path => '../node_modules/react-native/'
  pod 'React-Core', :path => '../node_modules/react-native/React'
  pod 'React-DevSupport', :path => '../node_modules/react-native/React'
  pod 'React-fishhook', :path => '../node_modules/react-native/Libraries/fishhook'
  pod 'React-RCTActionSheet', :path => '../node_modules/react-native/Libraries/ActionSheetIOS'
  pod 'React-RCTAnimation', :path => '../node_modules/react-native/Libraries/NativeAnimation'
  pod 'React-RCTBlob', :path => '../node_modules/react-native/Libraries/Blob'
  pod 'React-RCTImage', :path => '../node_modules/react-native/Libraries/Image'
  pod 'React-RCTLinking', :path => '../node_modules/react-native/Libraries/LinkingIOS'
  pod 'React-RCTNetwork', :path => '../node_modules/react-native/Libraries/Network'
  pod 'React-RCTSettings', :path => '../node_modules/react-native/Libraries/Settings'
  pod 'React-RCTText', :path => '../node_modules/react-native/Libraries/Text'
  pod 'React-RCTVibration', :path => '../node_modules/react-native/Libraries/Vibration'
  pod 'React-RCTWebSocket', :path => '../node_modules/react-native/Libraries/WebSocket'

  pod 'React-cxxreact', :path => '../node_modules/react-native/ReactCommon/cxxreact'
  pod 'React-jsi', :path => '../node_modules/react-native/ReactCommon/jsi'
  pod 'React-jsiexecutor', :path => '../node_modules/react-native/ReactCommon/jsiexecutor'
  pod 'React-jsinspector', :path => '../node_modules/react-native/ReactCommon/jsinspector'
  pod 'yoga', :path => '../node_modules/react-native/ReactCommon/yoga'

  pod 'DoubleConversion', :podspec => '../node_modules/react-native/third-party-podspecs/DoubleConversion.podspec'
  pod 'glog', :podspec => '../node_modules/react-native/third-party-podspecs/glog.podspec'
  pod 'Folly', :podspec => '../node_modules/react-native/third-party-podspecs/Folly.podspec'
  pod 'Folly', :podspec => '../node_modules/react-native/third-party-podspecs/Folly.podspec'

  target 'RNSplitePackTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'RNSplitePackUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end
```

然后我们在项目跟目录创建一个package.json文件并install下react的库及diff-match-patch的库
```json
{
  "name": "RNSplitePack",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "start": "yarn react-native start",
    "test": "node ./script/diff.js"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "react": "^16.8.6",
    "react-native": "^0.60.4"
  },
  "devDependencies": {
    "diff-match-patch": "^1.0.4"
  }
}

```

接着我们在iOS工程中pod install下安装下相关依赖，之后我们将googel-diff-match-patch导入到工程，由于库比较老不支持pod同时有些MRC的文件需要配置下-fno-objc-arc。

这是我们整个简单的配置就基本完成，接下来我们就是进行common和business包拆分的流程。
