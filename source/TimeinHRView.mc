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
  hidden var userHeartRateZones as Lang.Array<Lang.Number> = [0, 0, 0, 0, 0, 0];
  hidden var mZoneColors as Lang.Array<Lang.Number> = [
    Graphics.COLOR_BLUE,
    Graphics.COLOR_BLUE,
    Graphics.COLOR_GREEN,
    Graphics.COLOR_YELLOW,
    Graphics.COLOR_ORANGE,
    Graphics.COLOR_RED,
  ];
  hidden var timeInZoneFraction as Array<Lang.Float>;
  hidden var currentZoneDecimal as Float = 0.0;
  hidden var currentZone as Number = 0;
  hidden var mFont = WatchUi.loadResource(Rez.Fonts.mplus1_medium_36);
  hidden var fontHeight = Graphics.getFontHeight(mFont);
  hidden var smallFont = WatchUi.loadResource(Rez.Fonts.mplus1_medium_20);
  //hidden var smallFont = Graphics.FONT_SYSTEM_SMALL;
  hidden var smallFontHeight = Graphics.getFontHeight(smallFont);
  hidden var currentHeartRate as Number = 0;
  hidden var restingHeartRate as Float = 0.0;
  hidden var percentHRR as Float = 0.0;
  hidden var tap = false as Boolean;

  function initialize() {
    DataField.initialize();
    mValue = 0.0f;
    timeInHeartRateZones = [0, 0, 0, 0, 0, 0];
    var currentSport = UserProfile.getCurrentSport() as UserProfile.SportHrZone;
    userHeartRateZones = UserProfile.getHeartRateZones(currentSport) as Lang.Array<Lang.Number>;
    var restingHR = UserProfile.getProfile().restingHeartRate as Number; 
    if (restingHR == null) {
      restingHeartRate = 0.0;
    } else {
      restingHeartRate = restingHR.toFloat();
    }

    System.println("Current sport: " + currentSport);
    System.println("Current zones: " + userHeartRateZones);
    System.println("Resting Heart Rate: " + restingHeartRate);
    timeInZoneFraction = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
  }

  // Set your layout here. Anytime the size of obscurity of
  // the draw context is changed this will be called.
  function onLayout(dc as Dc) as Void {
    var obscurityFlags = DataField.getObscurityFlags();
    // Use the generic, centered layout
    // View.setLayout(Rez.Layouts.MainLayout(dc));
    drawBarsOnScreen(dc);
  }

  function onTap() as Void {
    tap = !tap;
    System.println("onTap " + tap);
  }

  // The given info object contains all the current workout information.
  // Calculate a value and save it locally in this method.
  // Note that compute() and onUpdate() are asynchronous, and there is no
  // guarantee that compute() will be called before onUpdate().
  function compute(info as Activity.Info) as Void {
    // See Activity.Info in the documentation for available information.
    updateHeartRateZonesTime(info);
  }

  // Increase the time spent in the current heart rate zone
  function updateHeartRateZonesTime(info as Activity.Info) as Void {
    if (
      info has :currentHeartRate && info has :elapsedTime &&
      info.currentHeartRate != null &&
      info.elapsedTime != null && info.elapsedTime > 1000
    ) {
      currentHeartRate = info.currentHeartRate as Number;

      var maxHR = userHeartRateZones[userHeartRateZones.size() - 1].toFloat();

      percentHRR = (currentHeartRate.toFloat() - restingHeartRate.toFloat()) / (maxHR - restingHeartRate);
      if (percentHRR < 0.0) {
        percentHRR = 0.0;
      } else if (percentHRR > 1.0) {
        percentHRR = 1.0;
      }

      var elapsedMilliSeconds = info.elapsedTime as Number;
      var elapsedSeconds = (elapsedMilliSeconds.toFloat() / 1000) as Float;

    System.println("Current heart rate: " + currentHeartRate);

      currentZone = 0;
      if (currentHeartRate < userHeartRateZones[0]) {
        currentZone = 0;
        currentZoneDecimal = currentHeartRate.toFloat() / userHeartRateZones[0];
      } else {
        if (currentHeartRate >= userHeartRateZones[0] && currentHeartRate < userHeartRateZones[1]) {
          currentZone = 1;
        } else if (currentHeartRate >= userHeartRateZones[1] && currentHeartRate < userHeartRateZones[2]) {
          currentZone = 2;
        } else if (currentHeartRate >= userHeartRateZones[2] && currentHeartRate < userHeartRateZones[3]) {
          currentZone = 3;
        } else if (currentHeartRate >= userHeartRateZones[3] && currentHeartRate < userHeartRateZones[4]) {
          currentZone = 4;
        } else if (currentHeartRate >= userHeartRateZones[4]) {
          currentZone = 5;
        }
        currentZoneDecimal =
          (currentHeartRate - userHeartRateZones[currentZone - 1]).toFloat() /
          (userHeartRateZones[currentZone] - userHeartRateZones[currentZone - 1]).toFloat();
      }

      if (currentZoneDecimal > 1.0) {
        currentZoneDecimal = 1.0;
      }
      currentZoneDecimal = currentZone + currentZoneDecimal;

      // Update the time in the current zone and calculate fraction of time in each zone
      var timeInCurrentZone = (timeInHeartRateZones[currentZone] + 1) as Number;
      timeInHeartRateZones[currentZone] = timeInCurrentZone;
      var fraction = 0.0;
      if (elapsedSeconds > 0.0) {
        fraction = timeInCurrentZone.toFloat() / elapsedSeconds;
      }
      if (fraction > 1.0) {
        fraction = 1.0;
      }
      timeInZoneFraction[currentZone] = fraction;

      for (var i = 0; i < userHeartRateZones.size(); i++) {
        if (i != currentZone) {
          var timeInZoneI = (timeInHeartRateZones[i] as Number).toFloat();
          var fractionI = 0.0;
          fractionI = timeInZoneI / elapsedSeconds;
          if (fractionI > 1.0) {
            fractionI = 1.0;
          }
          timeInZoneFraction[i] = fractionI;
        }
      }
    } else {
      System.println("No heart rate data");
    }
  }

  // Display the value you computed here. This will be called
  // once a second when the data field is visible.
  function onUpdate(dc as Dc) as Void {
    // Call parent's onUpdate(dc) to redraw the layout
    View.onUpdate(dc);
    drawBarsOnScreen(dc);
  }

  hidden var cornerRadius as Number = 2;

  function drawBarsOnScreen(dc as Dc) as Void {
    // Create the heart rate zone bars
    var screenWidth = dc.getWidth();
    var screenHeight = dc.getHeight();

    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
    dc.fillRectangle(0, 0, screenWidth, screenHeight);

    var minimumBarWidth = 8;
    var barVerticalSpacing = 0;
    var barHeight = screenHeight.toFloat() / (timeInHeartRateZones.size().toFloat());


    for (var indexBar = timeInHeartRateZones.size() - 1; indexBar > 0; indexBar--) {
      var barX = 0;
      var indexZone = timeInHeartRateZones.size() - indexBar;
      System.println("indexBar " + indexBar + " index " + indexZone);
      var barY = (indexBar - 1) * barHeight + barVerticalSpacing; // indexBar - 1 to position at top of screen for zone 5
      var barColor = mZoneColors[indexZone];
      var barWidth = minimumBarWidth + timeInZoneFraction[indexZone] * (screenWidth - minimumBarWidth);
      dc.setColor(barColor, Graphics.COLOR_WHITE);
      dc.fillRoundedRectangle(barX, barY, barWidth, barHeight, cornerRadius);

      var labelX = barX + minimumBarWidth + 30;
      
      var labelY = barY + ((barHeight - fontHeight) / 2) - 2;
      var labelText = "Z" + indexZone;
      if (timeInHeartRateZones[indexZone] > 0) {
        labelText += " " + secondsToTimeString(timeInHeartRateZones[indexZone]);
      }
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
      dc.drawText(labelX, labelY, mFont, labelText, Graphics.TEXT_JUSTIFY_LEFT);

      System.println(
          " Time in zone " + indexZone + ": " + timeInHeartRateZones[indexZone] +
          " currentZone: " + currentZone +
          " currentZoneDecimal: " + currentZoneDecimal +
          " TimeFraction: " + timeInZoneFraction[indexZone] +
          " userHeartRateZones: " + userHeartRateZones
      );

      // draw a black rectangle around the current zone
      if (currentZone == indexZone) {
        dc.setPenWidth(3);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(0, (indexBar - 1) * barHeight, screenWidth, barHeight, cornerRadius);
      }
    }

    // draw a triangle pointing right in the Z1 to Z5 area
    if (currentZoneDecimal > 0.9) {
      var triangleSize = barHeight / 4;
      var triangleX = minimumBarWidth;
      var triangleY = screenHeight * (1 - (currentZoneDecimal / 6));
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
      dc.fillPolygon([
        [triangleX, triangleY - triangleSize],      // Top vertex
        [triangleX + 25, triangleY],                // Right vertex
        [triangleX, triangleY + triangleSize],      // Bottom vertex
      ]);
    }

    var maxY = screenHeight - barHeight;
    // draw horizonta line after z5
    var penWidth = 2;
    dc.setPenWidth(penWidth);
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    dc.drawLine(0, maxY, screenWidth, maxY);
    // draw vertical centered line after z5
    dc.drawLine(screenWidth / 2, maxY, screenWidth / 2, screenHeight);


    // text with current heart rate zone 
    var textY = maxY + (barHeight - fontHeight) / 2;
    var zoneDecimal = currentZoneDecimal.format("%.2f");
    var textX = ((screenWidth / 2) - dc.getTextWidthInPixels(zoneDecimal, mFont)) / 2;
    dc.drawText(textX, textY, mFont, zoneDecimal, Graphics.TEXT_JUSTIFY_LEFT);
    

    // bar with %HRR
    var barColor = mZoneColors[currentZone];
    var barWidth = percentHRR * (screenWidth / 2);
    dc.setColor(barColor, Graphics.COLOR_WHITE);
    var hr;
    if (tap) {
      hr = (percentHRR * 100).format("%2d") + "%";
    } else {
      hr = "♥" + currentHeartRate;
    }
    dc.fillRectangle(screenWidth / 2 + penWidth / 2, maxY + penWidth / 2, barWidth - penWidth / 2, barHeight);
    textX = screenWidth / 2 + ((screenWidth / 2) - dc.getTextWidthInPixels(hr, mFont)) / 2;
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    dc.drawText(textX, textY, mFont, hr, Graphics.TEXT_JUSTIFY_LEFT);
  }

  function secondsToTimeString(totalSeconds as Number) as String {
    var hours = totalSeconds / 3600;
    var minutes = (totalSeconds / 60) % 60;
    var seconds = totalSeconds % 60;
    return format("$1$:$2$:$3$", [
      hours.format("%01d"),
      minutes.format("%02d"),
      seconds.format("%02d"),
    ]);
  }

