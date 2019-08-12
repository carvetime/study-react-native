
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

我们分别创建一个common.js和business.js，common是一个空的view用于加载基础框架代码，business用于写业务的代码，随后我们使用react-native自带的带包工具分别打包两个文件
```bash
react-native bundle --platform ios --entry-file index.js --bundle-output ./dist/index.bundle --dev false
react-native bundle --platform ios --entry-file common.js --bundle-output ./dist/common.bundle --dev false
```

另外我们再创建一个简单脚本文件diff.js用于生产diff文件。
```bash
var DiffMatchPatch=require('diff-match-patch');
var fs = require('fs'),
path = require('path');


var data1 = fs.readFileSync(path.resolve(__dirname, '../dist/common.bundle'), 'utf8');
var data2 = fs.readFileSync(path.resolve(__dirname, '../dist/index.bundle'), 'utf8');

var ms_start = (new Date).getTime();

var dmp = new DiffMatchPatch();
var diff = dmp.diff_main(data1, data2,true);
if (diff.length > 2) {
  dmp.diff_cleanupSemantic(diff);
}
var patch_list = dmp.patch_make(data1, data2, diff);
var patch_text = dmp.patch_toText(patch_list);

var ms_end = (new Date).getTime();
fs.writeFile(path.resolve(__dirname, '../dist/business.patch'),patch_text,function(err){
    if(err){
        console.log(err);
    }else{
        var time = (ms_end - ms_start) / 1000 + 's';
        console.log("生成patch包成功\n")
        console.log("耗时:"+ time);
    }
})
```

这时候我们执行下diff的脚本，就生产business.path包,这是我们再dist文件夹看到三个文件，其中common.bundle是放在客户端本地的基础包，diff就是业务包或叫补丁包，我们将这两个包导入到iOS工程中，用于react-native进行本地加载。

我们看下iOS工程中的测试加载的代码
```oc
- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    RCTBridge *bridge = [[RCTBridge alloc]initWithDelegate:self launchOptions:nil];
    RCTRootView *rootView = [[RCTRootView alloc] initWithBridge:bridge moduleName:@"RNHighScores" initialProperties:nil];
    
    self.view = rootView;
}



- (NSString *)getMergeBundlePath{
    NSString *commonBundlePath = [[NSBundle mainBundle] pathForResource:@"common" ofType:@"bundle"];
    NSLog(@"path=%@",commonBundlePath);
    NSString *commonJsCode = [[NSString alloc] initWithContentsOfFile:commonBundlePath encoding:NSUTF8StringEncoding error:nil];
    
    
    NSString *businessBundlePath = [[NSBundle mainBundle] pathForResource:@"business" ofType:@"patch"];
    NSLog(@"path=%@",businessBundlePath);
    NSString *businessJsCode = [[NSString alloc] initWithContentsOfFile:businessBundlePath encoding:NSUTF8StringEncoding error:nil];
    
    
    DiffMatchPatch *diffMatchPatch = [[DiffMatchPatch alloc] init];
    NSArray *convertedPatches = [diffMatchPatch patch_fromText:businessJsCode error:nil];
    
    NSArray *resultsArray = [diffMatchPatch patch_apply:convertedPatches toString:commonJsCode];
    NSString *resultJSCode = resultsArray[0]; //patch合并后的js
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    NSString *newPath = [NSString stringWithFormat:@"%@/%@.bundle",docDir,@"newbusiness"];
    
    if (resultsArray.count > 1) {
        BOOL ret = [resultJSCode writeToFile:newPath atomically:NO encoding:NSUTF8StringEncoding error:nil];
        NSLog(@"存入状态%d",ret);
    }
    return newPath;
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge{
    if (DEBUG) {
        return [NSURL URLWithString:@"http://localhost:8081/index.bundle?platform=ios"];
    } else {
        NSString *path = [self getMergeBundlePath];
        NSURL *jsBundleURL = [NSURL URLWithString:path];
        return jsBundleURL;
    }
}

```
这里我们可以看到common和business在打包的时候进行拆分，在客户端本地加载的时候有进行了合并，基础代码合业务代码有效的进行了拆分，不论有多少个业务模块common代码只有一份，不会造成多余的重复代码浪费存储和下载空间，同时diff方案目前也是很多热修复补丁使用的方案，但是此方法也是存在某些不足的，比如说在客户端进行合并及存储操作中也是存在I/O耗时操作的。