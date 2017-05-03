#import "RNMediaEditor.h"
#import "RCTImageLoader.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import <MobileCoreServices/MobileCoreServices.h>


@interface RNMediaEditor ()

@property (nonatomic, strong) NSMutableDictionary *options;

@end


@implementation RNMediaEditor {
  NSString *_imageAssetPath;
}


@synthesize bridge = _bridge;

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

- (NSDictionary *)constantsToExport
{
  return @{
    @"AssetType": @{
      @"Image": @"image",
      @"Video": @"video"
    }
  };
}

- (UIColor *)colorFromHexString:(NSString *)hexString Alpha:(float)alpha {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 \
                           green:((rgbValue & 0xFF00) >> 8)/255.0 \
                            blue:(rgbValue & 0xFF)/255.0 alpha:alpha];
}

// borderImage = [self imageWithColor:videoBackgroundColor rectSize:CGRectMake(-(size.height - size.width)/2, 0, size.width, size.width)];
- (UIImage *)imageWithColor:(UIColor *)color rectSize:(CGRect)imageSize {
    CGRect rect = imageSize;
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);   // Fill it with your color
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
 
    return image;
}


////////////////////////////////////////////////////////////////////////
// how to use this
// jpegData = [self returnJpgData:firstText image:()image];
// return jpgData;
- (NSData *)returnJpgData:(NSDictionary *)textInfo image:(UIImage *)image{
  // again to second text
  NSNumber *fontSizeNumber = [textInfo objectForKey:@"fontSize"];
  NSInteger fontSize = abs(fontSizeNumber.intValue);

  NSNumber *lineNumber = [textInfo objectForKey:@"lineNum"];
  NSInteger lineNum = abs(lineNumber.intValue);

  NSNumber *maxLengthNumber = [textInfo objectForKey:@"maxLength"];
  NSInteger maxLength = abs(maxLengthNumber.intValue);  

  UIColor *textColor =
  [self colorFromHexString:[textInfo objectForKey:@"textColor"] Alpha:1.0];

  NSNumber *backgroundOpacityNumber = [textInfo objectForKey:@"backgroundOpacity"];
  float backgroundOpacity = backgroundOpacityNumber.floatValue;

  UIColor *backgroundColor =
  [self colorFromHexString:[textInfo objectForKey:@"backgroundColor"] Alpha:backgroundOpacity];

  NSNumber *topNumber = [textInfo objectForKey:@"top"];
  NSNumber *leftNumber = [textInfo objectForKey:@"left"];
  CGFloat top = topNumber.floatValue;
  CGFloat left = leftNumber.floatValue;

  NSString *text = [textInfo objectForKey:@"text"];

  // create font and size of font
  UIFont *font = [UIFont boldSystemFontOfSize:fontSize];
  CGSize size = [text sizeWithFont:font];

  // create rect of image
  // ここから繰り返し
  UIGraphicsBeginImageContext(image.size);
  [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];

  // wrapper rect
  // CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);

  // the base point of text rect
  CGPoint point = CGPointMake(left, top);
  [backgroundColor set];

  CGRect textContainer;
  CGRect textRect;
  NSNumber *isTextInfoVertical = [textInfo objectForKey:@"vertical"];

  if ([isTextInfoVertical integerValue] == 1) {
  NSLog(@"Vertical string");
  textContainer = CGRectMake(point.x - fontSize / 6, point.y - fontSize / 6,
   size.height * lineNum + fontSize / 6, size.height * maxLength + fontSize / 3);
  CGContextFillRect(
    UIGraphicsGetCurrentContext(),
    textContainer
  );
  textRect = CGRectMake(point.x + fontSize / 6, point.y + fontSize / 6, size.height * lineNum, size.height * maxLength);
  } else {
  textContainer = CGRectMake(point.x - fontSize / 6, point.y - fontSize / 6, size.height * maxLength + fontSize / 3, size.height * lineNum + fontSize / 6);
  CGContextFillRect(
    UIGraphicsGetCurrentContext(),
    textContainer
  );
  textRect = CGRectMake(point.x + fontSize / 6, point.y + fontSize / 6, size.height * maxLength, size.height * lineNum);
  }


  [textColor set];
  [text drawInRect:textRect  // 文字入れる
        withFont:font  // apply font
     lineBreakMode:UILineBreakModeClip
       alignment:UITextAlignmentLeft ];


  UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();


  NSData* UIImageJPEGRepresentedData = [[NSData alloc] initWithData:UIImageJPEGRepresentation(newImage, 1.0f)];

  return UIImageJPEGRepresentedData;
}

