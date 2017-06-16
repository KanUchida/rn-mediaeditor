package com.rnmediaeditor;

import android.graphics.Bitmap;
import android.graphics.Matrix;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.Typeface;
import android.content.Context;
import android.app.Activity;
import android.content.res.AssetManager;
import android.os.Environment;
import android.provider.MediaStore;
import android.support.annotation.Nullable;
import android.support.annotation.RequiresPermission;
import android.support.annotation.StringDef;
import android.util.Log;
import android.util.Base64;
import android.text.Layout;
import android.text.StaticLayout;
import android.text.TextPaint;
import android.text.Layout.Alignment;
import android.media.ExifInterface;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.github.hiteshsondhi88.libffmpeg.ExecuteBinaryResponseHandler;
import com.github.hiteshsondhi88.libffmpeg.FFmpeg;
import com.github.hiteshsondhi88.libffmpeg.LoadBinaryResponseHandler;
import com.github.hiteshsondhi88.libffmpeg.exceptions.FFmpegCommandAlreadyRunningException;
import com.github.hiteshsondhi88.libffmpeg.exceptions.FFmpegNotSupportedException;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.text.SimpleDateFormat;
import java.util.Date;


public class RNMediaEditorModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext _reactContext;
  private static final String TAG = "RNMediaEditorModule";

  public static final int TYPE_IMAGE = 1;
  public static final int TYPE_VIDEO = 2;

  public static Promise _promise;
  public WritableMap _result;

  public RNMediaEditorModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this._reactContext = reactContext;
  }

  @Override
  public String getName() {
    return "RNMediaEditor";
  }

  @ReactMethod
  public void embedText(final ReadableMap options, Promise promise) {
    String type = options.getString("type");
    copyAssets();
    if (type.equals("image")) {
      Log.d("Example", "RNMediaeditor embed text on image called");
      embedTextOnImage(options, promise);
    } else if (type.equals("video")) {
      embedTextOnVideo(options, promise);
    }
  }


  public Typeface customTypeFace(Context context, String fontName) {
    AssetManager manager = context.getAssets();
    String fileName = "";
    if (fontName.equals("SourceHanSerif-Bold")) {
      fileName = "fonts/" + fontName + ".otf";
    } else {
      fileName = "fonts/" + fontName + ".ttf";
    }

    try {
      String[] list = manager.list("fonts");
      Log.d("example", "getAssets=" + list);
    } catch(IOException e) {
      System.err.println(e.getMessage());
    }

    Typeface custom_font = Typeface.createFromAsset(manager, fileName);
    return custom_font;
  }

  private void embedTextOnImage(final ReadableMap options, final Promise promise) {
    // decode input base64 string to bitmap
    String rawData = options.getString("data");
    byte[] decodedBytes = Base64.decode(rawData, Base64.DEFAULT);
    Context context = getReactApplicationContext();
    int scale = (int)options.getDouble("scale");

    // 回転の情報を取得(pathから)

    Bitmap bitmap = BitmapFactory.decodeByteArray(decodedBytes, 0, decodedBytes.length);
    // Log.d("Example", "orientation ", orientation);
    int i = getOrientation(options.getString("path"));
    Log.d("Example", "orientaion " + i);
    Bitmap bmRotated = rotateBitmap(bitmap, i);

    Bitmap.Config bitmapConfig = bitmap.getConfig();
    // set default config if config is none
    if (bitmapConfig == null) {
      bitmapConfig = Bitmap.Config.ARGB_8888;
    }

    bitmap = bmRotated.copy(bitmapConfig, true);
    Canvas canvas = new Canvas(bitmap); // bitmapをcanvasに渡し、編集可能にする

    // embed first text on bitmap
    ReadableMap firstText = options.getMap("firstText");

    String backgroundColor = firstText.getString("backgroundColor");
    float backgroundOpacity = (float) (firstText.getDouble("backgroundOpacity"));

    // draw text container container
    Paint containerPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    containerPaint.setColor(Color.parseColor(backgroundColor));
    containerPaint.setStyle(Paint.Style.FILL);
    int opacity = (int) (255 * backgroundOpacity);
    containerPaint.setAlpha(opacity);

    String fontColor = firstText.getString("textColor");
    int fontSize = firstText.getInt("fontSize");
    String text = firstText.getString("text");

    // draw text Paint
    TextPaint textPaint = new TextPaint();
    textPaint.setColor(Color.parseColor(fontColor));
    textPaint.setTextSize(fontSize);

    String fontFamily = firstText.getString("fontFamily");
    textPaint.setTypeface(customTypeFace(context, fontFamily));

    int top = topValue(firstText, i);
    int left = leftValue(firstText, i);


    boolean isVertical = firstText.getBoolean("vertical");
    if (isVertical) {
      // Rect textSize = new Rect();
      // textPaint.getTextBounds(text, 0, text.length(), textSize); // textが全部入るようなtextSize(Rect)を作った

      // canvas.drawRect(left, top, left + textSize.width(), top + (textSize.height() - 5) * text.length(), containerPaint); // left, top, right, bottom

      // StaticLayout mTextLayout = new StaticLayout(text, textPaint, canvas.getWidth(), Alignment.ALIGN_NORMAL, 1.0f, 0.0f, false);
      // canvas.save();
      // canvas.translate(left + textSize.height()/2, top + textSize.height()/2);
      // mTextLayout.draw(canvas);
      // canvas.restore();

      int y = top + fontSize / 2;
      for (String line: text.split("\n")) {
        canvas.drawText(line, left, y, textPaint);
        y += fontSize + 5 * scale;
      }

    } else {
      int y = top;
      for (String line: text.split("\n")) {
        canvas.drawText(line, left, y, textPaint);
        y += textPaint.descent() - textPaint.ascent();
      }
    }



    // embed first text on bitmap
    ReadableMap secondText = options.getMap("secondText");

    String backgroundColor2 = secondText.getString("backgroundColor");
    float backgroundOpacity2 = (float) (secondText.getDouble("backgroundOpacity"));

    // draw text container container
    Paint containerPaint2 = new Paint(Paint.ANTI_ALIAS_FLAG);
    containerPaint2.setColor(Color.parseColor(backgroundColor2));
    containerPaint2.setStyle(Paint.Style.FILL);
    int opacity2 = (int) (255 * backgroundOpacity2);
    containerPaint2.setAlpha(opacity2);

    String fontColor2 = secondText.getString("textColor");
    int fontSize2 = secondText.getInt("fontSize");
    String text2 = secondText.getString("text");

    // draw text Paint
    TextPaint textPaint2 = new TextPaint();
    textPaint2.setColor(Color.parseColor(fontColor2));
    textPaint2.setTextSize(fontSize2);

    String fontFamily2 = secondText.getString("fontFamily");
    textPaint2.setTypeface(customTypeFace(context, fontFamily2));

    int top2 = topValue(secondText, i);
    int left2 = leftValue(secondText, i);


    boolean isVertical2 = secondText.getBoolean("vertical");
    if (isVertical2) {
      // Rect textSize = new Rect();
      // textPaint2.getTextBounds(text2, 0, text2.length(), textSize);

      // canvas.drawRect(left2, top2, left2 + textSize.width(), top2+ (textSize.height() - 5) * text2.length(), containerPaint2); // left, top, right, bottom

      // StaticLayout mTextLayout = new StaticLayout(text2, textPaint2, canvas.getWidth(), Alignment.ALIGN_NORMAL, 1.0f, 0.0f, false);
      // canvas.save();
      // canvas.translate(left2 + textSize.height()/2, top2 + textSize.height()/2);
      // mTextLayout.draw(canvas);
      // canvas.restore();
      int y2 = top2 + fontSize2 / 2;
      for (String line: text2.split("\n")) {
        canvas.drawText(line, left2, y2, textPaint2);
        y2 += fontSize2 + 5 * scale;
      }
    } else {
      int y2 = top2;
      for (String line: text2.split("\n")) {
        canvas.drawText(line, left2, y2, textPaint2);
        y2 += textPaint2.descent() - textPaint2.ascent();
      }
    }

    ReadableMap thirdText = options.getMap("thirdText");

    String backgroundColor3 = thirdText.getString("backgroundColor");
    float backgroundOpacity3 = (float) (thirdText.getDouble("backgroundOpacity"));

    // draw text container container
    Paint containerPaint3 = new Paint(Paint.ANTI_ALIAS_FLAG);
    containerPaint3.setColor(Color.parseColor(backgroundColor3));
    containerPaint3.setStyle(Paint.Style.FILL);
    int opacity3 = (int) (255 * backgroundOpacity3);
    containerPaint3.setAlpha(opacity3);

    String fontColor3 = thirdText.getString("textColor");
    int fontSize3 = thirdText.getInt("fontSize");
    String text3 = thirdText.getString("text");

    // draw text Paint
    TextPaint textPaint3 = new TextPaint();
    textPaint3.setColor(Color.parseColor(fontColor3));
    textPaint3.setTextSize(fontSize3);

    String fontFamily3 = thirdText.getString("fontFamily");
    textPaint3.setTypeface(customTypeFace(context, fontFamily3));

    int top3 = topValue(thirdText, i);
    int left3 = leftValue(thirdText, i);


    boolean isVertical3 = thirdText.getBoolean("vertical");
    if (isVertical3) {
      // Rect textSize = new Rect();
      // textPaint3.getTextBounds(text3, 0, text3.length(), textSize);

      // canvas.drawRect(left3, top3, left3 + textSize.width(), top3+ (textSize.height() - 5) * text3.length(), containerPaint3); // left, top, right, bottom

      // StaticLayout mTextLayout = new StaticLayout(text3, textPaint3, canvas.getWidth(), Alignment.ALIGN_NORMAL, 1.0f, 0.0f, false);
      // canvas.save();
      // canvas.translate(left3 + textSize.height()/2, top3 + textSize.height()/2);
      // mTextLayout.draw(canvas);
      // canvas.restore();
      int y3= top3+ fontSize3/ 2;
      for (String line: text3.split("\n")) {
        canvas.drawText(line, left3, y3, textPaint3);
        y3 += fontSize3 + 5 * scale;
      }
    } else {
      int y3 = top3;
      for (String line: text3.split("\n")) {
        canvas.drawText(line, left3, y3, textPaint3);
        y3 += textPaint3.descent() - textPaint3.ascent();
      }
    }

    ReadableMap fourthText = options.getMap("fourthText");

    String backgroundColor4 = fourthText.getString("backgroundColor");
    float backgroundOpacity4 = (float) (fourthText.getDouble("backgroundOpacity"));

    // draw text container container
    Paint containerPaint4 = new Paint(Paint.ANTI_ALIAS_FLAG);
    containerPaint4.setColor(Color.parseColor(backgroundColor4));
    containerPaint4.setStyle(Paint.Style.FILL);
    int opacity4 = (int) (255 * backgroundOpacity4);
    containerPaint4.setAlpha(opacity4);

    String fontColor4 = fourthText.getString("textColor");
    int fontSize4 = fourthText.getInt("fontSize");
    String text4 = fourthText.getString("text");

    // draw text Paint
    TextPaint textPaint4 = new TextPaint();
    textPaint4.setColor(Color.parseColor(fontColor4));
    textPaint4.setTextSize(fontSize4);

    String fontFamily4 = fourthText.getString("fontFamily");
    textPaint4.setTypeface(customTypeFace(context, fontFamily4));

    int top4 = topValue(fourthText, i);
    int left4 = leftValue(fourthText, i);


    boolean isVertical4 = fourthText.getBoolean("vertical");
    if (isVertical4) {
      // Rect textSize = new Rect();
      // textPaint4.getTextBounds(text4, 0, text4.length(), textSize);

      // canvas.drawRect(left4, top4, left4 + textSize.width(), top4+ (textSize.height() - 5) * text4.length(), containerPaint4); // left, top, right, bottom

      // StaticLayout mTextLayout = new StaticLayout(text4, textPaint4, canvas.getWidth(), Alignment.ALIGN_NORMAL, 1.0f, 0.0f, false);
      // canvas.save();
      // canvas.translate(left4 + textSize.height()/2, top4 + textSize.height()/2);
      // mTextLayout.draw(canvas);
      // canvas.restore();
      int y4= top4+ fontSize4/ 2;
      for (String line: text4.split("\n")) {
        canvas.drawText(line, left4, y4, textPaint4);
        y4 += fontSize4 + 5 * scale;
      }
    } else {
      int y4 = top4;
      for (String line: text4.split("\n")) {
        canvas.drawText(line, left4, y4, textPaint4);
        y4 += textPaint4.descent() - textPaint4.ascent();
      }
    }


    // output
    ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
    bitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream);
    byte[] byteArray = byteArrayOutputStream.toByteArray();

    String encoded = Base64.encodeToString(byteArray, Base64.DEFAULT);


    WritableMap map = Arguments.createMap();
    // storeImage(bitmap);

    map.putString("data", encoded);
    map.putInt("orientation", i);
    map.putString("message", "success");
    promise.resolve(map);
  }

  private void storeImage(Bitmap image) {
    File pictureFile = getOutputFile(1);
    if (pictureFile == null) {
      Log.d(TAG, "Error creating media file, check storage permissions: ");
      return;
    }
    try {
      FileOutputStream fos = new FileOutputStream(pictureFile);
      image.compress(Bitmap.CompressFormat.PNG, 90, fos);
      fos.close();
    } catch (FileNotFoundException e) {
      Log.d(TAG, "File not found: " + e.getMessage());
    } catch (IOException e) {
      Log.d(TAG, "Error accessing file: " + e.getMessage());
    }
  }

  @Nullable
  private Throwable writeDataToFile(byte[] data, File file) {
    try {
      FileOutputStream fos = new FileOutputStream(file);
      fos.write(data);
      fos.close();
    } catch (FileNotFoundException e) {
      return e;
    } catch (IOException e) {
      return e;
    }

    return null;
  }

  @Nullable
  private File getOutputFile(int type) {
    File storageDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM);

    // Create storage dir if it does not exist
    if (!storageDir.exists()) {
      if (!storageDir.mkdirs()) {
        Log.e(TAG, "Failed to create directory:" + storageDir.getAbsolutePath());
        return null;
      }
    }

    // media file name
    String fileName = String.format("%s", new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date()));


    if (type == TYPE_IMAGE) {
      fileName = String.format("IMG_%s.jpg", fileName);
    } else if (type == TYPE_VIDEO) {
      fileName = String.format("VID_%s.mp4", fileName);
    } else {
      Log.e(TAG, "Unsupported media type:" + type);
      return null;
    }
    Log.d("example", String.format("%s%s%s", storageDir.getPath(), File.separator, fileName));

    return new File(String.format("%s%s%s", storageDir.getPath(), File.separator, fileName));
  }

  public String customFont(Context context, String fontName) {
    String cpath = context.getFilesDir().getAbsolutePath() + "/";
    Log.d("example", "cpath" + cpath);
    return cpath;
  }



  public void embedTextOnVideo(ReadableMap options, Promise promise) {
    this._promise = promise;
    Context context = getReactApplicationContext();
    Log.d("example", "filepath=" + context.getExternalFilesDir(null));
    String storagePath = context.getExternalFilesDir(null).toString();


    FFmpeg ffmpeg = FFmpeg.getInstance(_reactContext);
    try {
      ffmpeg.loadBinary(new LoadBinaryResponseHandler() {

        @Override
        public void onStart() {
        }

        @Override
        public void onFailure() {
        }

        @Override
        public void onSuccess() {
        }

        @Override
        public void onFinish() {
        }
      });
    } catch (FFmpegNotSupportedException e) {
      // Handle if FFmpeg is not supported by device
    }

    String path = options.getString("path");
    double duration = options.getDouble("duration");
    int scale = (int)options.getDouble("scale");

    ReadableMap firstText = options.getMap("firstText");
    String text = firstText.getString("text");
    String fontColor = firstText.getString("textColor");
    String backgroundColor = firstText.getString("backgroundColor");
    int fontSize = (int)firstText.getDouble("fontSize");
    float backgroundOpaciy = (float)firstText.getDouble("backgroundOpacity");
    int top = (int)firstText.getDouble("top");
    int left = (int)firstText.getDouble("left");
    boolean isVertical = firstText.getBoolean("vertical");
    String fontFamily1 = firstText.getString("fontFamily");

    ReadableMap secondText = options.getMap("secondText");
    String text2 = secondText.getString("text");
    String fontColor2 = secondText.getString("textColor");
    String backgroundColor2 = secondText.getString("backgroundColor");
    int fontSize2 = (int)secondText.getDouble("fontSize");
    float backgroundOpaciy2 = (float)secondText.getDouble("backgroundOpacity");
    int top2 = (int)secondText.getDouble("top");
    int left2 = (int)secondText.getDouble("left");
    boolean isVertical2 = secondText.getBoolean("vertical");
    String fontFamily2 = secondText.getString("fontFamily");

    ReadableMap thirdText = options.getMap("thirdText");
    String text3 = thirdText.getString("text");
    String fontColor3 = thirdText.getString("textColor");
    String backgroundColor3 = thirdText.getString("backgroundColor");
    int fontSize3 = (int)thirdText.getDouble("fontSize");
    float backgroundOpaciy3 = (float)thirdText.getDouble("backgroundOpacity");
    int top3 = (int)thirdText.getDouble("top");
    int left3 = (int)thirdText.getDouble("left");
    boolean isVertical3 = thirdText.getBoolean("vertical");
    String fontFamily3 = thirdText.getString("fontFamily");

    ReadableMap fourthText = options.getMap("fourthText");
    String text4 = fourthText.getString("text");
    String fontColor4 = fourthText.getString("textColor");
    String backgroundColor4 = fourthText.getString("backgroundColor");
    int fontSize4 = (int)fourthText.getDouble("fontSize");
    float backgroundOpaciy4 = (float)fourthText.getDouble("backgroundOpacity");
    int top4 = (int)fourthText.getDouble("top");
    int left4 = (int)fourthText.getDouble("left");
    boolean isVertical4 = fourthText.getBoolean("vertical");
    String fontFamily4 = fourthText.getString("fontFamily");

    File out = getOutputFile(TYPE_VIDEO);

    // rotate情報取得
    String[] cmd1 = new String[] {
      "ffprobe", "-show_streams", "-print_format", "json", "-show_format", "-show_streams", ""
    };

    String paintText1 = "";
    int y1 = top;
    if (!isVertical) {
      y1 = top + fontSize / 2;
    }
    String extension1 = ".ttf";
    if (fontFamily1.equals("SourceHanSerif-Bold")) {
      extension1 = ".otf";
    }
    String fontStyle1 = storagePath + "/" + fontFamily1 + extension1;
    for (String line: text.split("\n")) {
      if (line.length() > 0) {
        String str = "drawtext=enable='between(t," + (duration-3) + "," + duration + ")'" + ":fontfile=" + fontStyle1 + ":text=" + line + ":x=" + left + ":y=" + y1 + "-max_glyph_a/2" + ":fontcolor=" + fontColor + ":fontsize=" + fontSize + ",";
        paintText1 += str;
      }
      y1 += fontSize + scale * 5;
    }

    String paintText2 = "";
    int y2 = top2;
    if (!isVertical2) {
      y2 = top2 + fontSize2 / 2;
    }
    String extension2 = ".ttf";
    if (fontFamily2.equals("SourceHanSerif-Bold")) {
      extension2 = ".otf";
    }
    String fontStyle2 = storagePath + "/" + fontFamily2 + extension2;
    for (String line: text2.split("\n")) {
      if (line.length() > 0) {
        String str = "drawtext=enable='between(t," + (duration-3) + "," + duration + ")'" + ":fontfile=" + fontStyle2 + ":text=" + line + ":x=" + left2 + ":y=" + y2 + "-max_glyph_a/2" + ":fontcolor=" + fontColor2 + ":fontsize=" + fontSize2 + ",";
        paintText2 += str;
      }
      y2 += fontSize2 + scale * 5;
    }

    String paintText3 = "";
    int y3 = top3;
    if (!isVertical3) {
      y3 = top3 + fontSize3 / 2;
    }
    String extension3 = ".ttf";
    if (fontFamily3.equals("SourceHanSerif-Bold")) {
      extension3 = ".otf";
    }
    String fontStyle3 = storagePath + "/" + fontFamily3 + extension3;
    for (String line: text3.split("\n")) {
      if (line.length() > 0) {
        String str = "drawtext=enable='between(t," + (duration-3) + "," + duration + ")'" + ":fontfile=" + fontStyle3 + ":text=" + line + ":x=" + left3 + ":y=" + y3 + "-max_glyph_a/2" + ":fontcolor=" + fontColor3 + ":fontsize=" + fontSize3 + ",";
        paintText3 += str;
      }
      y3 += fontSize3 + scale * 5;
    }

    String paintText4 = "";
    int y4 = top4;
    if (!isVertical4) {
      y4 = top4 + fontSize4 / 2;
    }
    String extension4 = ".ttf";
    if (fontFamily4.equals("SourceHanSerif-Bold")) {
      extension4 = ".otf";
    }
    String fontStyle4 = storagePath + "/" + fontFamily4 + extension4;
    for (String line: text4.split("\n")) {
      if (line.length() > 0) {
        String str = "drawtext=enable='between(t," + (duration-3) + "," + duration + ")'" + ":fontfile=" + fontStyle4 + ":text=" + line + ":x=" + left4 + ":y=" + y4 + "-max_glyph_a/2" + ":fontcolor=" + fontColor4 + ":fontsize=" + fontSize4 + ",";
        paintText4 += str;
      }
      y4 += fontSize4 + scale * 5;
    }

    String paintText = paintText1 + paintText2 + paintText3 + paintText4;
    Log.d("example", "paintText=" + paintText);


    String[] cmd = new String[] {
            "-i", path, "-c:v", "libx264", "-preset", "ultrafast", "-filter_complex",
            paintText.substring(0,paintText.length() - 1), out.getAbsolutePath()
    };

    // String[] cmd = new String[] {
    //         "-i", path, "-c:v", "libx264", "-preset", "ultrafast", "-filter_complex",
    //         "drawtext=fontfile=/system/fonts/Roboto-Black.ttf:text=" + text + ":x=" + left + ":y=" + top + ":fontcolor=" + fontColor + ":fontsize=" + fontSize + ":enable='between(t," + (duration-3) + "," + duration + ")'" + "," +
    //         "drawtext=fontfile=/system/fonts/Roboto-Black.ttf:text=" + text2 + ":x=" + left2 + ":y=" + top2 + ":fontcolor=" + fontColor2 + ":fontsize=" + fontSize2 + ":enable='between(t," + (duration-3) + "," + duration + ")'" + "," +
    //         "drawtext=fontfile=/system/fonts/Roboto-Black.ttf:text=" + text3 + ":x=" + left3 + ":y=" + top3 + ":fontcolor=" + fontColor3 + ":fontsize=" + fontSize3 + ":enable='between(t," + (duration-3) + "," + duration + ")'" + "," +
    //         "drawtext=fontfile=/system/fonts/Roboto-Black.ttf:text=" + text4 + ":x=" + left4 + ":y=" + top4 + ":fontcolor=" + fontColor4 + ":fontsize=" + fontSize4 + ":enable='between(t," + (duration-3) + "," + duration + ")'",
    //         out.getAbsolutePath()
    // };

    // String[] cmd = new String[] {
    //         "-i", path, "-c:v", "libx264", "-preset", "ultrafast", "-filter_complex",
    //         "drawtext=fontfile=/system/fonts/NotoSansCJK-Regular.ttc:text=" +
    //         text + ":x=" + left + ":y=" + top + ":fontcolor=" + fontColor + ":fontsize=" + fontSize +
    //         ":box=1:boxcolor="+backgroundColor+"@"+backgroundOpaciy+":boxborderw="+(fontSize/2) + ":enable='between(t," + (duration-3) + "," + duration + ")'," +
    //         "drawtext=fontfile=/system/fonts/NotoSansCJK-Regular.ttc:text=" +
    //         text2 + ":x=" + left2 + ":y=" + top2 + ":fontcolor=" + fontColor2 + ":fontsize=" + fontSize2 +
    //         ":box=1:boxcolor="+backgroundColor2+"@"+backgroundOpaciy2+":boxborderw="+(fontSize2/2)+  ":enable='between(t," + (duration-3) + "," + duration + ")'",
    //         out.getAbsolutePath()
    //       }

    _result = Arguments.createMap();
    _result.putString("path", out.getAbsolutePath());

    // 埋め込み
    try {
      // to execute "ffmpeg -version" command you just need to pass "-version"
      ffmpeg.execute(cmd, new ExecuteBinaryResponseHandler() {

        @Override
        public void onStart() {
          Log.d("example", "start ffmpeg");
        }

        @Override
        public void onProgress(String message) {
          Log.d("example", "onProgress: " + message);
        }

        @Override
        public void onFailure(String message) {
          Log.e("example", "Error ffmpeg executing with message:\n\t" + message);
        }

        @Override
        public void onSuccess(String message) {
          _result.putString("message", "success");
          RNMediaEditorModule._promise.resolve(_result);
        }

        @Override
        public void onFinish() {
        }
      });
    } catch (FFmpegCommandAlreadyRunningException e) {
      // Handle if FFmpeg is already running
    }
  }

  public static Bitmap rotateBitmap(Bitmap bitmap, int orientation) {

    Matrix matrix = new Matrix();
    switch (orientation) {
      case ExifInterface.ORIENTATION_NORMAL:
        return bitmap;
      case ExifInterface.ORIENTATION_FLIP_HORIZONTAL:
        matrix.setScale(-1, 1);
        break;
      case ExifInterface.ORIENTATION_ROTATE_180:
        matrix.setRotate(180);
        break;
      case ExifInterface.ORIENTATION_FLIP_VERTICAL:
        matrix.setRotate(180);
        matrix.postScale(-1, 1);
        break;
      case ExifInterface.ORIENTATION_TRANSPOSE:
        matrix.setRotate(90);
        matrix.postScale(-1, 1);
        break;
     case ExifInterface.ORIENTATION_ROTATE_90:
       matrix.setRotate(90);
       break;
     case ExifInterface.ORIENTATION_TRANSVERSE:
       matrix.setRotate(-90);
       matrix.postScale(-1, 1);
       break;
     case ExifInterface.ORIENTATION_ROTATE_270:
       matrix.setRotate(-90);
       break;
     default:
         return bitmap;
    }
    try {
      Bitmap bmRotated = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, true);
      bitmap.recycle();
      return bmRotated;
    }
    catch (OutOfMemoryError e) {
      e.printStackTrace();
      return null;
    }
  }

  public static int getOrientation(String path) {
    try {
      ExifInterface exifImage = new ExifInterface(path);
      int orientation = exifImage.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_UNDEFINED);
      return orientation;
    } catch(IOException e) {
      System.err.println(e.getMessage());
      return 1;
    }
  }

  public static int topValue(ReadableMap text, int orientation) {
    int top = 0;
    if (orientation < 5) {
      top = text.getInt("top");
    } else if (orientation >= 5) {
      top = text.getInt("rtop");
    }
    return top;
  }

  public static int leftValue(ReadableMap text, int orientation) {
    int left = 0;
    if (orientation < 5) {
      left = text.getInt("left");
    } else if (orientation >= 5) {
      left = text.getInt("rleft");
    }
    return left;
  }

  private void copyAssets() {
    Context context = getReactApplicationContext();
    AssetManager assetManager = context.getAssets();
    String[] files = null;
    try {
      files = assetManager.list("");
    } catch (IOException e) {
      Log.e("tag", "Failed to get asset file list.", e);
    }
    if (files != null) for (String filename : files) {
      InputStream in = null;
      OutputStream out = null;
      try {
        in = assetManager.open(filename);
        File outFile = new File(context.getExternalFilesDir(null), filename);
        out = new FileOutputStream(outFile);
        copyFile(in, out);
        Log.d("example", "fontFile=" + filename);
      } catch(IOException e) {
        Log.e("tag", "Failed to copy asset file: " + filename, e);
      }
      finally {
        if (in != null) {
          try {
            in.close();
          } catch (IOException e) {
            // NOOP
          }
        }
        if (out != null) {
          try {
            out.close();
          } catch (IOException e) {
            // NOOP
          }
        }
      }
    }
  }
  private void copyFile(InputStream in, OutputStream out) throws IOException {
      byte[] buffer = new byte[1024];
      int read;
      while((read = in.read(buffer)) != -1){
        out.write(buffer, 0, read);
      }
  }


  //
  // // get rotate data from ffprobe
  // public static int getRotate() {
  //   String CODEC_TYPE_VIDEO = "video";
  //   String CODEC_TYPE_AUDIO = "audio";
  //   String CODEC_TYPE_SUBTITLE = "subtitle";
  //
  //   String[] CMD_JSON = {"ffprobe", "-v", "quiet", "-print_format", "json", "-show_format", "-show_streams", ""};
  //
  //   String[] CMD_LOG = {"ffprobe", ""};
  //
  //   Probe data;
  //   File file = fileName;
  //
  //   Log.d("ffprobe parsing file: " + file.getAbsolutePath());
  //
  //   String filePath = file.getAbsolutePath();
  //
  //   // just for logging ===============================
  //   CMD_LOG[CMD_LOG.length - 1] = filePath;
  //   RuntimeExec rt = new RuntimeExec(CMD_LOG, null, RuntimeExec.VERBOSE);
  //   rt.execute();
  //
  //   // real data ===============================
  //   CMD_JSON[CMD_JSON.length - 1] = filePath;
  //   rt = new RuntimeExec(CMD_JSON, null, RuntimeExec.STRING_RESPONSE);
  //
  //   if (rt.execute()) {
  //     String response = rt.getResponse();
  //     Gson gson = new GsonBuilder().create();
  //     return gson.fromJson(response, Probe.class);
  //   }
  // }
}
