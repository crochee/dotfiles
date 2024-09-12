var panel = new Panel();
var panelScreen = panel.screen;

panel.location = "top";
panel.height = 2 * Math.floor((gridUnit * 13) / 18);
panel.width = screenGeometry(panelScreen).width;

panel.addWidget("org.kde.plasma.kickoff");
panel.addWidget("org.kde.plasma.appmenu");

panel.addWidget("org.kde.plasma.panelspacer");
panel.addWidget("org.kde.plasma.digitalclock");
panel.addWidget("org.kde.plasma.panelspacer");

panel.addWidget("org.kde.plasma.systemmonitor.net");
var langIds = [
  "as", // Assamese
  "bn", // Bengali
  "bo", // Tibetan
  "brx", // Bodo
  "doi", // Dogri
  "gu", // Gujarati
  "hi", // Hindi
  "ja", // Japanese
  "kn", // Kannada
  "ko", // Korean
  "kok", // Konkani
  "ks", // Kashmiri
  "lep", // Lepcha
  "mai", // Maithili
  "ml", // Malayalam
  "mni", // Manipuri
  "mr", // Marathi
  "ne", // Nepali
  "or", // Odia
  "pa", // Punjabi
  "sa", // Sanskrit
  "sat", // Santali
  "sd", // Sindhi
  "si", // Sinhala
  "ta", // Tamil
  "te", // Telugu
  "th", // Thai
  "ur", // Urdu
  "vi", // Vietnamese
  "zh_CN", // Simplified Chinese
  "zh_TW",
]; // Traditional Chinese
if (langIds.indexOf(languageId) != -1) {
  panel.addWidget("org.kde.plasma.kimpanel");
}
panel.addWidget("org.kde.plasma.systemtray");
panel.addWidget("org.kde.plasma.showdesktop");

var dock = new Panel();
dock.location = "bottom";
dock.height = 2 * Math.floor((gridUnit * 3) / 2);
dock.hiding = "autohide";
dock.minimumLength = 2 * Math.floor(gridUnit * 4);
dock.alignment = "center";
dock.offset = 0;

dock.addWidget("org.kde.plasma.pager");
dock.addWidget("org.kde.plasma.icontasks");

var downloads = dock.addWidget("org.kde.plasma.folder");
downloads.currentConfigGroup = ["General"];
downloads.writeConfig("labelMode", "3");
downloads.writeConfig("labelText", "Downloads");
downloads.writeConfig("url", `${userDataPath("downloads")}`);

dock.addWidget("org.kde.plasma.trash");

var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
  desktopsArray[j].wallpaperPlugin = "org.kde.image";
  var analogclock = desktopsArray[j].addWidget(
    "org.kde.plasma.analogclock",
    gridUnit * 33,
    gridUnit * 2,
    gridUnit * 10,
    gridUnit * 10,
  );
  analogclock.currentConfigGroup = ["General"];
  analogclock.writeConfig("showSecondHand", true);
}
