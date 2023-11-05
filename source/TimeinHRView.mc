import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.UserProfile;
import Toybox.Time;
import Toybox.Math;
import Toybox.Attention;

class TimeinHRView extends WatchUi.DataField {

  hidden var timeInHeartRateZones as Array;
  hidden var userHeartRateZones as Lang.Array<Lang.Number> = [0, 0, 0, 0, 0, 0];
  hidden var mZoneColors as Lang.Array<Lang.Number> = [
    0x86F6FF, // light blue
    0x86F6FF, // light blue
    Graphics.COLOR_BLUE, 
    Graphics.COLOR_GREEN,
    0xFFD33A, // orange
    0xFF2100, // red
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
  hidden var averageHeartRate as Number = 0;
  hidden var restingHeartRate as Float = 0.0;
  hidden var percentHRR as Float = 0.0;
  hidden var tap = false as Boolean;
  hidden var cornerRadius as Number = 2;

  function initialize() {
    DataField.initialize();
    
    timeInHeartRateZones = [0, 0, 0, 0, 0, 0];
    var currentSport = UserProfile.getCurrentSport() as UserProfile.SportHrZone;
    userHeartRateZones = UserProfile.getHeartRateZones(currentSport) as Lang.Array<Lang.Number>;
    var restingHR = UserProfile.getProfile().restingHeartRate as Number; 
    if (restingHR == null) {
      restingHeartRate = 0.0;
    } else {
      restingHeartRate = restingHR.toFloat();
    }
    timeInZoneFraction = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    var hasColors = WatchUi.loadResource(Rez.Strings.hasColors);
    if (!hasColors.equals("true")) {
      mZoneColors = [
        Graphics.COLOR_TRANSPARENT,
        Graphics.COLOR_TRANSPARENT,
        Graphics.COLOR_TRANSPARENT,
        Graphics.COLOR_TRANSPARENT,
        Graphics.COLOR_TRANSPARENT,
        Graphics.COLOR_TRANSPARENT,
        ];
    }

    // var timer = new Timer.Timer();
		// timer.start(method(:onTimer), 1000, true);

  }

  // function onTimer() as Void {
  //   var info = Activity.getActivityInfo();
  //   if (info == null) {
  //     System.println("OnTimer. No activity info");
  //     return;
  //   } else {
  //     updateHeartRateZonesTime(info);
  //     WatchUi.requestUpdate();
  //   }
  // }

  // Set your layout here. Anytime the size of obscurity of
  // the draw context is changed this will be called.
  function onLayout(dc as Dc) as Void {
    // var obscurityFlags = View.getObscurityFlags();
    // Use the generic, centered layout
    // View.setLayout(Rez.Layouts.MainLayout(dc));
    drawBarsOnScreen(dc);
  }

  function onTap() as Void {
    tap = !tap;
    if (Attention has :playTone) {
      Attention.playTone(Attention.TONE_KEY);
    }
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

  // Increase the time spent in the current heart rate zone and calculate the fraction of time in each zone
  function updateHeartRateZonesTime(info as Activity.Info) as Void {
    currentZone = 0;
    if (info has :currentHeartRate) { 
      var current = info.currentHeartRate as Number;

      if (current == null) {
        currentHeartRate = 0;
      } else {
        currentHeartRate = current;
      }

      var maxHR = userHeartRateZones[userHeartRateZones.size() - 1].toFloat();

      percentHRR = (currentHeartRate.toFloat() - restingHeartRate.toFloat()) / (maxHR - restingHeartRate);
      if (percentHRR < 0.0) {
        percentHRR = 0.0;
      } else if (percentHRR > 1.0) {
        percentHRR = 1.0;
      }

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
    }

    if (info has :averageHeartRate) {
      var average = info.averageHeartRate as Number;
      if (average == null) {
        averageHeartRate = 0;
      } else {
        averageHeartRate = average;
      }
    }

    if (info has :elapsedTime && info.elapsedTime != null && info.elapsedTime > 1000 && 
        info has :timerState && info.timerState == Activity.TIMER_STATE_ON) {

      var elapsedMilliSeconds = info.elapsedTime as Number;
      var elapsedSeconds = (elapsedMilliSeconds.toFloat() / 1000) as Float;

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
    }
  }

  // Display the value you computed here. This will be called
  // once a second when the data field is visible.
  function onUpdate(dc as Dc) as Void {
    // in your view, always check if KiezelPay wants to display something
    // if ((kpay as KPayApp.KPay.Core).shouldShowDialog()) {
    //  // if (false) {
    //   System.println("KiezelPay app locked!");
    //   // in case KiezelPay wants to display something, allow it to draw it's dialog
    //   (kpay as KPayApp.KPay.Core).drawDialog(dc);
    // } else {
    //   System.println("KiezelPay app not locked");
      // Call the parent onUpdate function to redraw the layout
      View.onUpdate(dc);
      drawBarsOnScreen(dc);
    // }
  }


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

      // draw a black rectangle around the current zone
      if (currentZone == indexZone) {
        dc.setPenWidth(3);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(0, (indexBar - 1) * barHeight, screenWidth, barHeight, cornerRadius);
      }
    }

    // draw a triangle pointing right in the Z1 to Z5 area indicating the zone the user is in
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
    var penWidth = 2;
    
    // bar with %HRR
    var barColor = mZoneColors[currentZone];
    var barWidth = percentHRR * (screenWidth / 2);
    dc.setColor(barColor, Graphics.COLOR_WHITE);
    dc.fillRectangle(screenWidth / 2 + penWidth / 2, maxY + penWidth / 2, barWidth - penWidth / 2, barHeight);

    // draw horizontal line after z5
    dc.setPenWidth(penWidth);
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    dc.drawLine(0, maxY, screenWidth, maxY);

    // draw vertical centered line after z5
    dc.drawLine(screenWidth / 2, maxY, screenWidth / 2, screenHeight);


    // text with current heart rate zone on the left side of the screen
    var leftText = "Average HR";
    var textX = (screenWidth / 2 - dc.getTextWidthInPixels(leftText, smallFont)) / 2;
    dc.drawText(textX, maxY, smallFont, leftText, Graphics.TEXT_JUSTIFY_LEFT);
    // var zoneDecimal = currentZoneDecimal.format("%.2f");
    if (averageHeartRate == 0) {
      leftText = "--";
    } else {
      leftText = averageHeartRate.toString();
    }
    textX = ((screenWidth / 2) - dc.getTextWidthInPixels(leftText, mFont)) / 2;
    var textY = maxY + (smallFontHeight / 2) + (barHeight - smallFontHeight / 2 - fontHeight) / 2;
    dc.drawText(textX, textY, mFont, leftText, Graphics.TEXT_JUSTIFY_LEFT);
   
    var hr;
    var hrText;
    if (tap) {
      hr = (percentHRR * 100).format("%2d") + "%";
      hrText = "%HRR";
    } else {
      hr = "♥" + currentHeartRate;
      hrText = "Heart Rate";
    }
    if (currentHeartRate == 0) {
      hr = "--";
    }
    // Draw HR text title on the right side of the screen
    textX = screenWidth / 2 + ((screenWidth / 2) - dc.getTextWidthInPixels(hrText, smallFont)) / 2;
    dc.drawText(textX, maxY, smallFont, hrText, Graphics.TEXT_JUSTIFY_LEFT);

    // Draw HR value on the right side of the screen
    textX = screenWidth / 2 + ((screenWidth / 2) - dc.getTextWidthInPixels(hr, mFont)) / 2;
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
