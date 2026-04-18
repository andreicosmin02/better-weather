import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: page

    property string cfg_locationName: "Brasov"
    property double cfg_latitude: 45.64860916137695
    property double cfg_longitude: 25.606130599975586
    property string cfg_timezone: "Europe/Bucharest"
    property int cfg_hourlyCount: 8
    property int cfg_refreshMinutes: 30
    property bool cfg_use24Hour: true
    property string cfg_fontFamily: ""
    property string cfg_fontWeight: "Light"
    property string cfg_windUnit: "kmh"
    property string cfg_pressureUnit: "hPa"
    property string cfg_distanceUnit: "km"
    property string cfg_precipitationUnit: "mm"
    property bool cfg_showFeelsLike: true
    property bool cfg_showHumidity: true
    property bool cfg_showWind: true
    property bool cfg_showGusts: true
    property bool cfg_showPressure: true
    property bool cfg_showVisibility: false
    property bool cfg_showCloudCover: false
    property bool cfg_showPrecipitation: true
    property bool cfg_showSunTimes: true
    property bool cfg_showUpdated: false

    property bool lookupBusy: false
    property string lookupError: ""
    property bool showAdvancedLocation: false

    readonly property int settingsColumns: width > Kirigami.Units.gridUnit * 30 ? 2 : 1
    readonly property color frameColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)

    implicitWidth: Kirigami.Units.gridUnit * 28
    implicitHeight: Kirigami.Units.gridUnit * 28

    function syncComboBox(comboBox, model, value) {
        for (let i = 0; i < model.count; ++i) {
            if (model.get(i).value === value) {
                comboBox.currentIndex = i;
                return;
            }
        }

        comboBox.currentIndex = 0;
    }

    function resultSubtitle(admin1, country) {
        const parts = [];

        if (String(admin1 || "").length > 0) {
            parts.push(admin1);
        }

        if (String(country || "").length > 0) {
            parts.push(country);
        }

        return parts.join(", ");
    }

    function applyLocation(name, latitude, longitude, timezone, subtitle) {
        cfg_locationName = name;
        cfg_latitude = Number(latitude);
        cfg_longitude = Number(longitude);
        cfg_timezone = String(timezone || "").trim().length > 0 ? timezone : cfg_timezone;

        locationNameField.text = cfg_locationName;
        latitudeField.text = Number(cfg_latitude).toString();
        longitudeField.text = Number(cfg_longitude).toString();
        timezoneField.text = cfg_timezone;
        locationSearchField.text = subtitle.length > 0 ? name + ", " + subtitle : name;

        lookupError = "";
        locationResultsModel.clear();
        showAdvancedLocation = false;
    }

    function searchLocations() {
        const query = locationSearchField.text.trim();

        locationResultsModel.clear();
        lookupError = "";

        if (query.length < 2) {
            lookupError = i18n("Enter at least 2 characters to search.");
            return;
        }

        const xhr = new XMLHttpRequest();
        const url = "https://geocoding-api.open-meteo.com/v1/search"
            + "?name=" + encodeURIComponent(query)
            + "&count=8"
            + "&language=en"
            + "&format=json";

        lookupBusy = true;

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) {
                return;
            }

            lookupBusy = false;

            if (xhr.status >= 200 && xhr.status < 300) {
                try {
                    const data = JSON.parse(xhr.responseText);
                    const results = data.results || [];

                    if (!results.length) {
                        lookupError = i18n("No matching locations found.");
                        return;
                    }

                    for (let i = 0; i < results.length; ++i) {
                        const result = results[i];
                        const subtitle = resultSubtitle(result.admin1, result.country);

                        locationResultsModel.append({
                            "locationName": String(result.name || ""),
                            "subtitle": subtitle,
                            "timezoneValue": String(result.timezone || ""),
                            "latitudeValue": Number(result.latitude),
                            "longitudeValue": Number(result.longitude)
                        });
                    }
                } catch (error) {
                    lookupError = i18n("Could not parse the location search results.");
                }
            } else {
                lookupError = i18n("Location search failed (%1).", xhr.status);
            }
        };

        xhr.open("GET", url);
        xhr.send();
    }

    ListModel {
        id: fontsModel

        Component.onCompleted: {
            const items = [{ "text": i18nc("Use default font", "Default"), "value": "" }];
            const families = Qt.fontFamilies();

            for (let i = 0; i < families.length; ++i) {
                items.push({ "text": families[i], "value": families[i] });
            }

            for (let i = 0; i < items.length; ++i) {
                append(items[i]);
            }

            syncComboBox(fontFamilyComboBox, fontsModel, cfg_fontFamily);
        }
    }

    ListModel {
        id: weightsModel
        ListElement { text: "Thin"; value: "Thin" }
        ListElement { text: "Extra Light"; value: "ExtraLight" }
        ListElement { text: "Light"; value: "Light" }
        ListElement { text: "Normal"; value: "Normal" }
        ListElement { text: "Medium"; value: "Medium" }
        ListElement { text: "Demi Bold"; value: "DemiBold" }
        ListElement { text: "Bold"; value: "Bold" }
    }

    ListModel {
        id: locationResultsModel
    }

    ListModel {
        id: windUnitsModel
        ListElement { text: "km/h"; value: "kmh" }
        ListElement { text: "m/s"; value: "ms" }
        ListElement { text: "mph"; value: "mph" }
    }

    ListModel {
        id: pressureUnitsModel
        ListElement { text: "hPa"; value: "hPa" }
        ListElement { text: "mmHg"; value: "mmHg" }
        ListElement { text: "inHg"; value: "inHg" }
    }

    ListModel {
        id: distanceUnitsModel
        ListElement { text: "km"; value: "km" }
        ListElement { text: "mi"; value: "mi" }
    }

    ListModel {
        id: precipitationUnitsModel
        ListElement { text: "mm"; value: "mm" }
        ListElement { text: "in"; value: "in" }
    }

    onCfg_fontFamilyChanged: syncComboBox(fontFamilyComboBox, fontsModel, cfg_fontFamily)
    onCfg_fontWeightChanged: syncComboBox(fontWeightComboBox, weightsModel, cfg_fontWeight)
    onCfg_windUnitChanged: syncComboBox(windUnitComboBox, windUnitsModel, cfg_windUnit)
    onCfg_pressureUnitChanged: syncComboBox(pressureUnitComboBox, pressureUnitsModel, cfg_pressureUnit)
    onCfg_distanceUnitChanged: syncComboBox(distanceUnitComboBox, distanceUnitsModel, cfg_distanceUnit)
    onCfg_precipitationUnitChanged: syncComboBox(precipitationUnitComboBox, precipitationUnitsModel, cfg_precipitationUnit)

    Component.onCompleted: {
        locationSearchField.text = cfg_locationName;
        syncComboBox(fontFamilyComboBox, fontsModel, cfg_fontFamily);
        syncComboBox(fontWeightComboBox, weightsModel, cfg_fontWeight);
        syncComboBox(windUnitComboBox, windUnitsModel, cfg_windUnit);
        syncComboBox(pressureUnitComboBox, pressureUnitsModel, cfg_pressureUnit);
        syncComboBox(distanceUnitComboBox, distanceUnitsModel, cfg_distanceUnit);
        syncComboBox(precipitationUnitComboBox, precipitationUnitsModel, cfg_precipitationUnit);
    }

    QQC2.ScrollView {
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth

        Item {
            width: availableWidth
            implicitHeight: rootColumn.implicitHeight + Kirigami.Units.largeSpacing * 2

            ColumnLayout {
                id: rootColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.largeSpacing

                QQC2.Frame {
                    Layout.fillWidth: true
                    padding: Kirigami.Units.largeSpacing

                    background: Rectangle {
                        radius: Kirigami.Units.largeSpacing
                        color: Kirigami.Theme.backgroundColor
                        border.color: page.frameColor
                    }

                    contentItem: ColumnLayout {
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Heading {
                            text: i18n("Location")
                            level: 2
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: i18n("Search for a city and pick a result. The widget fills in the coordinates automatically.")
                            color: Kirigami.Theme.disabledTextColor
                            wrapMode: Text.Wrap
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            QQC2.TextField {
                                id: locationSearchField
                                Layout.fillWidth: true
                                placeholderText: i18n("Search city or town")
                                onAccepted: page.searchLocations()
                            }

                            QQC2.Button {
                                text: i18n("Search")
                                onClicked: page.searchLocations()
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: lookupBusy
                            spacing: Kirigami.Units.smallSpacing

                            QQC2.BusyIndicator {
                                running: lookupBusy
                            }

                            QQC2.Label {
                                text: i18n("Looking up locations...")
                                color: Kirigami.Theme.disabledTextColor
                            }
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            visible: lookupError.length > 0
                            text: lookupError
                            color: Kirigami.Theme.negativeTextColor
                            wrapMode: Text.Wrap
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: visible ? Math.min(contentHeight, Kirigami.Units.gridUnit * 11) : 0
                            visible: locationResultsModel.count > 0
                            clip: true
                            spacing: Kirigami.Units.smallSpacing
                            model: locationResultsModel

                            delegate: QQC2.ItemDelegate {
                                width: ListView.view.width
                                onClicked: page.applyLocation(locationName, latitudeValue, longitudeValue, timezoneValue, subtitle)

                                contentItem: ColumnLayout {
                                    spacing: 2

                                    QQC2.Label {
                                        text: subtitle.length > 0 ? locationName + ", " + subtitle : locationName
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    QQC2.Label {
                                        text: i18n("Timezone: %1  |  %2, %3", timezoneValue, Number(latitudeValue).toFixed(3), Number(longitudeValue).toFixed(3))
                                        color: Kirigami.Theme.disabledTextColor
                                        wrapMode: Text.Wrap
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: selectedLocationRow.implicitHeight + Kirigami.Units.smallSpacing * 2
                            radius: Kirigami.Units.smallSpacing
                            color: Kirigami.Theme.alternateBackgroundColor
                            border.color: page.frameColor

                            RowLayout {
                                id: selectedLocationRow
                                anchors.fill: parent
                                anchors.margins: Kirigami.Units.smallSpacing
                                spacing: Kirigami.Units.smallSpacing

                                QQC2.Label {
                                    text: i18n("Selected")
                                    color: Kirigami.Theme.disabledTextColor
                                }

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: cfg_locationName + "  |  " + cfg_timezone
                                    font.weight: Font.DemiBold
                                    wrapMode: Text.Wrap
                                }
                            }
                        }

                        QQC2.Button {
                            text: showAdvancedLocation ? i18n("Hide advanced location fields") : i18n("Show advanced location fields")
                            onClicked: showAdvancedLocation = !showAdvancedLocation
                        }

                        Kirigami.FormLayout {
                            Layout.fillWidth: true
                            visible: showAdvancedLocation

                            QQC2.TextField {
                                id: locationNameField
                                Kirigami.FormData.label: i18n("Location name:")
                                text: page.cfg_locationName
                                onTextChanged: page.cfg_locationName = text
                            }

                            QQC2.TextField {
                                id: latitudeField
                                Kirigami.FormData.label: i18n("Latitude:")
                                text: Number(page.cfg_latitude).toString()
                                inputMethodHints: Qt.ImhFormattedNumbersOnly
                                onEditingFinished: {
                                    const parsed = Number(text);
                                    if (!Number.isNaN(parsed)) {
                                        page.cfg_latitude = parsed;
                                    }
                                }
                            }

                            QQC2.TextField {
                                id: longitudeField
                                Kirigami.FormData.label: i18n("Longitude:")
                                text: Number(page.cfg_longitude).toString()
                                inputMethodHints: Qt.ImhFormattedNumbersOnly
                                onEditingFinished: {
                                    const parsed = Number(text);
                                    if (!Number.isNaN(parsed)) {
                                        page.cfg_longitude = parsed;
                                    }
                                }
                            }

                            QQC2.TextField {
                                id: timezoneField
                                Kirigami.FormData.label: i18n("Timezone:")
                                text: page.cfg_timezone
                                onTextChanged: page.cfg_timezone = text
                            }
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: page.settingsColumns
                    rowSpacing: Kirigami.Units.largeSpacing
                    columnSpacing: Kirigami.Units.largeSpacing

                    QQC2.Frame {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        padding: Kirigami.Units.largeSpacing

                        background: Rectangle {
                            radius: Kirigami.Units.largeSpacing
                            color: Kirigami.Theme.backgroundColor
                            border.color: page.frameColor
                        }

                        contentItem: ColumnLayout {
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Heading {
                                text: i18n("Forecast")
                                level: 2
                            }

                            QQC2.Label {
                                Layout.fillWidth: true
                                text: i18n("Control how much forecast data appears in the popup and how often it refreshes.")
                                color: Kirigami.Theme.disabledTextColor
                                wrapMode: Text.Wrap
                            }

                            Kirigami.FormLayout {
                                Layout.fillWidth: true

                                QQC2.SpinBox {
                                    Kirigami.FormData.label: i18n("Hours shown:")
                                    from: 4
                                    to: 24
                                    value: page.cfg_hourlyCount
                                    onValueChanged: page.cfg_hourlyCount = value
                                }

                                QQC2.SpinBox {
                                    Kirigami.FormData.label: i18n("Refresh every:")
                                    from: 5
                                    to: 120
                                    stepSize: 5
                                    value: page.cfg_refreshMinutes
                                    textFromValue: function(value) { return i18n("%1 min", value); }
                                    valueFromText: function(text) { return parseInt(text, 10); }
                                    onValueChanged: page.cfg_refreshMinutes = value
                                }

                                QQC2.CheckBox {
                                    Kirigami.FormData.label: i18n("Time format:")
                                    text: i18n("Use 24-hour time")
                                    checked: page.cfg_use24Hour
                                    onToggled: page.cfg_use24Hour = checked
                                }
                            }
                        }
                    }

                    QQC2.Frame {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        padding: Kirigami.Units.largeSpacing

                        background: Rectangle {
                            radius: Kirigami.Units.largeSpacing
                            color: Kirigami.Theme.backgroundColor
                            border.color: page.frameColor
                        }

                        contentItem: ColumnLayout {
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Heading {
                                text: i18n("Appearance")
                                level: 2
                            }

                            QQC2.Label {
                                Layout.fillWidth: true
                                text: i18n("Tune the panel text style without editing the widget manually.")
                                color: Kirigami.Theme.disabledTextColor
                                wrapMode: Text.Wrap
                            }

                            Kirigami.FormLayout {
                                Layout.fillWidth: true

                                QQC2.ComboBox {
                                    id: fontFamilyComboBox
                                    Kirigami.FormData.label: i18n("Font family:")
                                    model: fontsModel
                                    textRole: "text"

                                    onActivated: {
                                        const current = model.get(currentIndex);
                                        if (current) {
                                            page.cfg_fontFamily = current.value;
                                        }
                                    }
                                }

                                QQC2.ComboBox {
                                    id: fontWeightComboBox
                                    Kirigami.FormData.label: i18n("Font weight:")
                                    model: weightsModel
                                    textRole: "text"

                                    onActivated: {
                                        const current = model.get(currentIndex);
                                        if (current) {
                                            page.cfg_fontWeight = current.value;
                                        }
                                    }
                                }

                                QQC2.Label {
                                    Kirigami.FormData.label: i18n("Source:")
                                    text: i18n("Open-Meteo forecast API")
                                    color: Kirigami.Theme.disabledTextColor
                                    wrapMode: Text.Wrap
                                }
                            }
                        }
                    }

                    QQC2.Frame {
                        Layout.fillWidth: true
                        Layout.columnSpan: page.settingsColumns
                        padding: Kirigami.Units.largeSpacing

                        background: Rectangle {
                            radius: Kirigami.Units.largeSpacing
                            color: Kirigami.Theme.backgroundColor
                            border.color: page.frameColor
                        }

                        contentItem: ColumnLayout {
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Heading {
                                text: i18n("Units")
                                level: 2
                            }

                            QQC2.Label {
                                Layout.fillWidth: true
                                text: i18n("Choose how wind, pressure, visibility, and precipitation are displayed.")
                                color: Kirigami.Theme.disabledTextColor
                                wrapMode: Text.Wrap
                            }

                            Kirigami.FormLayout {
                                Layout.fillWidth: true

                                QQC2.ComboBox {
                                    id: windUnitComboBox
                                    Kirigami.FormData.label: i18n("Wind:")
                                    model: windUnitsModel
                                    textRole: "text"

                                    onActivated: {
                                        const current = model.get(currentIndex);
                                        if (current) {
                                            page.cfg_windUnit = current.value;
                                        }
                                    }
                                }

                                QQC2.ComboBox {
                                    id: pressureUnitComboBox
                                    Kirigami.FormData.label: i18n("Pressure:")
                                    model: pressureUnitsModel
                                    textRole: "text"

                                    onActivated: {
                                        const current = model.get(currentIndex);
                                        if (current) {
                                            page.cfg_pressureUnit = current.value;
                                        }
                                    }
                                }

                                QQC2.ComboBox {
                                    id: distanceUnitComboBox
                                    Kirigami.FormData.label: i18n("Visibility:")
                                    model: distanceUnitsModel
                                    textRole: "text"

                                    onActivated: {
                                        const current = model.get(currentIndex);
                                        if (current) {
                                            page.cfg_distanceUnit = current.value;
                                        }
                                    }
                                }

                                QQC2.ComboBox {
                                    id: precipitationUnitComboBox
                                    Kirigami.FormData.label: i18n("Precipitation:")
                                    model: precipitationUnitsModel
                                    textRole: "text"

                                    onActivated: {
                                        const current = model.get(currentIndex);
                                        if (current) {
                                            page.cfg_precipitationUnit = current.value;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
