import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.UserProfile;
import Toybox.Time;

class TimeinHRView extends WatchUi.DataField {

    hidden var mValue as Numeric;
    hidden var timeInHeartRateZones as Array;
    hidden var userHeartRateZones = [0, 0, 0, 0, 0, 0]; // 6 elements
    hidden var mZoneColors = [Graphics.COLOR_BLUE, Graphics.COLOR_GREEN, Graphics.COLOR_YELLOW, Graphics.COLOR_ORANGE, Graphics.COLOR_RED];
    hidden var mZonePercentage as Array<Lang.Float>;
    hidden var currentZone as Number = 1;

    function initialize() {
        DataField.initialize();
        mValue = 0.0f;
        timeInHeartRateZones = [0, 0, 0, 0, 0];
        var currentSport = UserProfile.getCurrentSport() as UserProfile.SportHrZone;
        userHeartRateZones = UserProfile.getHeartRateZones(currentSport) as Lang.Array<Lang.Number>;

        System.println("Current sport: " + currentSport);
        System.println("Current zones: " + userHeartRateZones);
        mZonePercentage = [0.0, 0.0, 0.0, 0.0, 0.0];
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc as Dc) as Void {
        var obscurityFlags = DataField.getObscurityFlags();

        // // Use the generic, centered layout
        // View.setLayout(Rez.Layouts.MainLayout(dc));

        // var labelView = View.findDrawableById("label") as Text;
        // labelView.locY = labelView.locY - 16;
        // var valueView = View.findDrawableById("value") as Text;
        // valueView.locY = valueView.locY + 7;

        

        updateBarsOnScreen(dc);

        // labelView.setColor(Graphics.COLOR_BLACK);
        // labelView.setText(Rez.Strings.label);
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info as Activity.Info) as Void {
        // See Activity.Info in the documentation for available information.
        updateHeartRateZonesTime(info);
        // if (info has :currentHeartRate && info.currentHeartRate != null) {
        //     mValue = info.currentHeartRate as Number;
        // } else {
        //     mValue = 0.0f;
        // }
    }

    // Increase the time spent in the current heart rate zone
    function updateHeartRateZonesTime(info as Activity.Info) as Void {
        if (info == null) {
            System.println("Info is null");
            return;
        }
        
        if (info has :currentHeartRate && info.currentHeartRate != null && info.elapsedTime != null && info.elapsedTime > 1000) {
            var currentHeartRate = info.currentHeartRate as Number;
            var elapsedMilliSeconds = info.elapsedTime as Number;
            var elapsedSeconds = elapsedMilliSeconds / 1000;
            for (var i = 1; i < userHeartRateZones.size(); i++) {
                var zone = userHeartRateZones[i] as Number;
                if (zone != null && currentHeartRate <= zone) {
                    currentZone = i;
                    try {
                        var timeInZoneI = (timeInHeartRateZones[i] + 1) as Number;
                        timeInHeartRateZones[i] = timeInZoneI;
                        var percentage = 0;
                        if (elapsedSeconds > 0) {
                            percentage = (timeInZoneI.toFloat() / elapsedSeconds.toFloat());
                        }
                        mZonePercentage[i] = percentage;
                        System.println("CurrentHeartRate: " + currentHeartRate + " Zone " + i + " percentage: " + percentage + " timeInZoneI: " + timeInZoneI + " elapsedSeconds: " + elapsedSeconds + " elpasedMiliseconds: " + elapsedMilliSeconds);
                    } catch (e) {
                        System.println("Exception: " + e + "\n" +
                    "timeInHeartRateZones[i]: " + timeInHeartRateZones[i] + "\n" +
                    "elapsedTime: " + elapsedSeconds + "\n" +
                    "imZonePercentage: " + mZonePercentage + "\n" +
                    "i: " + i);
                    }
                    break;
                }
            }
        } else {
            System.println("No heart rate data");
        }
    }

    function updateBarsOnScreen(dc as Dc) as Void {
        // Create the heart rate zone bars
        var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillRectangle(0, 0, screenWidth, screenHeight);


        var minimumBarWidth = 20;
        var barHeight = screenHeight / timeInHeartRateZones.size();
        var barVerticalSpacing = 1;
        var startX = 0;
        var startY = 0;
        for (var i = 0; i < timeInHeartRateZones.size(); i++) {
            var barX = startX;
            var barY = startY + i * (barHeight + barVerticalSpacing);
            var barColor = mZoneColors[i];
            var barWidth = minimumBarWidth + mZonePercentage[i] * (screenWidth - minimumBarWidth);
            dc.setColor(barColor, Graphics.COLOR_WHITE);
            dc.fillRectangle(barX, barY, barWidth, barHeight);

            if (currentZone == i) {
                // draw triangle pointing right using dc.drawLine(x1, y1, x2, y2)
                var triangleX = 1;
                var triangleY = barY + barHeight / 2;
                var triangleSize = 20;
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
                dc.fillPolygon([[triangleX, triangleY - triangleSize / 2], [triangleX + triangleSize, triangleY], [triangleX, triangleY + triangleSize / 2]]);
            }
            var transparentColor = Graphics.COLOR_TRANSPARENT;
            // dc.createColor(128, 0, 0, 0)
            dc.setColor(Graphics.COLOR_BLACK, transparentColor);
            var labelX = barX + minimumBarWidth;
            var labelY = barY + dc.getFontHeight(Graphics.FONT_NUMBER_MEDIUM) / 4;

            var labelText = "Z" + (i + 1) + " " + secondsToTimeString(timeInHeartRateZones[i]);
            dc.drawText(labelX, labelY , Graphics.FONT_NUMBER_MEDIUM, labelText, Graphics.TEXT_JUSTIFY_LEFT);
        }
    }
    

    function secondsToTimeString(totalSeconds as Number) as String {
        var hours = totalSeconds / 3600;
        var minutes = (totalSeconds /60) % 60;
        var seconds = totalSeconds % 60;
        var timeString = format("$1$:$2$:$3$", [hours.format("%01d"), minutes.format("%02d"), seconds.format("%02d")]);
        return timeString;
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc as Dc) as Void {
        // Set the background color
        // (View.findDrawableById("Background") as Text).setColor(getBackgroundColor());

        // Set the foreground color and value
        // var value = View.findDrawableById("value") as Text;
        // if (getBackgroundColor() == Graphics.COLOR_BLACK) {
        //     value.setColor(Graphics.COLOR_WHITE);
        // } else {
        //     value.setColor(Graphics.COLOR_BLACK);
        // }
        // value.setColor(Graphics.COLOR_BLACK);
        // value.setText(mValue.format("%.2f"));

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);

        updateBarsOnScreen(dc);
    }

}
