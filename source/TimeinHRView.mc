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
  hidden var currentZoneFraction as Float = 1.0;
  hidden var currentZone as Number = 0;
  hidden var mFont as Toybox.WatchUi.FontReference = WatchUi.loadResource(Rez.Fonts.id_system_font);

  function initialize() {
    DataField.initialize();
    mValue = 0.0f;
    timeInHeartRateZones = [0, 0, 0, 0, 0, 0];
    var currentSport = UserProfile.getCurrentSport() as UserProfile.SportHrZone;
    userHeartRateZones = UserProfile.getHeartRateZones(currentSport) as Lang.Array<Lang.Number>;

    System.println("Current sport: " + currentSport);
    System.println("Current zones: " + userHeartRateZones);
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
    if (info == null) {
      System.println("Info is null");
      return;
    }

    if (
      info has :currentHeartRate && info has :elapsedTime &&
      info.currentHeartRate != null &&
      info.elapsedTime != null && info.elapsedTime > 1000
    ) {
      var currentHeartRate = info.currentHeartRate as Number;

      var elapsedMilliSeconds = info.elapsedTime as Number;
      var elapsedSeconds = elapsedMilliSeconds / 1000;

    System.println("Current heart rate: " + currentHeartRate);

      currentZone = 0;
      if (currentHeartRate <= userHeartRateZones[0]) {
        currentZone = 0;
        currentZoneFraction = currentHeartRate.toFloat() / userHeartRateZones[0];
      } else {
        if (
          currentHeartRate > userHeartRateZones[0] &&
          currentHeartRate <= userHeartRateZones[1]
        ) {
          currentZone = 1;
        } else if (
          currentHeartRate > userHeartRateZones[1] &&
          currentHeartRate <= userHeartRateZones[2]
        ) {
          currentZone = 2;
        } else if (
          currentHeartRate > userHeartRateZones[2] &&
          currentHeartRate <= userHeartRateZones[3]
        ) {
          currentZone = 3;
        } else if (
          currentHeartRate > userHeartRateZones[3] &&
          currentHeartRate <= userHeartRateZones[4]
        ) {
          currentZone = 4;
        } else if (currentHeartRate >= userHeartRateZones[4]) {
          currentZone = 5;
        }
        currentZoneFraction =
          (currentHeartRate - userHeartRateZones[currentZone - 1]).toFloat() /
          (userHeartRateZones[currentZone] - userHeartRateZones[currentZone - 1]).toFloat();
      }

      if (currentZoneFraction > 1.0) {
        currentZoneFraction = 1.0;
      }

      // Update the time in the current zone and calculate fraction of time in each zone
      var timeInCurrentZone = (timeInHeartRateZones[currentZone] + 1) as Number;
      timeInHeartRateZones[currentZone] = timeInCurrentZone;
      var fraction = 0.0;
      if (elapsedSeconds > 0.0) {
        fraction = timeInCurrentZone.toFloat() / elapsedSeconds.toFloat();
      }
      if (fraction > 1.0) {
        fraction = 1.0;
      }
      timeInZoneFraction[currentZone] = fraction;

      for (var i = 0; i < userHeartRateZones.size(); i++) {
        if (i != currentZone) {
          var timeInZoneI = timeInHeartRateZones[i] as Number;
          var fractionI = 0.0;
          if (elapsedSeconds > 0.0) {
            fractionI = timeInZoneI.toFloat() / elapsedSeconds.toFloat();
          }
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

  hidden var cornerRadius as Number = 4;
  hidden var penWidth as Number = 4;

  function drawBarsOnScreen(dc as Dc) as Void {
    // Create the heart rate zone bars
    var screenWidth = dc.getWidth();
    var screenHeight = dc.getHeight();

    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
    dc.fillRectangle(0, 0, screenWidth, screenHeight);

    var minimumBarWidth = 8;
    var barVerticalSpacing = 0;
    var barHeight = screenHeight / (timeInHeartRateZones.size() - 1);

    for (var i = 1; i < timeInHeartRateZones.size(); i++) {
      var barX = 0;
      var barY = (i - 1) * barHeight + barVerticalSpacing; // i - 1 to position at top of screen for zone 1
      var barColor = mZoneColors[i];
      var barWidth = minimumBarWidth + timeInZoneFraction[i] * (screenWidth - minimumBarWidth);
      dc.setColor(barColor, Graphics.COLOR_WHITE);
      dc.fillRoundedRectangle(barX, barY, barWidth, barHeight, cornerRadius);

      var labelX = barX + minimumBarWidth + 30;
      Graphics.FONT_SYSTEM_LARGE
      var fontHeight = Graphics.getFontHeight(mFont);
      System.println("Font height: " + fontHeight);
      
      var labelY = barY + fontHeight / 2 + penWidth;
      var labelText = "Z" + i;
      if (timeInHeartRateZones[i] > 0) {
        labelText += " " + secondsToTimeString(timeInHeartRateZones[i]);
      }
      dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
      dc.drawText(labelX, labelY, mFont, labelText, Graphics.TEXT_JUSTIFY_LEFT);

      System.println(
          " Time in zone " + i + ": " + timeInHeartRateZones[i] +
          " currentZone: " + currentZone +
          " currentZoneFraction: " + currentZoneFraction +
          " TimeFraction: " + timeInZoneFraction[i] +
          " userHeartRateZones: " + userHeartRateZones
      );

      if (currentZone == i) {
        // draw a black rectangle around the current zone
        dc.setPenWidth(penWidth);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(0, (i - 1) * barHeight, screenWidth, barHeight, cornerRadius);

        // draw a triangle pointing right
        var triangleX = minimumBarWidth;
        var triangleY = barY + currentZoneFraction * (barHeight - penWidth);
        var triangleSize = 25;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillPolygon([
          [triangleX, triangleY - triangleSize / 2],
          [triangleX + triangleSize, triangleY],
          [triangleX, triangleY + triangleSize / 2],
        ]);
      }
    }
  }

  function secondsToTimeString(totalSeconds as Number) as String {
    var hours = totalSeconds / 3600;
    var minutes = (totalSeconds / 60) % 60;
    var seconds = totalSeconds % 60;
    var timeString = format("$1$:$2$:$3$", [
      hours.format("%01d"),
      minutes.format("%02d"),
      seconds.format("%02d"),
    ]);
    return timeString;
  }

  // Display the value you computed here. This will be called
  // once a second when the data field is visible.
  function onUpdate(dc as Dc) as Void {
    // Call parent's onUpdate(dc) to redraw the layout
    View.onUpdate(dc);
    drawBarsOnScreen(dc);
  }
}
