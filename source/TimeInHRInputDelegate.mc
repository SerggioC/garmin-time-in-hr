using Toybox.WatchUi as Ui;

//! A custom BehaviorDelegate that lets us use the next and previous
//! page events as well as adding an onEnter() event.
class TimeinHRInputDelegate extends Ui.BehaviorDelegate {

    var relatedView;

    //! Initialize a TimeinHRInputDelegate
    //! @param view The view that this delegate is tied to.
    function initialize(view) {
        relatedView = view;
    }

    //! Use the basic InputeDelegate to detect the enter key for the fenix 3
    //! and Forerunner 920.
    function onKey(evt) {
        if (evt.getKey() == Ui.KEY_MENU) {
            relatedView.onTap();
        }
        return true;
    }

    // Used to detect the start of the round on a vivoactive
    function onTap(evt) {
        relatedView.onTap();
        return true;
    }

    //! An enter event has occurred. This is triggered the following ways:
    //!     - vivoactive: a tap occurs
    //!     - fenix 3: the enter key is pressed
    //!     - Forerunner 920: the enter key is pressed
    //! @returns True if the event is handled
    function onEnter() {
        return false;
    }

    function onBack() {
        return false;
    }

}