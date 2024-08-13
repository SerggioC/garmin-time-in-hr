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
  hidden var userHeartRateRanges as Lang.Array<String> = ["", "", "", "", "", "", ""];
  hidden var percentHeartRateRanges as Lang.Array<String> = ["", "", "", "", "", "", ""];
  hidden var mZoneColors as Lang.Array<Lang.Number> = [
    0x86F6FF, // light blue
    0x86F6FF, // light blue
    Graphics.COLOR_BLUE, 
    Graphics.COLOR_GREEN,
    0xFFD33A, // orange
    0xFA4747, // red
  ];
  hidden var timeInZoneFraction as Array<Lang.Float>;
  hidden var currentZoneDecimal as Float = 0.0;
  hidden var currentZone as Number = 0;
  hidden var bigFont = WatchUi.loadResource(Rez.Fonts.big_font);
  hidden var bigFontHeight = Graphics.getFontHeight(bigFont);
  hidden var smallFont = WatchUi.loadResource(Rez.Fonts.small_font);
  hidden var smallFontHeight = Graphics.getFontHeight(smallFont);
  hidden var currentHeartRate as Number = 0;
  hidden var averageHeartRate as Number = 0;
  hidden var restingHeartRate as Float = 0.0;
  hidden var percentHRR as Float = 0.0;
  hidden var tap = false as Boolean;
  hidden var cornerRadius as Number = 6;
  hidden var currentMaxHR as Number = 0;
  hidden var rectanglePenWidth = WatchUi.loadResource(Rez.Strings.rectanglePenWidth).toNumber();
  hidden var penWidth = rectanglePenWidth - 2;
  hidden var lastTimerState as Number = 0;

  function initialize() {
    DataField.initialize();
    
    timeInHeartRateZones = [0, 0, 0, 0, 0, 0];
    var currentSport = UserProfile.getCurrentSport() as UserProfile.SportHrZone;
    userHeartRateZones = UserProfile.getHeartRateZones(currentSport) as Lang.Array<Lang.Number>;

    var arraySize = userHeartRateZones.size();
    for (var i = 0; i < arraySize - 2; i++) {
      userHeartRateRanges[i] = userHeartRateZones[i] + " - " + (userHeartRateZones[i + 1] - 1);
    }
    userHeartRateRanges[arraySize - 2] = userHeartRateZones[arraySize - 2] + " - " + (userHeartRateZones[arraySize - 1]);

    var restingHR = UserProfile.getProfile().restingHeartRate as Number; 
    if (restingHR == null) {
      restingHeartRate = 0.0;
    } else {
      restingHeartRate = restingHR.toFloat();
    }

    var maxHR = userHeartRateZones[userHeartRateZones.size() - 1].toFloat();
    for (var i = 0; i < arraySize - 1; i++) {
      var percentHRR1 = (userHeartRateZones[i].toFloat() - restingHeartRate.toFloat()) / (maxHR - restingHeartRate);
      if (percentHRR1 < 0.0) {
        percentHRR1 = 0.0;
      } else if (percentHRR1 > 1.0) {
        percentHRR1 = 1.0;
      }
      var percentHRR2 = (userHeartRateZones[i + 1].toFloat() - restingHeartRate.toFloat()) / (maxHR - restingHeartRate);
      if (percentHRR2 < 0.0) {
        percentHRR2 = 0.0;
      } else if (percentHRR2 >= 1.0) {
        percentHRR2 = 1.01;
      }
      percentHeartRateRanges[i] = " " + (percentHRR1 * 100).format("%2d") + "% - " + (percentHRR2 * 100 - 1).format("%2d") + "%";
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
    var timerState = info.timerState as Number;
    var elapsedTime = info.elapsedTime as Number;
    var timerTime = info.timerTime as Number;
    System.println("compute. timerState: " + timerState + " elapsedTime: " + elapsedTime + " timerTime: " + timerTime);
    
    // Reset the time in zones when the timer is stopped
    if (timerState != lastTimerState && lastTimerState <= Activity.TIMER_STATE_STOPPED && timerState >= Activity.TIMER_STATE_PAUSED) {
      System.println("Reset time in zones");
      timeInHeartRateZones = [0, 0, 0, 0, 0, 0];
      timeInZoneFraction = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
      currentHeartRate = 0;
      averageHeartRate = 0;
      currentMaxHR = 0;
    }
    
    if (timerState != lastTimerState) {
      lastTimerState = timerState;
    }

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

      if (currentHeartRate > currentMaxHR) {
        currentMaxHR = currentHeartRate;
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

    var barHeight = screenHeight.toFloat() / (timeInHeartRateZones.size().toFloat());

    var triangleHeight = barHeight / 4.5;
    var triangleWidth = triangleHeight * 1.4;
    var barX = 0;
    var labelX = barX + minimumBarWidth + triangleWidth + 4;

    for (var indexBar = timeInHeartRateZones.size() - 1; indexBar > 0; indexBar--) {
      var indexZone = timeInHeartRateZones.size() - indexBar;

      var barY = (indexBar - 1) * barHeight; // indexBar - 1 to position at top of screen for zone 5
      var barColor = mZoneColors[indexZone];
      var barWidth = minimumBarWidth + timeInZoneFraction[indexZone] * (screenWidth - minimumBarWidth);
      dc.setColor(barColor, Graphics.COLOR_WHITE);
      dc.fillRectangle(barX, barY, barWidth, barHeight);

      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);

      var range;
      if (tap) {
        range = percentHeartRateRanges[indexZone - 1];
      } else {
        range = userHeartRateRanges[indexZone - 1];
      }
      var smallTextY = barY + barHeight - smallFontHeight - 2;
      dc.drawText(labelX, smallTextY, smallFont, range, Graphics.TEXT_JUSTIFY_LEFT);

      var labelText = "Z" + indexZone;
      if (timeInHeartRateZones[indexZone] > 0) {
        var timePercent = timeInZoneFraction[indexZone];
        labelText += " " + secondsToTimeString(timeInHeartRateZones[indexZone]);

        var dimentions = dc.getTextDimensions(range, smallFont);
        var widthRange = dimentions[0];
        
        var percentTime = (timePercent * 100).format("%2d") + "%";
        dimentions = dc.getTextDimensions(percentTime, smallFont);

        var percentXPos = labelX + widthRange + (screenWidth - widthRange - dimentions[0]) / 2;
        dc.drawText(percentXPos, smallTextY, smallFont, percentTime, Graphics.TEXT_JUSTIFY_LEFT);
      }

      // Z2 00:00:00 Draw the label for the zone and the time in the zone
      var labelY = barY + (barHeight - bigFontHeight - smallFontHeight) / 2 + 2;
      dc.drawText(labelX, labelY, bigFont, labelText, Graphics.TEXT_JUSTIFY_LEFT);


      // draw a black rectangle around the current zone
      if (currentZone == indexZone) {
        dc.setPenWidth(rectanglePenWidth);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(0, (indexBar - 1) * barHeight, screenWidth, barHeight, cornerRadius);
      }
    }

    // draw a triangle pointing right in the Z1 to Z5 area indicating the zone the user is in
    if (currentZoneDecimal > 0.9) {
      var triangleX = 6;
      var triangleY = screenHeight * (1 - (currentZoneDecimal / 6));
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
      dc.fillPolygon([
        [triangleX, triangleY - triangleHeight],      // Top vertex
        [triangleX + triangleWidth, triangleY],       // Right vertex
        [triangleX, triangleY + triangleHeight],      // Bottom vertex
      ]);
      
      // triangle pointing to the left with the same size as the abose triangle but aligned to the right side of the screen
      triangleX = screenWidth - triangleX;
      dc.fillPolygon([
        [triangleX, triangleY - triangleHeight],      // Top vertex
        [triangleX - triangleWidth, triangleY],       // Left vertex
        [triangleX, triangleY + triangleHeight],      // Bottom vertex
      ]);
    }

    var maxY = screenHeight - barHeight;
    
    // bar with %HRR
    var barColor = mZoneColors[currentZone];
    var barWidth = percentHRR * (screenWidth / 3);
    dc.setColor(barColor, Graphics.COLOR_WHITE);
    dc.fillRectangle(screenWidth * 2 / 3 + penWidth / 2, maxY + penWidth / 2, barWidth - penWidth / 2, barHeight);

    // draw horizontal line after z1
    dc.setPenWidth(penWidth);
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    dc.drawLine(0, maxY, screenWidth, maxY);

    // draw vertical centered line after z1
    //dc.drawLine(screenWidth / 2, maxY, screenWidth / 2, screenHeight);

    // draw 2 lines that devide the screen in 3 equal parts
    dc.drawLine(screenWidth / 3, maxY, screenWidth / 3, screenHeight);
    dc.drawLine(screenWidth * 2 / 3, maxY, screenWidth * 2 / 3, screenHeight);


    // text with current max heart rate zone on the left side of the screen
    var leftText = "Max HR";
    var textX = (screenWidth / 3 - dc.getTextWidthInPixels(leftText, smallFont)) / 2;
    dc.drawText(textX, maxY, smallFont, leftText, Graphics.TEXT_JUSTIFY_LEFT);
    leftText = currentMaxHR.toString();
    if (currentMaxHR == 0) {
      leftText = "--";
    }
    textX = (screenWidth / 3 - dc.getTextWidthInPixels(leftText, bigFont)) / 2;
    var textY = maxY + (smallFontHeight / 2) + (barHeight - smallFontHeight / 2 - bigFontHeight) / 2;
    dc.drawText(textX, textY, bigFont, leftText, Graphics.TEXT_JUSTIFY_LEFT);


    // text with current heart rate zone on the center of the screen
    var centerText = "Average";
    textX = (screenWidth - dc.getTextWidthInPixels(centerText, smallFont)) / 2;
    dc.drawText(textX, maxY, smallFont, centerText, Graphics.TEXT_JUSTIFY_LEFT);
    if (averageHeartRate == 0) {
      centerText = "--";
    } else {
      centerText = averageHeartRate.toString();
    }
    textX = (screenWidth - dc.getTextWidthInPixels(centerText, bigFont)) / 2;
    dc.drawText(textX, textY, bigFont, centerText, Graphics.TEXT_JUSTIFY_LEFT);
   
    var hr;
    var hrText;
    if (tap) {
      hr = (percentHRR * 100).format("%2d") + "%";
      hrText = "%HRR";
    } else {
      hr = currentHeartRate.toString();
      hrText = "♥ Rate";
    }
    if (currentHeartRate == 0) {
      hr = "--";
    }
    // Draw HR text title on the right side of the screen
    textX = screenWidth * 2 / 3 + ((screenWidth / 3) - dc.getTextWidthInPixels(hrText, smallFont)) / 2;
    dc.drawText(textX, maxY, smallFont, hrText, Graphics.TEXT_JUSTIFY_LEFT);

    // Draw HR value on the right side of the screen
    textX = screenWidth * 2 / 3 + ((screenWidth / 3) - dc.getTextWidthInPixels(hr, bigFont)) / 2;
    dc.drawText(textX, textY, bigFont, hr, Graphics.TEXT_JUSTIFY_LEFT);
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

}
