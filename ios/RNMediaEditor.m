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
  UIImage *image = [UIImage imageWithData:data];


  NSNumber *fontSizeNumber = [firstText objectForKey:@"fontSize"];
  NSInteger fontSize = abs(fontSizeNumber.intValue);
  
  NSNumber *lineNumber1 = [firstText objectForKey:@"lineNum"];
  NSInteger lineNum1 = abs(lineNumber1.intValue);

  UIColor *textColor =
    [self colorFromHexString:[firstText objectForKey:@"textColor"] Alpha:1.0];

  NSNumber *backgroundOpacityNumber = [firstText objectForKey:@"backgroundOpacity"];
  float backgroundOpacity = backgroundOpacityNumber.floatValue;

  UIColor *backgroundColor =
    [self colorFromHexString:[firstText objectForKey:@"backgroundColor"] Alpha:backgroundOpacity];

  NSNumber *topNumber = [firstText objectForKey:@"top"];
  NSNumber *leftNumber = [firstText objectForKey:@"left"];
  CGFloat top = topNumber.floatValue;
  CGFloat left = leftNumber.floatValue;

  NSString *text = [firstText objectForKey:@"text"];

  // create font and size of font
  UIFont *font = [UIFont boldSystemFontOfSize:fontSize];
  CGSize size = [text sizeWithFont:font];

  // create rect of image
  UIGraphicsBeginImageContext(image.size);
  [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];

  // wrapper rect
  CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);

  // the base point of text rect
  CGPoint point = CGPointMake(left, top);


  [backgroundColor set];

  NSNumber *isFirstTextVertical = [firstText objectForKey:@"vertical"];

  CGRect textContainer;
  CGRect textRect;
  if ([isFirstTextVertical integerValue] == 1) {
    NSLog(@"Vertical string");
    textContainer = CGRectMake(point.x, point.y, size.height * lineNum1, size.height * (text.length + 1) / 2);
    CGContextFillRect(
      UIGraphicsGetCurrentContext(),
      textContainer
    );
    textRect = CGRectMake(point.x + fontSize/(lineNum1 + 1), point.y + size.height / 4, size.height * lineNum1, size.height * text.length);
  } else {
    textContainer = CGRectMake(point.x, point.y, size.width + fontSize * 1, size.height * lineNum1 * 1.5);
    CGContextFillRect(
      UIGraphicsGetCurrentContext(),
      textContainer
    );
    textRect = CGRectMake(point.x + fontSize/(lineNum1 + 1), point.y + textContainer.size.height / 4, size.width, size.height * lineNum1);
  }

  [textColor set];
  [text drawInRect:textRect
          withFont:font
     lineBreakMode:UILineBreakModeClip
         alignment:UITextAlignmentLeft ];

  UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  NSData* jpgData = [[NSData alloc] initWithData:UIImageJPEGRepresentation(newImage, 1.0f)];
  UIImage *image2 = [UIImage imageWithData:jpgData];


  // again to second text
  NSNumber *fontSizeNumber2 = [secondText objectForKey:@"fontSize"];
  NSInteger fontSize2 = abs(fontSizeNumber2.intValue);

  NSNumber *lineNumber2 = [secondText objectForKey:@"lineNum"];
  NSInteger lineNum2 = abs(lineNumber2.intValue);

  UIColor *textColor2 =
  [self colorFromHexString:[secondText objectForKey:@"textColor"] Alpha:1.0];

  NSNumber *backgroundOpacityNumber2 = [secondText objectForKey:@"backgroundOpacity"];
  float backgroundOpacity2 = backgroundOpacityNumber2.floatValue;

  UIColor *backgroundColor2 =
  [self colorFromHexString:[secondText objectForKey:@"backgroundColor"] Alpha:backgroundOpacity2];

  NSNumber *topNumber2 = [secondText objectForKey:@"top"];
  NSNumber *leftNumber2 = [secondText objectForKey:@"left"];
  CGFloat top2 = topNumber2.floatValue;
  CGFloat left2 = leftNumber2.floatValue;

  NSString *text2 = [secondText objectForKey:@"text"];

  // create font and size of font
  UIFont *font2 = [UIFont boldSystemFontOfSize:fontSize2];
  CGSize size2 = [text2 sizeWithFont:font2];

  // create rect of image
  UIGraphicsBeginImageContext(image.size);
  [image2 drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];

  // wrapper rect
  CGRect rect2 = CGRectMake(0, 0, image.size.width, image.size.height);

  // the base point of text rect
  CGPoint point2 = CGPointMake(left2, top2);
  [backgroundColor2 set];

  CGRect textContainer2;
  CGRect textRect2;
  NSNumber *isSecondTextVertical = [secondText objectForKey:@"vertical"];

  if ([isSecondTextVertical integerValue] == 1) {
    NSLog(@"Vertical string");
    textContainer2 = CGRectMake(point2.x, point2.y, size2.height * lineNum2, size2.height * (text2.length + 1) / 2);
    CGContextFillRect(
      UIGraphicsGetCurrentContext(),
      textContainer2
    );
    textRect2 = CGRectMake(point2.x + fontSize2/(lineNum2 + 1), point2.y + size.height / 4, size.height * lineNum2, size.height * text.length);
  } else {
    textContainer2 = CGRectMake(point2.x, point2.y, size.width + fontSize2 * 1, size.height * lineNum2 * 1.5);
    CGContextFillRect(
      UIGraphicsGetCurrentContext(),
      textContainer2
    );
    textRect2 = CGRectMake(point2.x + fontSize2/(lineNum2 + 1), point2.y + textContainer2.size.height / 4, size.width, size.height * lineNum2);
  }

  [textColor2 set];
  [text2 drawInRect:textRect2
          withFont:font2
     lineBreakMode:UILineBreakModeClip
         alignment:UITextAlignmentLeft ];


  UIImage *newImage2 = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  NSData* jpgData2 = [[NSData alloc] initWithData:UIImageJPEGRepresentation(newImage2, 1.0f)];
  NSString* jpg64Str = [jpgData2 base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength];


  resolve(@[@"embed text on image", jpg64Str]);
}