////////////////////////////////////////////////////////////////////
// how to use this
// [self embedTextOnCALayer:firstText targetLayer:overlayLayer]
- (void)embedTextOnCALayer:(NSDictionary *)textInfo targetLayer:(CALayer *)layer isBaseVideoPortrait:(BOOL)isBaseVideoPortrait size:(CGSize *)size{
  // embed text on CATextLayer
  CATextLayer *subtitleText = [[CATextLayer alloc] init];
  // Docs say this is supposed to be written for layer statement
  subtitleText.contentsScale = [[UIScreen mainScreen] scale];
  NSString *text = [textInfo objectForKey:@"text"];

  if ([text length] != 0) {
    // font指定
    [subtitleText setFont:@"GenEiGothicM-R"];
    // fontSizeを指定
    NSNumber *fontSizeNumber = [textInfo objectForKey:@"fontSize"];
    NSInteger fontSize = abs(fontSizeNumber.integerValue);

    // fontSizeを指定
    NSNumber *fontSizeLandscapeNumber = [textInfo objectForKey:@"fontSizeLandscape"];
    NSInteger fontSizeLandscape = abs(fontSizeLandscapeNumber.integerValue);

    // fontの指定
    UIFont *font = [UIFont fontWithName:@"GenEiGothicM-R" size:fontSize];
    CGSize textSize = [text sizeWithFont:font];

    // fontの指定
    UIFont *fontLandscape = [UIFont fontWithName:@"GenEiGothicM-R" size:fontSizeLandscape];
    CGSize textSizeLandscape = [text sizeWithFont:fontLandscape];

    // 位置指定 portrait, landscapeで向きが異なる
    NSNumber *topN = [textInfo objectForKey:@"top"];
    NSNumber *leftN = [textInfo objectForKey:@"left"];

    // 位置指定 portrait, landscapeで向きが異なる
    NSNumber *topNLandscape = [textInfo objectForKey:@"topLandscape"];
    NSNumber *leftNLandscape = [textInfo objectForKey:@"leftLandscape"];

    // 行数の指定
    NSNumber *lineNumber = [textInfo objectForKey:@"lineNum"];
    NSInteger lineNum = abs(lineNumber.intValue);

    NSNumber *maxLengthNumber = [textInfo objectForKey:@"maxLength"];
    NSInteger maxLength = abs(maxLengthNumber.intValue);

    NSNumber *textNumber = [textInfo objectForKey:@"textNum"];
    NSInteger textNum = abs(textNumber.intValue);



    // font sizeをポイントで指定
    if (isBaseVideoPortrait) {
      [subtitleText setFontSize:font.pointSize];
    } else {
      [subtitleText setFontSize:fontLandscape.pointSize];
    }  

    // 文字入力エリアの用意
    // textNumが0の可能性があるから、それで割るとエラーがでる
    NSNumber *istextInfoVertical = [textInfo objectForKey:@"vertical"];
    if ([istextInfoVertical integerValue] == 1) {
      if (isBaseVideoPortrait) { // portrait
        [subtitleText setFrame:CGRectMake(leftN.integerValue + fontSize / 6, topN.integerValue + fontSize / 6, textSize.width / textNum * lineNum, textSize.height * maxLength)];
      } else {  // vertical
        [subtitleText setFrame:CGRectMake(leftNLandscape.integerValue + fontSizeLandscape / 6, topNLandscape.integerValue + fontSizeLandscape / 6, textSizeLandscape.width / textNum * lineNum, textSizeLandscape.height * maxLength)];
      }
    } else {
      if (isBaseVideoPortrait) {  // portrait
        [subtitleText setFrame:CGRectMake(leftN.integerValue + fontSize / 6, topNLandscape.integerValue + fontSize / 6, textSize.width / textNum * maxLength, textSize.height * lineNum)];
      } else {  // vertical
        [subtitleText setFrame:CGRectMake(leftNLandscape.integerValue + fontSizeLandscape / 6, topNLandscape.integerValue + fontSizeLandscape / 6, textSizeLandscape.width / textNum * maxLength, textSizeLandscape.height * lineNum)];
      }
    }

    // 実際のテキストの割り当て -> align left -> contents 中央
    [subtitleText setString:text];
    [subtitleText setAlignmentMode:kCAAlignmentLeft];
    [subtitleText setContentsGravity:kCAGravityCenter];

    // 文字色指定
    UIColor *textColor =
    [self colorFromHexString:[textInfo objectForKey:@"textColor"] Alpha:1.0];
    [subtitleText setForegroundColor:[textColor CGColor]];

    // 背景の透明度指定
    NSNumber *backgroundOpacityNumber = [textInfo objectForKey:@"backgroundOpacity"];
    float alpha = backgroundOpacityNumber.floatValue;

    // 背景色の指定
    UIColor *backgroundColor = [self colorFromHexString:[textInfo objectForKey:@"backgroundColor"] Alpha:alpha];
    [subtitleText setBackgroundColor:[backgroundColor CGColor]];

    NSLog(@"Test - subtitleText.frame : %@", NSStringFromCGRect(subtitleText.frame));
    NSLog(@"Test - subtitleText.bounds: %@", NSStringFromCGRect(subtitleText.bounds));

    [layer addSublayer:subtitleText];
  }
}


