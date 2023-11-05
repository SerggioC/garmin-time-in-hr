import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// // import the KiezelPay functionality from the barrel
// using KPayApp.KPay as KPay;

// // make sure this variable is also accessible from your View
// var kpay as KPay.Core?;

// (:background :typecheck(disableBackgroundCheck))
class TimeinHRApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    //! Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        // make sure to always initialize KiezelPay at startup. Supply the KPAY_CONFIG you have defined in kpay_config.mc as parameter
        // kpay = new KPay.Core(KPAY_CONFIG);

        var initialView = new TimeinHRView();
        var inputDelegate = new TimeinHRInputDelegate(initialView);
        return [initialView, inputDelegate] as Array<Views or InputDelegates>;
    }

}

function getApp() as TimeinHRApp {
    return Application.getApp() as TimeinHRApp;
}