-(void)embedTextOnVideo:(NSDictionary *)options
               resolver:(RCTPromiseResolveBlock)resolve
               rejecter:(RCTPromiseRejectBlock)reject
{
  // オリジナルはこれか：http://qiita.com/KUMAN/items/a2a1e903b26b062d2d79#%E5%8B%95%E7%94%BB%E5%90%88%E6%88%90%E3%81%AE%E6%B5%81%E3%82%8C
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

  // 変更不可能な、オリジナルのトラックを取得
  AVAssetTrack *baseVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
  AVAssetTrack *baseAudioTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
  
  // とった動画のwidth / height を取得
  CGSize size = baseVideoTrack.naturalSize;

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

  // subclass of AVVideoCompositionLayerInstruction
  // this is used to modify the transform, cropping, and opacity ramps to apply to a given track in a composition.
  // mutableCompositionVideoTrack このトラックに対する、新しい mutable video composition layer instruction を作成
  AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:mutableCompositionVideoTrack];

  // 回転試行錯誤その１
  // Apply the original transform.
  // baseVideoTrackの向きがもともとportraitsだったら、これは結局向きが変わらない
  // 変わらないから、localに保存された時点で向きが変わっちゃっている

  size = CGSizeMake(size.height, size.width);  // 左上を、縦表示の時の位置に移動？
  CGAffineTransform translateToCenter = CGAffineTransformMakeTranslation(size.width, 0);  // 平行移動
  CGAffineTransform rotation = CGAffineTransformMakeRotation(M_PI_2);  // 回転作業 おっけーっぽい
  CGAffineTransform mixedTransform = CGAffineTransformConcat(rotation, translateToCenter);  // 合成
  [layerInstruction setTransform:mixedTransform atTime:kCMTimeZero];


  // 特に何をしているわけでもないけど、とりあえずlayerInstructionsをもたせているのがこの時点での状況
  // このあとも出てこないから、この辺なくても良い気がする
  mainInstruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];


  ///////////////////////////////////////////////////////////////////////////////////
  // create font and size of font
  
  // create text1
  CATextLayer *subtitle1Text = [[CATextLayer alloc] init];
  subtitle1Text.contentsScale = [[UIScreen mainScreen] scale];
  NSString *text1 = [firstText objectForKey:@"text"];

  // font指定
  [subtitle1Text setFont:@"GenEiGothicM-R"];
  // fontSizeを指定
  NSNumber *fontSizeNumber1 = [firstText objectForKey:@"fontSize"];
  NSInteger fontSize1 = abs(fontSizeNumber1.integerValue * 0.5);

  // fontの指定
  UIFont *font1 = [UIFont fontWithName:@"GenEiGothicM-R" size:fontSize1];
  CGSize textSize1 = [text1 sizeWithFont:font1];

  // 位置指定
  NSNumber *topN1 = [firstText objectForKey:@"top"];
  NSNumber *leftN1 = [firstText objectForKey:@"left"];

  // 行数の指定
  NSNumber *lineNumber1 = [firstText objectForKey:@"lineNum"];
  NSInteger lineNum1 = abs(lineNumber1.intValue);

  // font sizeをポイントで指定
  [subtitle1Text setFontSize:font1.pointSize];
  

  // 文字入力エリアの用意
  NSNumber *isFirstTextVertical = [firstText objectForKey:@"vertical"];
  if ([isFirstTextVertical integerValue] == 1) {
    // [subtitle1Text setFrame:CGRectMake(leftN1.integerValue, size.height - topN1.integerValue, textSize1.height * lineNum1, textSize1.width)];
    // [subtitle1Text setFrame:CGRectMake(leftN1.integerValue,  topN1.integerValue, textSize1.height * lineNum1, textSize1.width)];
    [subtitle1Text setFrame:CGRectMake(0, 0, textSize1.height * lineNum1, textSize1.width)];
  } else {
    // [subtitle1Text setFrame:CGRectMake(leftN1.integerValue, size.height - topN1.integerValue, textSize1.width, textSize1.height * lineNum1)];
    // [subtitle1Text setFrame:CGRectMake(leftN1.integerValue, topN1.integerValue, textSize1.width, textSize1.height * lineNum1)];
    [subtitle1Text setFrame:CGRectMake(0, 0, textSize1.width, textSize1.height * lineNum1)];
  }

  // 実際のテキストの割り当て -> align left -> contents 中央
  [subtitle1Text setString:text1];
  [subtitle1Text setAlignmentMode:kCAAlignmentLeft];
  [subtitle1Text setContentsGravity:kCAGravityCenter];

  // 文字色指定
  UIColor *textColor1 =
  [self colorFromHexString:[firstText objectForKey:@"textColor"] Alpha:1.0];
  [subtitle1Text setForegroundColor:[textColor1 CGColor]];

  // 背景の透明度指定
  NSNumber *backgroundOpacityNumber1 = [firstText objectForKey:@"backgroundOpacity"];
  float alpha1 = backgroundOpacityNumber1.floatValue;

  // 背景色の指定
  UIColor *backgroundColor1 = [self colorFromHexString:[firstText objectForKey:@"backgroundColor"] Alpha:alpha1];
  [subtitle1Text setBackgroundColor:[backgroundColor1 CGColor]];


  ///////////////////////////////////////////////////////////////
  // create text2
  // same things to do
  CATextLayer *subtitle2Text = [[CATextLayer alloc] init];
  subtitle2Text.contentsScale = [[UIScreen mainScreen] scale];;

  // frame作らなくていいの？
  
  UIColor *color = [UIColor whiteColor];
  NSString *text2 = [secondText objectForKey:@"text"];

  // create font and size of font
  [subtitle2Text setFont:@"GenEiGothicM-R"];
  NSNumber *fontSizeNumber2 = [secondText objectForKey:@"fontSize"];
  NSInteger fontSize2 = abs(fontSizeNumber2.integerValue * 0.5);
  NSNumber *isSecondTextVertical = [secondText objectForKey:@"vertical"];
  UIFont *font2 = [UIFont fontWithName:@"GenEiGothicM-R" size:fontSize2];
  CGSize textSize2 = [text2 sizeWithFont:font2];
  NSNumber *topN2 = [secondText objectForKey:@"top"];
  NSNumber *leftN2 = [secondText objectForKey:@"left"];

  NSNumber *lineNumber2 = [secondText objectForKey:@"lineNum"];
  NSInteger lineNum2 = abs(lineNumber2.intValue);

  [subtitle2Text setFontSize:(font2.pointSize / 2)];

  // TODO 文字の場所をコントロールする
  // lineNumを考慮した値をtextSizeが返してくれるか確認
  if ([isSecondTextVertical integerValue] == 1) {
    // [subtitle2Text setFrame:CGRectMake(leftN2.integerValue, size.height - topN2.integerValue, textSize2.height, textSize2.width * lineNum2)];
    [subtitle2Text setFrame:CGRectMake(0, 0, textSize2.height, textSize2.width * lineNum2)];
    // [subtitle2Text setFrame:CGRectMake(leftN2.integerValue, topN2.integerValue, textSize2.height, textSize2.width)];
  } else {
    // [subtitle2Text setFrame:CGRectMake(leftN2.integerValue, size.height - topN2.integerValue, textSize2.width * lineNum2, textSize2.height)];
    [subtitle2Text setFrame:CGRectMake(0, 0, textSize2.height, textSize2.width * lineNum2)];
    // [subtitle2Text setFrame:CGRectMake(leftN2.integerValue, topN2.integerValue, textSize2.width, textSize2.height)];
  }

  [subtitle2Text setString:text2];  // 文字の埋め込み
  [subtitle2Text setAlignmentMode:kCAAlignmentLeft]; // 文字のalignの位置を決めているだけ

  // 文字色の指定
  UIColor *textColor2 =
  [self colorFromHexString:[secondText objectForKey:@"textColor"] Alpha:1.0];
  [subtitle2Text setForegroundColor:[textColor2 CGColor]];  // 色を指定

  // Opacityの指定
  NSNumber *backgroundOpacityNumber2 = [secondText objectForKey:@"backgroundOpacity"];
  float alpha2 = backgroundOpacityNumber2.floatValue;

  // 背景色の指定
  UIColor *backgroundColor2 = [self colorFromHexString:[secondText objectForKey:@"backgroundColor"] Alpha:alpha2];
  [subtitle2Text setBackgroundColor:[backgroundColor2 CGColor]];

  // end create text2
  /////////////////////////////////////////////
 

  /////////////////////////////////////////////
  // 残り３秒で現れる文字列の動作とlayerを作成する

  // ２つの文字を１つに合成し、表示する準備
  CALayer *overlayLayer = [CALayer layer];

  // 幅を指定: 画面一杯
  overlayLayer.frame = CGRectMake(0, 0, size.width, size.height);
  [overlayLayer addSublayer:subtitle1Text];
  [overlayLayer addSublayer:subtitle2Text];
  [overlayLayer setMasksToBounds:YES];
  [overlayLayer setOpacity:0.0];
  [overlayLayer displayIfNeeded];
  // [overlayLayer setGeometryFlipped:YES];
  

  ////////////////////////////////////////////////////
  // 埋め込む文字がどのように動作するのか決めている部分
  // 

  // 後ろから３秒に入れ込むために、長さを指定
  CMTime videoDuration = videoAsset.duration;
  CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
  [animation setDuration:0];
  [animation setFromValue:[NSNumber numberWithFloat:0.0]];
  [animation setToValue:[NSNumber numberWithFloat:1.0]];
  [animation setBeginTime:CMTimeGetSeconds(videoDuration)-3];  // 最後から３秒で開始
  [animation setRemovedOnCompletion:NO];
  [animation setFillMode:kCAFillModeForwards];
  [overlayLayer addAnimation:animation forKey:@"animateOpacity"];
  

  /////////////////////////////////////////////////////
  // create parent layer
  // この２つのlayerなくても何にも問題ないはず

  CALayer *parentLayer = [CALayer layer];
  CALayer *videoLayer = [CALayer layer];

  // 左上を原点にした座標を取得。そこを基準にする
  parentLayer.anchorPoint = CGPointMake(0, 0);
  videoLayer.anchorPoint = CGPointMake(0, 0);
  
  // 左上を原点に、横幅 size.width, 縦幅 size.heightのレクタングル（長方形）を取得
  parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
  videoLayer.frame = CGRectMake(0, 0, size.width, size.height);


/*
  // 下二つは表示されないから、videoLayerは動画の合成の際には使われてない layer??

  // おれんじ！
  UIColor *parentLayerColor = [self colorFromHexString:@"#f98829" Alpha:alpha2];
  [parentLayer setBackgroundColor:[parentLayerColor CGColor]];

  // 青っぽい色
  UIColor *videoLayerColor = [self colorFromHexString:@"#1c1321" Alpha:alpha2];
  [videoLayer setBackgroundColor:[videoLayerColor CGColor]];
*/

  // red
  UIColor *overlayLayerColor = [self colorFromHexString:@"#ca2e39" Alpha:alpha2];
  [overlayLayer setBackgroundColor:[overlayLayerColor CGColor]];

  // 要素をparentLayerにまとめにいく
  // ひょっとしたら使われていないけど
  [parentLayer addSublayer:videoLayer];
  [parentLayer addSublayer:overlayLayer];

  // create videocomposition to add textLayer on base video
  AVMutableVideoComposition *textLayerComposition = [AVMutableVideoComposition videoComposition];
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