/*
* options
* @type:                integer  required [0,1]
* @data:                base64 string   required
* @text:                string   required
* @subText:             string   optional
* @fontSize:            integer  optional
* @textColor:           string   optional
* @backgroundColor:     string   optional
* @backgroundOpacity:   float    optional
* @top:                 integer  optional
* @left:                integer  optional
* @subTop:              integer  optional
* @subLeft:             integer  optional
*/
RCT_EXPORT_METHOD
(
  embedText:(NSDictionary *)options
  resolve:(RCTPromiseResolveBlock)resolve
  reject:(RCTPromiseRejectBlock)reject
)
{
  self.options = options;
  NSString *type = [self.options valueForKey:@"type"];

  if ([type isEqualToString:@"image"]) {
    [self embedTextOnImage:options resolver:resolve rejecter:reject];

  } else if ([type isEqualToString:@"video"]) {
    [self embedTextOnVideo:options resolver:resolve rejecter:reject];

  } else {
    NSError *error = [NSError errorWithDomain: @"rnmediaeditor" code:1 userInfo:nil];
    reject(@"invalid_options", @"argument options invalid type", error);
  }
}


// actually embeding text
-(void)
  embedTextOnImage:(NSDictionary *)options
  resolver:(RCTPromiseResolveBlock)resolve
  rejecter:(RCTPromiseRejectBlock)reject
{
  self.options = options;
  NSDictionary *firstText = [options objectForKey:@"firstText"];
  NSDictionary *secondText = [options objectForKey:@"secondText"];

  NSString *base64str = [options objectForKey:@"data"];
  NSData *data = [[NSData alloc]
                  initWithBase64EncodedString:base64str
                  options:NSDataBase64DecodingIgnoreUnknownCharacters];
  
  // １文字目の埋め込み
  UIImage *image = [UIImage imageWithData:data];
  NSData* jpgData = [self returnJpgData:firstText image:image];

  // ２文字目の埋め込み
  UIImage *image2 = [UIImage imageWithData:jpgData];
  NSData* jpgData2 = [self returnJpgData:secondText image:image2];

  // base64 encoding 
  NSString* jpg64Str = [jpgData2 base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength];

  // 返す
  resolve(@[@"embed text on image", jpg64Str]);

}