// Function to interpolate between colors
function interpolateColor(value as Float) {
  // Ensure the value is between 0 and 1
  //value = Math.max(0, Math.min(1, value));

  // Define color values
  var blue = Graphics.createColor(255, 0, 0, 255);
  var green = Graphics.createColor(255, 0, 255, 0);
  var yellow = Graphics.createColor(255, 255, 255, 0);
  var orange = Graphics.createColor(255, 255, 165, 0);
  var red = Graphics.createColor(255, 255, 0, 0);

  // Interpolate between colors based on the value
  if (value <= 0.2) {
    return interpolate(blue, green, value / 0.2);
  } else if (value <= 0.4) {
    return interpolate(green, yellow, (value - 0.2) / 0.2);
  } else if (value <= 0.6) {
    return interpolate(yellow, orange, (value - 0.4) / 0.2);
  } else if (value <= 0.8) {
    return interpolate(orange, red, (value - 0.6) / 0.2);
  } else {
    return red;
  }
}

  // Function to interpolate between two colors
  function interpolate(color1, color2, ratio) as Number {
    var alpha = Math.round(color1 >> 24 + (color2 >> 24 - color1 >> 24) * ratio);
    var red = Math.round((color1 >> 16 & 0xFF) + ((color2 >> 16 & 0xFF) - (color1 >> 16 & 0xFF)) * ratio);
    var green = Math.round((color1 >> 8 & 0xFF) + ((color2 >> 8 & 0xFF) - (color1 >> 8 & 0xFF)) * ratio);
    var blue = Math.round((color1 & 0xFF) + ((color2 & 0xFF) - (color1 & 0xFF)) * ratio);

    return Graphics.createColor(alpha, red, green, blue);
  }


}
