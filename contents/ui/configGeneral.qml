import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property string cfg_locationName: "Brasov"
    property string cfg_locationNameDefault: "Brasov"
    property double cfg_latitude: 45.64860916137695
    property double cfg_latitudeDefault: 45.64860916137695
    property double cfg_longitude: 25.606130599975586
    property double cfg_longitudeDefault: 25.606130599975586
    property string cfg_timezone: "Europe/Bucharest"
    property string cfg_timezoneDefault: "Europe/Bucharest"
    property int cfg_hourlyCount: 8
    property int cfg_hourlyCountDefault: 8
    property int cfg_refreshMinutes: 30
    property int cfg_refreshMinutesDefault: 30
    property bool cfg_use24Hour: true
    property bool cfg_use24HourDefault: true
    property string cfg_fontFamily: ""
    property string cfg_fontFamilyDefault: ""
    property string cfg_fontWeight: "Light"
    property string cfg_fontWeightDefault: "Light"
    property string cfg_temperatureUnit: "celsius"
    property string cfg_temperatureUnitDefault: "celsius"
    property string cfg_windUnit: "kmh"
    property string cfg_windUnitDefault: "kmh"
    property string cfg_pressureUnit: "hPa"
    property string cfg_pressureUnitDefault: "hPa"
    property string cfg_distanceUnit: "km"
    property string cfg_distanceUnitDefault: "km"
    property string cfg_precipitationUnit: "mm"
    property string cfg_precipitationUnitDefault: "mm"
    property bool cfg_showFeelsLike: true
    property bool cfg_showFeelsLikeDefault: true
    property bool cfg_showHumidity: true
    property bool cfg_showHumidityDefault: true
    property bool cfg_showWind: true
    property bool cfg_showWindDefault: true
    property bool cfg_showGusts: true
    property bool cfg_showGustsDefault: true
    property bool cfg_showPressure: true
    property bool cfg_showPressureDefault: true
    property bool cfg_showVisibility: false
    property bool cfg_showVisibilityDefault: false
    property bool cfg_showCloudCover: false
    property bool cfg_showCloudCoverDefault: false
    property bool cfg_showPrecipitation: true
    property bool cfg_showPrecipitationDefault: true
    property bool cfg_showSunTimes: true
    property bool cfg_showSunTimesDefault: true
    property bool cfg_showUpdated: false
    property bool cfg_showUpdatedDefault: false
    title: i18n("General")

    property bool lookupBusy: false
    property string lookupError: ""
    property bool showAdvancedLocation: false

    readonly property int settingsColumns: width >= Kirigami.Units.gridUnit * 42 ? 2 : 1
    readonly property int cardMinimumWidth: Kirigami.Units.gridUnit * 18
    readonly property int comboMinimumWidth: Kirigami.Units.gridUnit * 10
    readonly property color frameColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
    readonly property color subtleFrameColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)

    implicitWidth: Kirigami.Units.gridUnit * 40

    function syncComboBox(comboBox, model, value) {
        if (!comboBox || !model) {
            return;
        }

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
        id: temperatureUnitsModel
        ListElement { text: "Celsius (\u00B0C)"; value: "celsius" }
        ListElement { text: "Fahrenheit (\u00B0F)"; value: "fahrenheit" }
        ListElement { text: "Kelvin (K)"; value: "kelvin" }
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

    onCfg_temperatureUnitChanged: syncComboBox(temperatureUnitComboBox, temperatureUnitsModel, cfg_temperatureUnit)
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
        syncComboBox(temperatureUnitComboBox, temperatureUnitsModel, cfg_temperatureUnit);
        syncComboBox(windUnitComboBox, windUnitsModel, cfg_windUnit);
        syncComboBox(pressureUnitComboBox, pressureUnitsModel, cfg_pressureUnit);
        syncComboBox(distanceUnitComboBox, distanceUnitsModel, cfg_distanceUnit);
        syncComboBox(precipitationUnitComboBox, precipitationUnitsModel, cfg_precipitationUnit);
    }

    Item {
        id: contents
        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: rootColumn.implicitHeight

        ColumnLayout {
            id: rootColumn
            anchors.left: parent.left
            anchors.right: parent.right
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
                    spacing: Kirigami.Units.mediumSpacing

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

                        Kirigami.SearchField {
                            id: locationSearchField
                            Layout.fillWidth: true
                            Layout.minimumWidth: page.cardMinimumWidth
                            placeholderText: i18n("Search city or town")
                            enabled: !lookupBusy
                            onAccepted: page.searchLocations()
                        }

                        QQC2.Button {
                            text: i18n("Search")
                            icon.name: "search"
                            display: QQC2.AbstractButton.TextBesideIcon
                            enabled: !lookupBusy && locationSearchField.text.trim().length >= 2
                            onClicked: page.searchLocations()
                        }
                    }

                    Kirigami.InlineMessage {
                        Layout.fillWidth: true
                        visible: lookupBusy || lookupError.length > 0
                        showCloseButton: false
                        type: lookupError.length > 0 ? Kirigami.MessageType.Error : Kirigami.MessageType.Information
                        text: lookupError.length > 0 ? lookupError : i18n("Looking up locations...")
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: visible ? Math.min(contentHeight, Kirigami.Units.gridUnit * 11) : 0
                        visible: locationResultsModel.count > 0
                        clip: true
                        interactive: contentHeight > height
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
                        border.color: page.subtleFrameColor

                        RowLayout {
                            id: selectedLocationRow
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                source: "mark-location-symbolic"
                                implicitWidth: Kirigami.Units.iconSizes.smallMedium
                                implicitHeight: Kirigami.Units.iconSizes.smallMedium
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                QQC2.Label {
                                    text: i18n("Selected location")
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
                    }

                    QQC2.Button {
                        text: showAdvancedLocation ? i18n("Hide advanced location fields") : i18n("Edit coordinates and timezone")
                        icon.name: showAdvancedLocation ? "go-up-symbolic" : "settings-configure"
                        display: QQC2.AbstractButton.TextBesideIcon
                        onClicked: showAdvancedLocation = !showAdvancedLocation
                    }

                    QQC2.Frame {
                        Layout.fillWidth: true
                        visible: showAdvancedLocation
                        padding: Kirigami.Units.mediumSpacing

                        background: Rectangle {
                            radius: Kirigami.Units.mediumSpacing
                            color: Kirigami.Theme.alternateBackgroundColor
                            border.color: page.subtleFrameColor
                        }

                        contentItem: Kirigami.FormLayout {
                            width: parent.width

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
            }

            GridLayout {
                Layout.fillWidth: true
                columns: page.settingsColumns
                rowSpacing: Kirigami.Units.largeSpacing
                columnSpacing: Kirigami.Units.largeSpacing

                QQC2.Frame {
                    Layout.fillWidth: true
                    Layout.minimumWidth: page.cardMinimumWidth
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
                    Layout.minimumWidth: page.cardMinimumWidth
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
                                Layout.minimumWidth: Kirigami.Units.gridUnit * 13
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
                                Layout.minimumWidth: page.comboMinimumWidth
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
                            text: i18n("Units")
                            level: 2
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: i18n("Choose how temperature, wind, pressure, visibility, and precipitation are displayed.")
                            color: Kirigami.Theme.disabledTextColor
                            wrapMode: Text.Wrap
                        }

                        Kirigami.FormLayout {
                            Layout.fillWidth: true

                            QQC2.ComboBox {
                                id: temperatureUnitComboBox
                                Kirigami.FormData.label: i18n("Temperature:")
                                Layout.minimumWidth: page.comboMinimumWidth
                                model: temperatureUnitsModel
                                textRole: "text"

                                onActivated: {
                                    const current = model.get(currentIndex);
                                    if (current) {
                                        page.cfg_temperatureUnit = current.value;
                                    }
                                }
                            }

                            QQC2.ComboBox {
                                id: windUnitComboBox
                                Kirigami.FormData.label: i18n("Wind:")
                                Layout.minimumWidth: page.comboMinimumWidth
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
                                Layout.minimumWidth: page.comboMinimumWidth
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
                                Layout.minimumWidth: page.comboMinimumWidth
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
                                Layout.minimumWidth: page.comboMinimumWidth
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

                QQC2.Frame {
                    Layout.fillWidth: true
                    Layout.columnSpan: page.settingsColumns
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
                            text: i18n("Popup Details")
                            level: 2
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: i18n("Choose which detail rows appear in the expanded forecast popup.")
                            color: Kirigami.Theme.disabledTextColor
                            wrapMode: Text.Wrap
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: page.settingsColumns
                            columnSpacing: Kirigami.Units.largeSpacing
                            rowSpacing: Kirigami.Units.smallSpacing

                            QQC2.CheckBox {
                                text: i18n("Feels like")
                                checked: page.cfg_showFeelsLike
                                onToggled: page.cfg_showFeelsLike = checked
                            }

                            QQC2.CheckBox {
                                text: i18n("Humidity")
                                checked: page.cfg_showHumidity
                                onToggled: page.cfg_showHumidity = checked
                            }

                            QQC2.CheckBox {
                                text: i18n("Wind")
                                checked: page.cfg_showWind
                                onToggled: page.cfg_showWind = checked
                            }

                            QQC2.CheckBox {
                                text: i18n("Gusts")
                                checked: page.cfg_showGusts
                                onToggled: page.cfg_showGusts = checked
                            }

                            QQC2.CheckBox {
                                text: i18n("Pressure")
                                checked: page.cfg_showPressure
                                onToggled: page.cfg_showPressure = checked
                            }

                            QQC2.CheckBox {
                                text: i18n("Visibility")
                                checked: page.cfg_showVisibility
                                onToggled: page.cfg_showVisibility = checked
                            }

                            QQC2.CheckBox {
                                text: i18n("Cloud cover")
                                checked: page.cfg_showCloudCover
                                onToggled: page.cfg_showCloudCover = checked
                            }

                            QQC2.CheckBox {
                                text: i18n("Precipitation")
                                checked: page.cfg_showPrecipitation
                                onToggled: page.cfg_showPrecipitation = checked
                            }

                            QQC2.CheckBox {
                                text: i18n("Sunrise and sunset")
                                checked: page.cfg_showSunTimes
                                onToggled: page.cfg_showSunTimes = checked
                            }

                            QQC2.CheckBox {
                                text: i18n("Updated time")
                                checked: page.cfg_showUpdated
                                onToggled: page.cfg_showUpdated = checked
                            }
                        }
                    }
                }
            }
        }
    }
}