-(void)embedTextOnVideo:(NSDictionary *)options
               resolver:(RCTPromiseResolveBlock)resolve
               rejecter:(RCTPromiseRejectBlock)reject
{
  // オリジナルはこれか：http://qiita.com/KUMAN/items/a2a1e903b26b062d2d79#%E5%8B%95%E7%94%BB%E5%90%88%E6%88%90%E3%81%AE%E6%B5%81%E3%82%8C
  // deprecateされてるの多いから要修正
  self.options = options;
  NSDictionary *firstText = [options objectForKey:@"firstText"];
  NSDictionary *secondText = [options objectForKey:@"secondText"];

  NSString *urlStr = [options objectForKey:@"path"];
  NSURL *url = [NSURL fileURLWithPath:urlStr];

  AVURLAsset *videoAsset = [AVURLAsset URLAssetWithURL:url options:nil];




  //////////////////////////////////////////////////////////////////////
  // prepare composition
  // 動画自体の操作などをするのはこいつ

  AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];

  // とってきた要素を個別のtrackを、受け取って自由に使える形で書き出し
  // ここでは、VideoとAudioを別々に取得している
  AVMutableCompositionTrack *mutableCompositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
  AVMutableCompositionTrack *mutableCompositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];

  // get immutable original tracks
  AVAssetTrack *baseVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
  AVAssetTrack *baseAudioTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
  


  // Check the first video track's preferred transform to determine if it was recorded in portrait mode.
  
  BOOL isBaseVideoPortrait = NO;
  CGAffineTransform baseVideoTransform = baseVideoTrack.preferredTransform;
  if (baseVideoTransform.a == 0 && baseVideoTransform.d == 0 && (baseVideoTransform.b == 1.0 ||
    baseVideoTransform.b == -1.0) && (baseVideoTransform.c == 1.0 || baseVideoTransform.c == -1.0))
  {
  isBaseVideoPortrait = YES;
  }

  // set size of video
  // portrait -> switch width and height
  // landscape -> do not switch width and height
  CGSize size = baseVideoTrack.naturalSize;
  if (isBaseVideoPortrait) {
    size = CGSizeMake(size.height, size.width);
  }

  // check orientation
  if (baseVideoTransform.tx == size.width && baseVideoTransform.ty == size.height) {
    NSLog(@"UIInterfaceOrientationLandscapeRight");
  } else if (baseVideoTransform.tx == 0 && baseVideoTransform.ty == 0) {
    NSLog(@"UIInterfaceOrientatonLandscapeLeft");
  } else if (baseVideoTransform.tx == 0 && baseVideoTransform.ty == size.width) {
    NSLog(@"UIInterfaceOrientationPortraitUpsideDown");
  } else {
    NSLog(@"UIInterfaceOrientationPortrait");
  }

  // 取り出した、可変のトラックに、時間の要素を追加してあげる
  // 同じように、音声にも追加してあげる
  [mutableCompositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, baseVideoTrack.timeRange.duration) ofTrack:baseVideoTrack atTime:kCMTimeZero error:nil];
  [mutableCompositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, baseAudioTrack.timeRange.duration) ofTrack:baseAudioTrack atTime:kCMTimeZero error:nil];


  //////////////////////////////////////////////////////////////////////
  // prepare instruction
  // compositionに乗せていく、個別の要素（レクタングル）を作成

  // mainの中で１つで管理
  AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];

  // 時間軸をもたせる
  mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mixComposition duration]);

  /////////////////////////////////////////////////////////////////////
  // set background color
  // こうすると、きれいな正方形でバックグラウンドカラーがつく？
