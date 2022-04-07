package de.mintware.barcode_scan;

import android.content.Context;
import android.content.res.Configuration;
import android.graphics.Rect;
import android.hardware.Camera;
import android.os.Handler;
import android.os.Looper;
import android.util.AttributeSet;
import android.util.Log;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.BinaryBitmap;
import com.google.zxing.DecodeHintType;
import com.google.zxing.LuminanceSource;
import com.google.zxing.MultiFormatReader;
import com.google.zxing.NotFoundException;
import com.google.zxing.PlanarYUVLuminanceSource;
import com.google.zxing.ReaderException;
import com.google.zxing.Result;
import com.google.zxing.common.HybridBinarizer;

import java.util.ArrayList;
import java.util.Collection;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;

import me.dm7.barcodescanner.core.DisplayUtils;

public class MyScannerView extends MyBarcodeScannerView {
    private static final String TAG = "MyScannerView";

    public interface ResultHandler {
        void handleResult(Result rawResult);
    }

    private MultiFormatReader mMultiFormatReader;
    public static final List<BarcodeFormat> BARCODE_FORMAT_ARRAY_LIST = new ArrayList<>();
    public static final List<BarcodeFormat> QRCODE_FORMAT_ARRAY_LIST = new ArrayList<>();
    private List<BarcodeFormat> mFormats;
    private ResultHandler mResultHandler;

    static {
        BARCODE_FORMAT_ARRAY_LIST.add(BarcodeFormat.AZTEC);
        BARCODE_FORMAT_ARRAY_LIST.add(BarcodeFormat.CODABAR);
        BARCODE_FORMAT_ARRAY_LIST.add(BarcodeFormat.CODE_39);
        BARCODE_FORMAT_ARRAY_LIST.add(BarcodeFormat.CODE_93);
        BARCODE_FORMAT_ARRAY_LIST.add(BarcodeFormat.CODE_128);
        BARCODE_FORMAT_ARRAY_LIST.add(BarcodeFormat.DATA_MATRIX);
        BARCODE_FORMAT_ARRAY_LIST.add(BarcodeFormat.EAN_8);
        BARCODE_FORMAT_ARRAY_LIST.add(BarcodeFormat.EAN_13);
        BARCODE_FORMAT_ARRAY_LIST.add(BarcodeFormat.ITF);
        BARCODE_FORMAT_ARRAY_LIST.add(BarcodeFormat.MAXICODE);
        BARCODE_FORMAT_ARRAY_LIST.add(BarcodeFormat.PDF_417);
        BARCODE_FORMAT_ARRAY_LIST.add(BarcodeFormat.RSS_14);
        BARCODE_FORMAT_ARRAY_LIST.add(BarcodeFormat.RSS_EXPANDED);
        BARCODE_FORMAT_ARRAY_LIST.add(BarcodeFormat.UPC_A);
        BARCODE_FORMAT_ARRAY_LIST.add(BarcodeFormat.UPC_E);
        BARCODE_FORMAT_ARRAY_LIST.add(BarcodeFormat.UPC_EAN_EXTENSION);

        QRCODE_FORMAT_ARRAY_LIST.add(BarcodeFormat.QR_CODE);
    }

    public MyScannerView(Context context) {
        super(context);
        initMultiFormatReader();
    }


    public MyScannerView(Context context, AttributeSet attributeSet) {
        super(context, attributeSet);
        initMultiFormatReader();
    }

    public void setFormats(List<BarcodeFormat> formats) {
        mFormats = formats;
        initMultiFormatReader();
    }

    public void setResultHandler(ResultHandler resultHandler) {
        mResultHandler = resultHandler;
    }

    public Collection<BarcodeFormat> getFormats() {
        if (mFormats == null) {
            if (BarcodeView.Companion.getScanType() == 1) {
                Log.d("response","scantype== 1");
                return BARCODE_FORMAT_ARRAY_LIST;
            } else {
                Log.d("response","scantype== 2");
                return QRCODE_FORMAT_ARRAY_LIST;
            }
        }
        return mFormats;
    }

    private void initMultiFormatReader() {
        Map<DecodeHintType, Object> hints = new EnumMap<>(DecodeHintType.class);
        hints.put(DecodeHintType.POSSIBLE_FORMATS, getFormats());
        mMultiFormatReader = new MultiFormatReader();
        mMultiFormatReader.setHints(hints);
    }

    @Override
    public void onPreviewFrame(byte[] data, Camera camera) {
        if (mResultHandler == null) {
            return;
        }

        try {
            Camera.Parameters parameters = camera.getParameters();
            Camera.Size size = parameters.getPreviewSize();
            int width = size.width;
            int height = size.height;
            if (DisplayUtils.getScreenOrientation(getContext()) == Configuration.ORIENTATION_PORTRAIT) {
                int rotationCount = getRotationCount();
                if (rotationCount == 1 || rotationCount == 3) {
                    int tmp = width;
                    width = height;
                    height = tmp;
                }
                data = getRotatedData(data, camera);
            }

            Result rawResult = null;
            PlanarYUVLuminanceSource source = buildLuminanceSource(data, width, height);
            if (source != null) {
                BinaryBitmap bitmap = new BinaryBitmap(new HybridBinarizer(source));
                try {
                    rawResult = mMultiFormatReader.decodeWithState(bitmap);
                } catch (ReaderException re) {
                    // continue
                } catch (NullPointerException npe) {
                    // This is terrible
                } catch (ArrayIndexOutOfBoundsException aoe) {

                } finally {
                    mMultiFormatReader.reset();
                }

                if (rawResult == null) {
                    LuminanceSource invertedSource = source.invert();
                    bitmap = new BinaryBitmap(new HybridBinarizer(invertedSource));
                    try {
                        rawResult = mMultiFormatReader.decodeWithState(bitmap);
                    } catch (NotFoundException e) {
                        // continue
                    } finally {
                        mMultiFormatReader.reset();
                    }
                }
            }

            final Result finalRawResult = rawResult;
            if (finalRawResult != null) {
                Handler handler = new Handler(Looper.getMainLooper());
                handler.post(new Runnable() {
                    @Override
                    public void run() {
//                        ZXingScannerView.ResultHandler tmpResultHandler = mResultHandler;
//                        mResultHandler = null;
                        stopCameraPreview();
                        if (mResultHandler != null) {
                            mResultHandler.handleResult(finalRawResult);
                        }
                    }
                });
//                handler.postDelayed(new Runnable() {
//                    @Override
//                    public void run() {
//                        resumeCameraPreview(mResultHandler);
//                    }
//                }, 1500);
            } else {
                camera.setOneShotPreviewCallback(this);
            }
        } catch (RuntimeException e) {
            // TODO: Terrible hack. It is possible that this method is invoked after camera is released.
            Log.e(TAG, e.toString(), e);
        }
    }

    public void resumeCameraPreview(ResultHandler resultHandler) {
        mResultHandler = resultHandler;
        super.resumeCameraPreview();
    }

    public PlanarYUVLuminanceSource buildLuminanceSource(byte[] data, int width, int height) {
        Rect rect = getFramingRectInPreview(width, height);
        if (rect == null) {
            return null;
        }
        // Go ahead and assume it's YUV rather than die.
        PlanarYUVLuminanceSource source = null;

        try {
//            source = new PlanarYUVLuminanceSource(data, width, height, 0, 0,
//                    rect.width(), rect.height(), false);
            source = new PlanarYUVLuminanceSource(data, width, height, 0, 0,
                    width, BarcodeView.Companion.getScanHeight(), false);
        } catch (Exception e) {
        }

        return source;
    }

}
