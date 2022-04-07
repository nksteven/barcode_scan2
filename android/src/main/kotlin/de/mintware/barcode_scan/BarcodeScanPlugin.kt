package de.mintware.barcode_scan

import androidx.annotation.Nullable
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry


/** BarcodeScanPlugin */
class BarcodeScanPlugin : FlutterPlugin ,ActivityAware{

    @Nullable
    private var channelHandler: ChannelHandler? = null
    @Nullable

    private var activityHelper: ActivityHelper? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        activityHelper = ActivityHelper(flutterPluginBinding.applicationContext)
        channelHandler = ChannelHandler(activityHelper!!)
        channelHandler!!.startListening(flutterPluginBinding.binaryMessenger)
        flutterPluginBinding.platformViewRegistry.registerViewFactory("barcode_android_view",BarcodeViewFactory(flutterPluginBinding.binaryMessenger))
    }

    override fun onDetachedFromEngine(p0: FlutterPlugin.FlutterPluginBinding) {
        if (channelHandler == null) {
            return
        }
        channelHandler!!.stopListening()
        channelHandler = null
        activityHelper = null
    }

    // This static function is optional and equivalent to onAttachedToEngine. It supports the old
    // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
    // plugin registration via this function while apps migrate to use the new Android APIs
    // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
    //
    // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
    // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
    // depending on the user's project. onAttachedToEngine or registerWith must both be defined
    // in the same class.
    companion object {
        @JvmStatic
        fun registerWith(registrar: PluginRegistry.Registrar) {
            registrar.platformViewRegistry().registerViewFactory("barcode_android_view",BarcodeViewFactory(registrar.messenger()))
        }
    }


    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        if (channelHandler == null) {
            return
        }
        binding.addActivityResultListener(activityHelper!!)
        binding.addRequestPermissionsResultListener(activityHelper!!)
        activityHelper!!.activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onDetachedFromActivity() {
        if (channelHandler == null) {
            return
        }
        activityHelper!!.activity = null
    }

   
}