/*

  UIImage *borderImage = nil;

  UIColor *videoBackgroundColor = [self colorFromHexString:@"#F6F5F4" Alpha:1.0];
  borderImage = [self imageWithColor:videoBackgroundColor rectSize:CGRectMake(-(size.height - size.width)/2, 0, size.width, size.width)];

  CALayer *backgroundLayer = [CALayer layer];
  [backgroundLayer setContents:(id)[borderImage CGImage]];
  backgroundLayer.frame = CGRectMake(0, 0, size.width, size.height);
  [backgroundLayer setMasksToBounds:YES];
*/

  // subclass of AVVideoCompositionLayerInstruction
  // this is used to modify the transform, cropping, and opacity ramps to apply to a given track in a composition.
  // mutableCompositionVideoTrack このトラックに対する、新しい mutable video composition layer instruction を作成
  AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:mutableCompositionVideoTrack];

  // Apply the original transform.
  // baseVideoTrackの向きがdefaultでportraits（横長でホームボタンじゃない方が上）
  // 縦固定で扱いたければ、全て入れかえて扱わなければいけない

  if (isBaseVideoPortrait) {
    CGAffineTransform translateToCenter = CGAffineTransformMakeTranslation(size.width, 0);  // 平行移動
    CGAffineTransform rotation = CGAffineTransformMakeRotation(M_PI_2);  // 回転作業 おっけーっぽい
    CGAffineTransform mixedTransform = CGAffineTransformConcat(rotation, translateToCenter);  // 合成
    [layerInstruction setTransform:mixedTransform atTime:kCMTimeZero];
  }

  // 特に何をしているわけでもないけど、とりあえずlayerInstructionsをもたせているのがこの時点での状況
  // このあとも出てこないから、この辺なくても良い気がする
  mainInstruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];


  /////////////////////////////////////////////
  // 残り３秒で現れる文字列の動作とlayerを作成する

  // ２つの文字を１つに合成し、表示する準備
  CALayer *overlayLayer = [CALayer layer];
  // this is supposed to write here according to docs, I don't understand completly
  overlayLayer.contentsScale = [[UIScreen mainScreen] scale];

  // define layer
  overlayLayer.frame = CGRectMake(0, 0, size.width, size.height);
  [self embedTextOnCALayer:firstText targetLayer:overlayLayer isBaseVideoPortrait:isBaseVideoPortrait size:&size];
  [self embedTextOnCALayer:secondText targetLayer:overlayLayer isBaseVideoPortrait:isBaseVideoPortrait size:&size];


  // settings for overlay layer
  [overlayLayer setMasksToBounds:YES];
  [overlayLayer setOpacity:0.0];
  [overlayLayer displayIfNeeded];
  [overlayLayer setGeometryFlipped:YES];
  

  ////////////////////////////////////////////////////
  // 埋め込む文字がどのように動作するのか決めている部分
  // 

  // set text layer to last three seconds
  CMTime videoDuration = videoAsset.duration;
  CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
  [animation setDuration:0];
  [animation setFromValue:[NSNumber numberWithFloat:0.0]];
  [animation setToValue:[NSNumber numberWithFloat:1.0]];
  [animation setBeginTime:CMTimeGetSeconds(videoDuration)-3];
  [animation setRemovedOnCompletion:NO];
  [animation setFillMode:kCAFillModeForwards];
  [overlayLayer addAnimation:animation forKey:@"animateOpacity"];
  

  /////////////////////////////////////////////////////
  // create parent layer

  CALayer *parentLayer = [CALayer layer];
  CALayer *videoLayer = [CALayer layer];

  // this is supposed to be written here, I don't understand reasons completly
  parentLayer.contentsScale = [[UIScreen mainScreen] scale];;
  videoLayer.contentsScale = [[UIScreen mainScreen] scale];;


  // 左上を原点にした座標を取得。そこを基準にする
  if (isBaseVideoPortrait) {
    parentLayer.anchorPoint = CGPointMake(0, 0);
    videoLayer.anchorPoint = CGPointMake(0, 0);
  
    // 左上を原点に、横幅 size.width, 縦幅 size.heightのレクタングル（長方形）を取得
    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
    videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
  } else {

    parentLayer.anchorPoint = CGPointMake(0, 0);
    // videoLayer.anchorPoint = CGPointMake(0, 0);
    videoLayer.anchorPoint = CGPointMake(0.5, 0.5);
  
    // 左上を原点に、横幅 size.width, 縦幅 size.heightのレクタングル（長方形）を取得
    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
    videoLayer.frame = CGRectMake(0, 0, size.width, size.height);    
  }

  // 要素をparentLayerにまとめにいく
  // ひょっとしたら使われていないけど
  // [parentLayer addSublayer:backgroundLayer];


  // 場所はちゃんとあう。必要であれば、きちんとセンターを基準にして回してあげる
  // CGAffineTransform rotateTransform = CGAffineTransformMakeRotation(M_PI);
  // CGAffineTransform translateToCenterTransform = CGAffineTransformMakeTranslation(-1*(size.height-size.width)/2, -1*(size.height-size.width)/2);  // 平行移動
  // CGAffineTransform mixedTransform = CGAffineTransformConcat(rotateTransform, translateToCenterTransform);  // 合成
  // [videoLayer setAffineTransform:rotateTransform];


  [parentLayer addSublayer:videoLayer];
  
  // 文字のlayerの上乗せ
  // parent layer回しているから、おそらく基準点ずれている
  [parentLayer addSublayer:overlayLayer];

  //////////////////////////////////////////////////////////////////////
  // create videocomposition to add textLayer on base video
  AVMutableVideoComposition *textLayerComposition = [AVMutableVideoComposition videoComposition];

  // set media sizes
  textLayerComposition.renderSize = size;
  textLayerComposition.frameDuration = CMTimeMake(1, 30);  // 1/30秒を１つの単位とする
  textLayerComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
  textLayerComposition.instructions = [NSArray arrayWithObject:mainInstruction];

  // Audioの合成パラメータオブジェクトを生成
  AVMutableAudioMixInputParameters *audioMixInputParameters;
  audioMixInputParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:mutableCompositionAudioTrack];
  [audioMixInputParameters setVolumeRampFromStartVolume:1.0
                                            toEndVolume:1.0
                                              timeRange:CMTimeRangeMake(kCMTimeZero, mixComposition.duration)];
  
  /////////////////////////////////////////////////////////////////////////////
  // 手順8
  
  // AVMutableAudioMixを生成
  AVMutableAudioMix *mutableAudioMix = [AVMutableAudioMix audioMix];
  mutableAudioMix.inputParameters = @[audioMixInputParameters];


  // static date formatter
  static NSDateFormatter *kDateFormatter;
  kDateFormatter = [[NSDateFormatter alloc] init];
  [kDateFormatter setDateFormat:@"yyyyMMddHHmmss"];


  ////////////////////////////////////////
  // check component positons

  NSLog(@"Test - parentLayer.frame : %@", NSStringFromCGRect(parentLayer.frame));
  NSLog(@"Test - parentLayer.bounds: %@", NSStringFromCGRect(parentLayer.bounds));

  //cview2のframeとboundsを出力
  NSLog(@"Test - videoLayer.frame : %@", NSStringFromCGRect(videoLayer.frame));
  NSLog(@"Test - videoLayer.bounds: %@", NSStringFromCGRect(videoLayer.bounds));

  //cview2のframeとboundsを出力
  NSLog(@"Test - overlayLayer.frame : %@", NSStringFromCGRect(overlayLayer.frame));
  NSLog(@"Test - overlayLayer.bounds: %@", NSStringFromCGRect(overlayLayer.bounds));

  //cview2のframeとboundsを出力
  NSLog(@"Test - textLayer.frame : %@", NSStringFromCGRect(videoLayer.frame));
  NSLog(@"Test - textLayer.bounds: %@", NSStringFromCGRect(videoLayer.bounds));

  // 画面情報諸々を出力
  // scaleを計算してログで出力
  UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
  BOOL landscape = (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight);
  NSLog(@"Test -Currently landscape: %@, width: %.2f, height: %.2f",
         (landscape ? @"Yes" : @"No"),
         [[UIScreen mainScreen] bounds].size.width,
         [[UIScreen mainScreen] bounds].size.height);
    
    
  ////////////////////////////////////////////////////////////////////////
  // export AVComposition to CameraRoll
  AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];

  exporter.videoComposition = textLayerComposition;
  exporter.audioMix = mutableAudioMix;
  
  exporter.outputURL = [[[[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:@YES error:nil] URLByAppendingPathComponent:[kDateFormatter stringFromDate:[NSDate date]]] URLByAppendingPathExtension:CFBridgingRelease(UTTypeCopyPreferredTagWithClass((CFStringRef)AVFileTypeMPEG4, kUTTagClassFilenameExtension))];

  exporter.outputFileType = AVFileTypeMPEG4;
  exporter.shouldOptimizeForNetworkUse = YES;

  [exporter exportAsynchronouslyWithCompletionHandler:^{
      ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
      if ([assetsLibrary videoAtPathIsCompatibleWithSavedPhotosAlbum:exporter.outputURL]) {
        [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:exporter.outputURL completionBlock:^(NSURL *assetURL, NSError *assetError){
          if (assetURL) {
            NSLog(@"output: %@", assetURL.absoluteString);
          }
          resolve(@{@"path": exporter.outputURL.absoluteString, @"assetPath": assetURL.absoluteString});
        }];
      }
  }];

}


@end
