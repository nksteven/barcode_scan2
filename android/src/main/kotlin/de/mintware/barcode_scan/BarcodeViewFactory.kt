package de.mintware.barcode_scan

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class BarcodeViewFactory(var messenger: BinaryMessenger): PlatformViewFactory(StandardMessageCodec.INSTANCE){


    override fun create(context: Context, viewId: Int, args: Any): PlatformView {
        var params=args?.let {
            args as  Map<String,Any>
        }
        return  BarcodeView(context,messenger,params)
    }
}