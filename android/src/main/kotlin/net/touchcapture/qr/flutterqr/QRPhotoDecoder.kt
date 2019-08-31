package net.touchcapture.qr.flutterqr

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.AsyncTask
import android.util.Log
import java.lang.ref.WeakReference
import com.google.zxing.common.GlobalHistogramBinarizer
import com.google.zxing.BinaryBitmap
import com.google.zxing.MultiFormatReader
import com.google.zxing.common.HybridBinarizer
import com.google.zxing.RGBLuminanceSource
import com.google.zxing.DecodeHintType
import com.google.zxing.BarcodeFormat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.util.*
import kotlin.collections.ArrayList


class QRPhotoDecoder(var registrar: PluginRegistry.Registrar) : MethodChannel.MethodCallHandler {
    private var channel: MethodChannel = MethodChannel(registrar.messenger(), "net.touchcapture.qr.flutterqr/photo_decoder")

    companion object {

        val HINTS: MutableMap<DecodeHintType, Any> = EnumMap(DecodeHintType::class.java)

        init {
            val allFormats = ArrayList<BarcodeFormat>()
            allFormats.add(BarcodeFormat.AZTEC)
            allFormats.add(BarcodeFormat.CODABAR)
            allFormats.add(BarcodeFormat.CODE_39)
            allFormats.add(BarcodeFormat.CODE_93)
            allFormats.add(BarcodeFormat.CODE_128)
            allFormats.add(BarcodeFormat.DATA_MATRIX)
            allFormats.add(BarcodeFormat.EAN_8)
            allFormats.add(BarcodeFormat.EAN_13)
            allFormats.add(BarcodeFormat.ITF)
            allFormats.add(BarcodeFormat.MAXICODE)
            allFormats.add(BarcodeFormat.PDF_417)
            allFormats.add(BarcodeFormat.QR_CODE)
            allFormats.add(BarcodeFormat.RSS_14)
            allFormats.add(BarcodeFormat.RSS_EXPANDED)
            allFormats.add(BarcodeFormat.UPC_A)
            allFormats.add(BarcodeFormat.UPC_E)
            allFormats.add(BarcodeFormat.UPC_EAN_EXTENSION)
            HINTS[DecodeHintType.TRY_HARDER] = BarcodeFormat.QR_CODE
            HINTS[DecodeHintType.POSSIBLE_FORMATS] = allFormats
            HINTS[DecodeHintType.CHARACTER_SET] = "utf-8"
        }

    }

    init {

        channel.setMethodCallHandler(this)
    }


    inner class DecoderTask
        : AsyncTask<String, Void, String?>() {


        private fun decode(bitmap: Bitmap): String? {
            var result: com.google.zxing.Result?
            var source: RGBLuminanceSource? = null
            try {
                val width = bitmap.width
                val height = bitmap.height
                val pixels = IntArray(width * height)
                bitmap.getPixels(pixels, 0, width, 0, 0, width, height)
                source = RGBLuminanceSource(width, height, pixels)
                result = MultiFormatReader().decode(BinaryBitmap(HybridBinarizer(source)), HINTS)
                return result!!.getText()
            } catch (e: Exception) {
                e.printStackTrace()
                if (source != null) {
                    try {
                        result = MultiFormatReader().decode(BinaryBitmap(GlobalHistogramBinarizer(source)), HINTS)
                        return result!!.text
                    } catch (e2: Throwable) {
                        e2.printStackTrace()
                    }

                }
                return null
            }

        }


        private fun loadBitmap(path: String): Bitmap? {
            return try {
                val options = BitmapFactory.Options()
                options.inJustDecodeBounds = true//  only load options
                BitmapFactory.decodeFile(path, options)
                var sampleSize = options.outHeight / 800
                if (sampleSize <= 0) {
                    sampleSize = 1
                }
                options.inSampleSize = sampleSize
                options.inJustDecodeBounds = false
                BitmapFactory.decodeFile(path, options)
            } catch (e: Exception) {
                e.printStackTrace()
                null
            }

        }


        override fun doInBackground(vararg params: String): String? {
            if (params.isNotEmpty()) {
                var path = params.first()
                var bitmap = loadBitmap(path)
                if (bitmap != null) {
                    return decode(bitmap)
                }
            }
            return null;
        }

        override fun onPostExecute(result: String?) {
            registrar.activity().runOnUiThread {
                channel.invokeMethod("onDecodeQR", (result ?: ""))
            }
        }
    }


    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when {
            call.method == "decode" -> prasePhoto(call.arguments as String)
            else -> result.notImplemented()
        }
    }

    private fun prasePhoto(path: String) {
        DecoderTask().execute(path)
    }


}