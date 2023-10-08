import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.UserProfile;
import Toybox.Time;
import Toybox.Math;

class TimeinHRView extends WatchUi.DataField {

    hidden var mValue as Numeric;
    hidden var timeInHeartRateZones as Array;
    hidden var userHeartRateZones = [0, 0, 0, 0, 0, 0]; // 6 elements
    hidden var mZoneColors = [Graphics.COLOR_BLUE, Graphics.COLOR_BLUE, Graphics.COLOR_GREEN, Graphics.COLOR_YELLOW, Graphics.COLOR_ORANGE, Graphics.COLOR_RED];
    hidden var mZonePercentage as Array<Lang.Float>;
    hidden var currentZoneFraction as Float = 1.0;
    hidden var currentZone as Number = 0;

    function initialize() {
        DataField.initialize();
        mValue = 0.0f;
        timeInHeartRateZones = [0, 0, 0, 0, 0, 0];
        var currentSport = UserProfile.getCurrentSport() as UserProfile.SportHrZone;
        userHeartRateZones = UserProfile.getHeartRateZones(currentSport) as Lang.Array<Lang.Number>;

        System.println("Current sport: " + currentSport);
        System.println("Current zones: " + userHeartRateZones);
        mZonePercentage = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
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

            currentZone = 0;
            if (currentHeartRate <= userHeartRateZones[0]) {
                currentZone = 0;
                currentZoneFraction = currentHeartRate / userHeartRateZones[0];
            } else {
                if (currentHeartRate > userHeartRateZones[0] && currentHeartRate <= userHeartRateZones[1]) {
                    currentZone = 1;
                } else if (currentHeartRate > userHeartRateZones[1] && currentHeartRate < userHeartRateZones[2]) {
                    currentZone = 2;
                } else if (currentHeartRate >= userHeartRateZones[2] && currentHeartRate < userHeartRateZones[3]) {
                    currentZone = 3;
                } else if (currentHeartRate >= userHeartRateZones[3] && currentHeartRate < userHeartRateZones[4]) {
                    currentZone = 4;
                } else if (currentHeartRate >= userHeartRateZones[4]) {
                    currentZone = 5;
                }
                currentZoneFraction = (currentHeartRate - userHeartRateZones[currentZone - 1]).toFloat() / 
                (userHeartRateZones[currentZone] - userHeartRateZones[currentZone - 1]).toFloat();
            }
            
            if (currentZoneFraction > 1.0) {
                currentZoneFraction = 1.0;
            }

            // Update the time in the current zone and calculate percentage
            var timeInCurrentZone = (timeInHeartRateZones[currentZone] + 1) as Number;
            timeInHeartRateZones[currentZone] = timeInCurrentZone;
            var percentage = 0;
            if (elapsedSeconds > 0) {
                percentage = (timeInCurrentZone.toFloat() / elapsedSeconds.toFloat());
            }
            if (percentage > 1) {
                percentage = 1;
            }
            mZonePercentage[currentZone] = percentage;
            System.println("CurrentHeartRate: " + currentHeartRate + " Zone " + currentZone + " percentage: " + percentage + " timeInCurrentZone: " + timeInCurrentZone + " elapsedSeconds: " + elapsedSeconds + " elapsedMilliseconds: " + elapsedMilliSeconds);

            for (var i = 0; i < userHeartRateZones.size(); i++) {
                if (i != currentZone) {
                    var timeInZoneI = timeInHeartRateZones[i] as Number;
                    var percentageI = 0;
                    if (elapsedSeconds > 0) {
                        percentageI = (timeInZoneI.toFloat() / elapsedSeconds.toFloat());
                    }
                    if (percentageI > 1) {
                        percentageI = 1;
                    }
                    mZonePercentage[i] = percentageI;

                    System.println("CurrentHeartRate: " + currentHeartRate + " Zone " + i + " percentage: " + percentageI + " timeInZoneI: " + timeInZoneI + " elapsedSeconds: " + elapsedSeconds + " elapsedMilliseconds: " + elapsedMilliSeconds);
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
        var barVerticalSpacing = 0;
        var barHeight = screenHeight / (timeInHeartRateZones.size() - 1);
        var startX = 0;
        var startY = 0;
        for (var i = 1; i < timeInHeartRateZones.size(); i++) {
            var barX = startX;
            var barY = startY + (i - 1) * barHeight + barVerticalSpacing;
            var barColor = mZoneColors[i];
            var barWidth = minimumBarWidth + mZonePercentage[i] * (screenWidth - minimumBarWidth);
            dc.setColor(barColor, Graphics.COLOR_WHITE);
            dc.fillRectangle(barX, barY, barWidth, barHeight);

            if (currentZone == i) {
                // draw a black rectangle around the current zone
                dc.setPenWidth(4);
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                dc.drawRectangle(0, (i - 1) * barHeight, screenWidth, barHeight);

                // draw triangle pointing right
                var triangleX = 1;
                System.println("Current Zone " + currentZone + " currentZoneFraction: " + currentZoneFraction);
                var triangleY = barY + currentZoneFraction * barHeight; // + barHeight / 2;
                var triangleSize = 20;
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
                dc.fillPolygon([
                    [triangleX, triangleY - triangleSize / 2], 
                    [triangleX + triangleSize, triangleY], 
                    [triangleX, triangleY + triangleSize / 2]
                ]);

            }

            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            var labelX = barX + minimumBarWidth;
            var labelY = barY + dc.getFontHeight(Graphics.FONT_NUMBER_MEDIUM) / 4;

            var labelText = "Z" + i;
            if (timeInHeartRateZones[i] > 0) {
                 labelText += " " + secondsToTimeString(timeInHeartRateZones[i]);
            }
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
