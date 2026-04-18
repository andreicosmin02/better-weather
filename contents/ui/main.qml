import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import QtQml 2.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0

PlasmoidItem {
    id: root

    preferredRepresentation: Plasmoid.compactRepresentation
    Plasmoid.backgroundHints: "ShadowBackground"

    property bool loading: false
    property string errorMessage: ""
    property string panelIconName: "weather-none-available"
    property string locationText: configuredLocationName()
    property string currentTemperatureText: "--"
    property string currentDescriptionText: i18n("Loading...")
    property string todayLabelText: ""
    property string highLowText: "--"
    property string feelsLikeText: "--"
    property string humidityText: "--"
    property string windText: "--"
    property string gustsText: "--"
    property string pressureText: "--"
    property string visibilityText: "--"
    property string precipitationAmountText: "--"
    property string cloudCoverText: "--"
    property string sunriseText: "--"
    property string sunsetText: "--"
    property string updatedText: ""
    property string nextHourTimeText: "--"
    property string nextHourDescriptionText: "--"
    property string nextHourTemperatureText: "--"
    property string nextHourPrecipitationText: "--"
    property string nextHourHumidityText: "--"
    property string nextHourWindText: "--"
    property string nextHourIconName: "weather-none-available"
    property int selectedHourIndex: 0
    property var forecastData: null
    property string uiFontFamily: {
        const family = String(Plasmoid.configuration.fontFamily || "").trim();
        return family.length > 0 ? family : Kirigami.Theme.defaultFont.family;
    }
    property int uiFontWeight: {
        switch (String(Plasmoid.configuration.fontWeight || "Light")) {
        case "Thin":
            return Font.Thin;
        case "ExtraLight":
            return Font.ExtraLight;
        case "Light":
            return Font.Light;
        case "Normal":
            return Font.Normal;
        case "Medium":
            return Font.Medium;
        case "DemiBold":
            return Font.DemiBold;
        case "Bold":
            return Font.Bold;
        default:
            return Font.Light;
        }
    }

    ListModel {
        id: hourlyModel
    }

    ListModel {
        id: dailyModel
    }

    ListModel {
        id: metricModel
    }

    function configuredLocationName() {
        const name = String(Plasmoid.configuration.locationName || "").trim();
        return name.length > 0 ? name : i18n("Weather");
    }

    function configuredLatitude() {
        return Number(Plasmoid.configuration.latitude);
    }

    function configuredLongitude() {
        return Number(Plasmoid.configuration.longitude);
    }

    function configuredTimezone() {
        const timezone = String(Plasmoid.configuration.timezone || "").trim();
        return timezone.length > 0 ? timezone : "auto";
    }

    function configuredHourlyCount() {
        const count = Number(Plasmoid.configuration.hourlyCount);
        return Number.isFinite(count) ? Math.max(4, Math.min(24, Math.round(count))) : 8;
    }

    function configuredRefreshMinutes() {
        const minutes = Number(Plasmoid.configuration.refreshMinutes);
        return Number.isFinite(minutes) ? Math.max(5, Math.min(120, Math.round(minutes))) : 30;
    }

    function configuredWindUnit() {
        const value = String(Plasmoid.configuration.windUnit || "kmh");
        return ["kmh", "ms", "mph"].includes(value) ? value : "kmh";
    }

    function configuredPressureUnit() {
        const value = String(Plasmoid.configuration.pressureUnit || "hPa");
        return ["hPa", "mmHg", "inHg"].includes(value) ? value : "hPa";
    }

    function configuredDistanceUnit() {
        const value = String(Plasmoid.configuration.distanceUnit || "km");
        return ["km", "mi"].includes(value) ? value : "km";
    }

    function configuredPrecipitationUnit() {
        const value = String(Plasmoid.configuration.precipitationUnit || "mm");
        return ["mm", "in"].includes(value) ? value : "mm";
    }

    function formatNumber(value, decimals) {
        if (!Number.isFinite(Number(value))) {
            return "--";
        }

        if (decimals <= 0) {
            return String(Math.round(Number(value)));
        }

        return (Math.round(Number(value) * Math.pow(10, decimals)) / Math.pow(10, decimals)).toFixed(decimals);
    }

    function formatTemperature(value) {
        if (!Number.isFinite(Number(value))) {
            return "--";
        }
        return Math.round(Number(value)) + "\u00B0";
    }

    function formatPercent(value) {
        if (!Number.isFinite(Number(value))) {
            return "--";
        }
        return Math.round(Number(value)) + "%";
    }

    function formatSpeed(value) {
        if (!Number.isFinite(Number(value))) {
            return "--";
        }

        switch (configuredWindUnit()) {
        case "ms":
            return formatNumber(Number(value) / 3.6, 1) + " m/s";
        case "mph":
            return formatNumber(Number(value) * 0.621371, 0) + " mph";
        default:
            return formatNumber(Number(value), 0) + " km/h";
        }
    }

    function formatPressure(value) {
        if (!Number.isFinite(Number(value))) {
            return "--";
        }

        switch (configuredPressureUnit()) {
        case "mmHg":
            return formatNumber(Number(value) * 0.750061683, 0) + " mmHg";
        case "inHg":
            return formatNumber(Number(value) * 0.0295299831, 2) + " inHg";
        default:
            return formatNumber(Number(value), 0) + " hPa";
        }
    }

    function formatDistance(value) {
        if (!Number.isFinite(Number(value))) {
            return "--";
        }

        const kilometers = Number(value) / 1000;

        if (configuredDistanceUnit() === "mi") {
            const miles = kilometers * 0.621371;
            return (miles >= 10 ? formatNumber(miles, 0) : formatNumber(miles, 1)) + " mi";
        }

        return (kilometers >= 10 ? formatNumber(kilometers, 0) : formatNumber(kilometers, 1)) + " km";
    }

    function formatPrecipitation(value) {
        if (!Number.isFinite(Number(value))) {
            return "--";
        }

        if (configuredPrecipitationUnit() === "in") {
            return formatNumber(Number(value) * 0.0393701, 2) + " in";
        }

        return formatNumber(Number(value), 1) + " mm";
    }

    function cardinalDirection(degrees) {
        if (!Number.isFinite(Number(degrees))) {
            return "";
        }

        const directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];
        const index = Math.round(Number(degrees) / 45) % directions.length;
        return directions[index];
    }

    function formatWind(speed, direction) {
        const speedText = formatSpeed(speed);
        const directionText = cardinalDirection(direction);

        if (speedText === "--") {
            return "--";
        }

        return directionText.length > 0 ? speedText + " " + directionText : speedText;
    }

    function formatTime(isoString) {
        if (!isoString) {
            return "--";
        }
        const date = new Date(isoString);
        return Qt.formatTime(date, Plasmoid.configuration.use24Hour ? "HH:mm" : "h:mm AP");
    }

    function formatDay(dateString) {
        if (!dateString) {
            return "";
        }
        const date = new Date(dateString + "T12:00:00");
        return Qt.formatDate(date, "dddd, d MMMM");
    }

    function formatShortDay(dateString) {
        if (!dateString) {
            return "";
        }
        const date = new Date(dateString + "T12:00:00");
        return Qt.formatDate(date, "ddd, d MMM");
    }

    function currentDateKey() {
        return Qt.formatDate(new Date(), "yyyy-MM-dd");
    }

    function currentDateTimeKey() {
        return Qt.formatDateTime(new Date(), "yyyy-MM-dd'T'HH:mm");
    }

    function resolveCurrentDayIndex(days) {
        const currentDate = currentDateKey();
        let dayIndex = 0;

        for (let i = 0; i < days.length; ++i) {
            if (String(days[i]) >= currentDate) {
                dayIndex = i;
                break;
            }
        }

        if (days.length > 0 && String(days[days.length - 1]) < currentDate) {
            dayIndex = days.length - 1;
        }

        return dayIndex;
    }

    function weatherDescription(code) {
        switch (Number(code)) {
        case 0:
            return i18n("Clear");
        case 1:
            return i18n("Mostly clear");
        case 2:
            return i18n("Partly cloudy");
        case 3:
            return i18n("Overcast");
        case 45:
        case 48:
            return i18n("Fog");
        case 51:
        case 53:
        case 55:
        case 56:
        case 57:
            return i18n("Drizzle");
        case 61:
        case 63:
        case 65:
        case 66:
        case 67:
            return i18n("Rain");
        case 71:
        case 73:
        case 75:
        case 77:
            return i18n("Snow");
        case 80:
        case 81:
        case 82:
            return i18n("Rain showers");
        case 85:
        case 86:
            return i18n("Snow showers");
        case 95:
            return i18n("Thunderstorm");
        case 96:
        case 99:
            return i18n("Thunderstorm with hail");
        default:
            return i18n("Weather unavailable");
        }
    }

    function weatherIconName(code, isDay) {
        switch (Number(code)) {
        case 0:
            return isDay ? "weather-clear" : "weather-clear-night";
        case 1:
            return isDay ? "weather-few-clouds" : "weather-few-clouds-night";
        case 2:
            return isDay ? "weather-clouds" : "weather-clouds-night";
        case 3:
            return "weather-overcast";
        case 45:
        case 48:
            return "weather-fog";
        case 51:
        case 53:
        case 55:
        case 56:
        case 57:
            return "weather-showers-scattered";
        case 61:
        case 63:
        case 65:
        case 66:
        case 67:
            return "weather-showers";
        case 71:
        case 73:
        case 75:
        case 77:
            return "weather-snow";
        case 80:
        case 81:
        case 82:
            return "weather-showers";
        case 85:
        case 86:
            return "weather-snow-scattered";
        case 95:
        case 96:
        case 99:
            return "weather-storm";
        default:
            return "weather-none-available";
        }
    }

    function forecastUrl() {
        const latitude = configuredLatitude();
        const longitude = configuredLongitude();
        const timezone = configuredTimezone();

        return "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + encodeURIComponent(latitude)
            + "&longitude=" + encodeURIComponent(longitude)
            + "&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,wind_speed_10m,wind_gusts_10m,wind_direction_10m,surface_pressure,cloud_cover,visibility,weather_code,is_day"
            + "&hourly=temperature_2m,relative_humidity_2m,precipitation_probability,wind_speed_10m,wind_direction_10m,weather_code,is_day"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset"
            + "&forecast_days=6"
            + "&timezone=" + encodeURIComponent(timezone);
    }

    function resetHourlySummary() {
        selectedHourIndex = 0;
        nextHourTimeText = "--";
        nextHourDescriptionText = "--";
        nextHourTemperatureText = "--";
        nextHourPrecipitationText = "--";
        nextHourHumidityText = "--";
        nextHourWindText = "--";
        nextHourIconName = "weather-none-available";
    }

    function selectHour(index) {
        if (index < 0 || index >= hourlyModel.count) {
            return;
        }

        const item = hourlyModel.get(index);
        selectedHourIndex = index;
        nextHourTimeText = item.timeLabel;
        nextHourDescriptionText = item.description;
        nextHourTemperatureText = item.temperature;
        nextHourPrecipitationText = item.precipitation;
        nextHourHumidityText = item.humidity;
        nextHourWindText = item.wind;
        nextHourIconName = item.iconName;
    }

    function refreshMetricModel() {
        metricModel.clear();

        function appendMetric(label, value) {
            metricModel.append({
                "label": label,
                "value": value
            });
        }

        if (Plasmoid.configuration.showFeelsLike) {
            appendMetric(i18n("Feels like"), feelsLikeText);
        }

        if (Plasmoid.configuration.showHumidity) {
            appendMetric(i18n("Humidity"), humidityText);
        }

        if (Plasmoid.configuration.showWind) {
            appendMetric(i18n("Wind"), windText);
        }

        if (Plasmoid.configuration.showGusts) {
            appendMetric(i18n("Gusts"), gustsText);
        }

        if (Plasmoid.configuration.showPressure) {
            appendMetric(i18n("Pressure"), pressureText);
        }

        if (Plasmoid.configuration.showVisibility) {
            appendMetric(i18n("Visibility"), visibilityText);
        }

        if (Plasmoid.configuration.showCloudCover) {
            appendMetric(i18n("Cloud cover"), cloudCoverText);
        }

        if (Plasmoid.configuration.showPrecipitation) {
            appendMetric(i18n("Precipitation"), precipitationAmountText);
        }

        if (Plasmoid.configuration.showSunTimes) {
            appendMetric(i18n("Sunrise"), sunriseText);
            appendMetric(i18n("Sunset"), sunsetText);
        }

        if (Plasmoid.configuration.showUpdated) {
            appendMetric(i18n("Updated"), updatedText);
        }
    }

    function populateHourlyData(hourly, currentTime) {
        const previouslySelectedTime = selectedHourIndex > 0 && selectedHourIndex < hourlyModel.count
            ? String(hourlyModel.get(selectedHourIndex).timeKey || "")
            : "";

        hourlyModel.clear();
        resetHourlySummary();

        const times = hourly.time || [];
        const maxItems = configuredHourlyCount();
        const referenceTime = currentDateTimeKey();
        let startIndex = -1;

        for (let i = 0; i < times.length; ++i) {
            if (String(times[i]) > referenceTime) {
                startIndex = i;
                break;
            }
        }

        if (startIndex < 0) {
            startIndex = Math.max(0, times.length - maxItems);
        }

        for (let i = startIndex; i < times.length && hourlyModel.count < maxItems; ++i) {
            const item = {
                "timeKey": String(times[i]),
                "timeLabel": formatTime(times[i]),
                "description": weatherDescription(hourly.weather_code[i]),
                "temperature": formatTemperature(hourly.temperature_2m[i]),
                "humidity": formatPercent(hourly.relative_humidity_2m[i]),
                "precipitation": formatPercent(hourly.precipitation_probability[i]),
                "wind": formatWind(hourly.wind_speed_10m[i], hourly.wind_direction_10m[i]),
                "iconName": weatherIconName(hourly.weather_code[i], Number(hourly.is_day[i]) === 1)
            };

            hourlyModel.append(item);
        }

        if (hourlyModel.count > 0) {
            let restoredIndex = 0;

            if (previouslySelectedTime.length > 0) {
                for (let i = 0; i < hourlyModel.count; ++i) {
                    if (String(hourlyModel.get(i).timeKey) === previouslySelectedTime) {
                        restoredIndex = i;
                        break;
                    }
                }
            }

            selectHour(restoredIndex);
        }
    }

    function populateDailyData(daily) {
        dailyModel.clear();

        const days = daily.time || [];
        const startIndex = resolveCurrentDayIndex(days);

        for (let i = startIndex + 1; i < days.length; ++i) {
            dailyModel.append({
                "dayLabel": formatShortDay(days[i]),
                "description": weatherDescription(daily.weather_code[i]),
                "temperatureRange": formatTemperature(daily.temperature_2m_max[i]) + " / " + formatTemperature(daily.temperature_2m_min[i]),
                "iconName": weatherIconName(daily.weather_code[i], true)
            });
        }
    }

    function applyForecast(data) {
        const dailyTimes = data.daily.time || [];
        const todayIndex = resolveCurrentDayIndex(dailyTimes);

        forecastData = data;
        locationText = configuredLocationName();
        panelIconName = weatherIconName(data.current.weather_code, Number(data.current.is_day) === 1);
        currentTemperatureText = formatTemperature(data.current.temperature_2m);
        currentDescriptionText = weatherDescription(data.current.weather_code);
        todayLabelText = formatDay(dailyTimes[todayIndex]);
        highLowText = formatTemperature(data.daily.temperature_2m_max[todayIndex]) + " / " + formatTemperature(data.daily.temperature_2m_min[todayIndex]);
        feelsLikeText = formatTemperature(data.current.apparent_temperature);
        humidityText = formatPercent(data.current.relative_humidity_2m);
        windText = formatWind(data.current.wind_speed_10m, data.current.wind_direction_10m);
        gustsText = formatSpeed(data.current.wind_gusts_10m);
        pressureText = formatPressure(data.current.surface_pressure);
        visibilityText = formatDistance(data.current.visibility);
        precipitationAmountText = formatPrecipitation(data.current.precipitation);
        cloudCoverText = formatPercent(data.current.cloud_cover);
        sunriseText = formatTime(data.daily.sunrise[todayIndex]);
        sunsetText = formatTime(data.daily.sunset[todayIndex]);
        updatedText = formatTime(data.current.time);
        populateHourlyData(data.hourly, data.current.time);
        populateDailyData(data.daily);
        refreshMetricModel();
    }

    function requestForecast() {
        const latitude = configuredLatitude();
        const longitude = configuredLongitude();

        if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
            errorMessage = i18n("Configure a valid latitude and longitude.");
            loading = false;
            hourlyModel.clear();
            dailyModel.clear();
            resetHourlySummary();
            return;
        }

        const xhr = new XMLHttpRequest();
        const url = forecastUrl();

        loading = true;
        errorMessage = "";

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) {
                return;
            }

            loading = false;

            if (xhr.status >= 200 && xhr.status < 300) {
                try {
                    const data = JSON.parse(xhr.responseText);
                    applyForecast(data);
                } catch (error) {
                    errorMessage = i18n("The forecast response could not be parsed.");
                }
            } else {
                errorMessage = i18n("Forecast request failed (%1).", xhr.status);
            }
        };

        xhr.open("GET", url);
        xhr.send();
    }

    Connections {
        target: Plasmoid.configuration

        function onLocationNameChanged() { root.locationText = root.configuredLocationName(); }
        function onLatitudeChanged() { root.requestForecast(); }
        function onLongitudeChanged() { root.requestForecast(); }
        function onTimezoneChanged() { root.requestForecast(); }
        function onHourlyCountChanged() { root.requestForecast(); }
        function onRefreshMinutesChanged() { refreshTimer.interval = root.configuredRefreshMinutes() * 60 * 1000; }
        function onUse24HourChanged() { if (root.forecastData) { root.applyForecast(root.forecastData); } else { root.requestForecast(); } }
        function onShowFeelsLikeChanged() { root.refreshMetricModel(); }
        function onShowHumidityChanged() { root.refreshMetricModel(); }
        function onShowWindChanged() { root.refreshMetricModel(); }
        function onShowGustsChanged() { root.refreshMetricModel(); }
        function onShowPressureChanged() { root.refreshMetricModel(); }
        function onShowVisibilityChanged() { root.refreshMetricModel(); }
        function onShowCloudCoverChanged() { root.refreshMetricModel(); }
        function onShowPrecipitationChanged() { root.refreshMetricModel(); }
        function onShowSunTimesChanged() { root.refreshMetricModel(); }
        function onShowUpdatedChanged() { root.refreshMetricModel(); }
        function onWindUnitChanged() { if (root.forecastData) { root.applyForecast(root.forecastData); } }
        function onPressureUnitChanged() { if (root.forecastData) { root.applyForecast(root.forecastData); } }
        function onDistanceUnitChanged() { if (root.forecastData) { root.applyForecast(root.forecastData); } }
        function onPrecipitationUnitChanged() { if (root.forecastData) { root.applyForecast(root.forecastData); } }
    }

    Timer {
        id: refreshTimer
        interval: configuredRefreshMinutes() * 60 * 1000
        repeat: true
        running: true
        onTriggered: root.requestForecast()
    }

    Timer {
        id: presentationRefreshTimer
        interval: 60 * 1000
        repeat: true
        running: true
        onTriggered: {
            if (root.forecastData) {
                root.applyForecast(root.forecastData);
            }
        }
    }

    Component.onCompleted: {
        locationText = configuredLocationName();
        requestForecast();
    }

    compactRepresentation: MouseArea {
        id: compactArea
        implicitWidth: compactRow.implicitWidth + Kirigami.Units.smallSpacing * 2
        implicitHeight: Math.max(compactRow.implicitHeight, Kirigami.Units.iconSizes.smallMedium)
        width: implicitWidth
        height: implicitHeight
        Layout.minimumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth
        Layout.maximumWidth: implicitWidth
        Layout.minimumHeight: implicitHeight
        Layout.preferredHeight: implicitHeight
        Layout.maximumHeight: implicitHeight
        hoverEnabled: true
        clip: true
        onClicked: root.expanded = !root.expanded

        RowLayout {
            id: compactRow
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: root.panelIconName
                implicitWidth: Kirigami.Units.iconSizes.smallMedium
                implicitHeight: Kirigami.Units.iconSizes.smallMedium
            }

            QQC2.Label {
                text: root.currentTemperatureText
                color: Kirigami.Theme.textColor
                font.family: root.uiFontFamily
                font.weight: root.uiFontWeight
            }
        }
    }

    fullRepresentation: Item {
        id: popupRoot
        implicitWidth: Kirigami.Units.gridUnit * 34
        implicitHeight: Kirigami.Units.gridUnit * 22
        Layout.minimumWidth: Kirigami.Units.gridUnit * 34

        readonly property color frameColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
        readonly property color subtleFrameColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
        readonly property int outerPadding: Kirigami.Units.largeSpacing
        readonly property int cardPadding: Kirigami.Units.largeSpacing
        readonly property int sectionGap: Kirigami.Units.mediumSpacing
        readonly property int cardRadius: Kirigami.Units.largeSpacing

        QQC2.ScrollView {
            anchors.fill: parent
            clip: true

            Item {
                width: parent.width
                implicitHeight: contentColumn.implicitHeight + popupRoot.outerPadding * 2

                ColumnLayout {
                    id: contentColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: popupRoot.outerPadding
                    spacing: popupRoot.sectionGap

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.minimumWidth: Kirigami.Units.gridUnit * 32
                        implicitHeight: headerContent.implicitHeight + popupRoot.cardPadding * 2
                        color: Kirigami.Theme.alternateBackgroundColor
                        radius: popupRoot.cardRadius
                        border.color: popupRoot.frameColor

                        ColumnLayout {
                            id: headerContent
                            anchors.fill: parent
                            anchors.margins: popupRoot.cardPadding
                            spacing: popupRoot.sectionGap

                            Item {
                                id: headerSummary
                                Layout.fillWidth: true
                                implicitHeight: Math.max(leftWeatherColumn.implicitHeight, rightWeatherColumn.implicitHeight)

                                Column {
                                    id: leftWeatherColumn
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.right: rightWeatherColumn.left
                                    anchors.rightMargin: Kirigami.Units.largeSpacing
                                    spacing: 2

                                    QQC2.Label {
                                        width: parent.width
                                        text: root.locationText
                                        font.family: root.uiFontFamily
                                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.35
                                        font.weight: root.uiFontWeight
                                        elide: Text.ElideRight
                                    }

                                    QQC2.Label {
                                        width: parent.width
                                        text: root.todayLabelText
                                        font.family: root.uiFontFamily
                                        font.weight: root.uiFontWeight
                                        color: Kirigami.Theme.disabledTextColor
                                    }

                                    QQC2.Label {
                                        width: parent.width
                                        text: root.currentDescriptionText
                                        font.family: root.uiFontFamily
                                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.1
                                        font.weight: root.uiFontWeight
                                        wrapMode: Text.Wrap
                                    }

                                    QQC2.Label {
                                        width: parent.width
                                        text: i18n("High/Low %1", root.highLowText)
                                        font.family: root.uiFontFamily
                                        font.weight: root.uiFontWeight
                                        color: Kirigami.Theme.disabledTextColor
                                    }
                                }

                                Column {
                                    id: rightWeatherColumn
                                    readonly property real contentWidth: Math.max(weatherIcon.implicitWidth, temperatureLabel.implicitWidth, updatedLabel.visible ? updatedLabel.implicitWidth : 0)
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    width: contentWidth
                                    spacing: 4

                                    Item {
                                        width: rightWeatherColumn.contentWidth
                                        height: weatherIcon.implicitHeight

                                        Kirigami.Icon {
                                            id: weatherIcon
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            source: root.panelIconName
                                            implicitWidth: Kirigami.Units.iconSizes.large
                                            implicitHeight: Kirigami.Units.iconSizes.large
                                        }
                                    }

                                    QQC2.Label {
                                        id: temperatureLabel
                                        width: rightWeatherColumn.contentWidth
                                        text: root.currentTemperatureText
                                        font.family: root.uiFontFamily
                                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 2.2
                                        font.weight: root.uiFontWeight
                                        horizontalAlignment: Text.AlignRight
                                    }

                                    QQC2.Label {
                                        id: updatedLabel
                                        visible: root.updatedText.length > 0 && root.updatedText !== "--"
                                        width: rightWeatherColumn.contentWidth
                                        text: i18n("Updated %1", root.updatedText)
                                        font.family: root.uiFontFamily
                                        font.weight: root.uiFontWeight
                                        color: Kirigami.Theme.disabledTextColor
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                visible: metricModel.count > 0
                                columns: width > Kirigami.Units.gridUnit * 28 ? 4 : 2
                                rowSpacing: Kirigami.Units.smallSpacing
                                columnSpacing: Kirigami.Units.smallSpacing

                                Repeater {
                                    model: metricModel

                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: Kirigami.Units.gridUnit * 7
                                        implicitHeight: statContent.implicitHeight + Kirigami.Units.smallSpacing * 2
                                        color: Kirigami.Theme.backgroundColor
                                        radius: Kirigami.Units.smallSpacing
                                        border.color: popupRoot.subtleFrameColor

                                        ColumnLayout {
                                            id: statContent
                                            anchors.fill: parent
                                            anchors.margins: Kirigami.Units.smallSpacing
                                            spacing: 2

                                            QQC2.Label {
                                                text: label
                                                font.family: root.uiFontFamily
                                                font.weight: root.uiFontWeight
                                                color: Kirigami.Theme.disabledTextColor
                                                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.9
                                            }

                                            QQC2.Label {
                                                text: value
                                                font.family: root.uiFontFamily
                                                font.weight: root.uiFontWeight
                                                wrapMode: Text.Wrap
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        visible: hourlyModel.count > 0
                        implicitHeight: hourlySection.implicitHeight + popupRoot.cardPadding * 2
                        color: Kirigami.Theme.backgroundColor
                        radius: popupRoot.cardRadius
                        border.color: popupRoot.frameColor

                        ColumnLayout {
                            id: hourlySection
                            anchors.fill: parent
                            anchors.margins: popupRoot.cardPadding
                            spacing: popupRoot.sectionGap

                            QQC2.Label {
                                text: i18n("Upcoming hours")
                                font.family: root.uiFontFamily
                                font.weight: root.uiFontWeight
                            }

                            ListView {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 7
                                orientation: ListView.Horizontal
                                spacing: popupRoot.sectionGap
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds
                                model: hourlyModel

                                delegate: Rectangle {
                                    width: Kirigami.Units.gridUnit * 6
                                    height: ListView.view.height
                                    radius: Kirigami.Units.largeSpacing
                                    color: index === root.selectedHourIndex ? Kirigami.Theme.backgroundColor : Kirigami.Theme.alternateBackgroundColor
                                    border.color: index === root.selectedHourIndex ? popupRoot.frameColor : popupRoot.subtleFrameColor

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: Kirigami.Units.smallSpacing
                                        spacing: 4

                                        QQC2.Label {
                                            text: timeLabel
                                            Layout.alignment: Qt.AlignHCenter
                                            font.family: root.uiFontFamily
                                            font.weight: root.uiFontWeight
                                        }

                                        Kirigami.Icon {
                                            source: iconName
                                            implicitWidth: Kirigami.Units.iconSizes.smallMedium
                                            implicitHeight: Kirigami.Units.iconSizes.smallMedium
                                            Layout.alignment: Qt.AlignHCenter
                                        }

                                        QQC2.Label {
                                            text: temperature
                                            font.family: root.uiFontFamily
                                            font.weight: root.uiFontWeight
                                            Layout.alignment: Qt.AlignHCenter
                                        }

                                        QQC2.Label {
                                            text: i18n("Rain %1", precipitation)
                                            font.family: root.uiFontFamily
                                            font.weight: root.uiFontWeight
                                            color: Kirigami.Theme.disabledTextColor
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.selectHour(index)
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        visible: hourlyModel.count > 0
                        implicitHeight: nextHourContent.implicitHeight + popupRoot.cardPadding * 2
                        color: Kirigami.Theme.alternateBackgroundColor
                        radius: popupRoot.cardRadius
                        border.color: popupRoot.frameColor

                        RowLayout {
                            id: nextHourContent
                            anchors.fill: parent
                            anchors.margins: popupRoot.cardPadding
                            spacing: popupRoot.sectionGap

                            Kirigami.Icon {
                                source: root.nextHourIconName
                                implicitWidth: Kirigami.Units.iconSizes.large
                                implicitHeight: Kirigami.Units.iconSizes.large
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                QQC2.Label {
                                    text: root.selectedHourIndex === 0 ? i18n("Next hour") : i18n("Selected hour")
                                    font.family: root.uiFontFamily
                                    font.weight: root.uiFontWeight
                                    color: Kirigami.Theme.disabledTextColor
                                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.9
                                }

                                QQC2.Label {
                                    text: root.nextHourTimeText + "  " + root.nextHourDescriptionText
                                    font.family: root.uiFontFamily
                                    font.weight: root.uiFontWeight
                                    wrapMode: Text.Wrap
                                }

                                QQC2.Label {
                                    text: i18n("Rain %1  |  Humidity %2", root.nextHourPrecipitationText, root.nextHourHumidityText)
                                    font.family: root.uiFontFamily
                                    font.weight: root.uiFontWeight
                                    color: Kirigami.Theme.disabledTextColor
                                    wrapMode: Text.Wrap
                                }

                                QQC2.Label {
                                    text: i18n("Wind %1", root.nextHourWindText)
                                    font.family: root.uiFontFamily
                                    font.weight: root.uiFontWeight
                                    color: Kirigami.Theme.disabledTextColor
                                    wrapMode: Text.Wrap
                                }
                            }

                            Item {
                                Layout.fillHeight: true
                                Layout.minimumWidth: nextHourTemperatureLabel.implicitWidth
                                Layout.preferredWidth: nextHourTemperatureLabel.implicitWidth

                                QQC2.Label {
                                    id: nextHourTemperatureLabel
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.nextHourTemperatureText
                                    font.family: root.uiFontFamily
                                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.9
                                    font.weight: root.uiFontWeight
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        visible: dailyModel.count > 0
                        implicitHeight: dailySection.implicitHeight + popupRoot.cardPadding * 2
                        color: Kirigami.Theme.backgroundColor
                        radius: popupRoot.cardRadius
                        border.color: popupRoot.frameColor

                        ColumnLayout {
                            id: dailySection
                            anchors.fill: parent
                            anchors.margins: popupRoot.cardPadding
                            spacing: popupRoot.sectionGap

                            QQC2.Label {
                                text: i18n("Next days")
                                font.family: root.uiFontFamily
                                font.weight: root.uiFontWeight
                            }

                            ListView {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 7
                                orientation: ListView.Horizontal
                                spacing: popupRoot.sectionGap
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds
                                model: dailyModel

                                delegate: Rectangle {
                                    width: Kirigami.Units.gridUnit * 7
                                    height: ListView.view.height
                                    radius: Kirigami.Units.largeSpacing
                                    color: Kirigami.Theme.alternateBackgroundColor
                                    border.color: popupRoot.subtleFrameColor

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: Kirigami.Units.smallSpacing
                                        spacing: 4

                                        QQC2.Label {
                                            text: dayLabel
                                            Layout.alignment: Qt.AlignHCenter
                                            font.family: root.uiFontFamily
                                            font.weight: root.uiFontWeight
                                            elide: Text.ElideRight
                                        }

                                        Kirigami.Icon {
                                            source: iconName
                                            implicitWidth: Kirigami.Units.iconSizes.smallMedium
                                            implicitHeight: Kirigami.Units.iconSizes.smallMedium
                                            Layout.alignment: Qt.AlignHCenter
                                        }

                                        QQC2.Label {
                                            text: temperatureRange
                                            Layout.alignment: Qt.AlignHCenter
                                            font.family: root.uiFontFamily
                                            font.weight: root.uiFontWeight
                                        }

                                        QQC2.Label {
                                            text: description
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignHCenter
                                            font.family: root.uiFontFamily
                                            font.weight: root.uiFontWeight
                                            color: Kirigami.Theme.disabledTextColor
                                            wrapMode: Text.Wrap
                                            maximumLineCount: 2
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }
                    }

                    QQC2.Label {
                        visible: root.loading || root.errorMessage.length > 0
                        text: root.loading ? i18n("Refreshing forecast...") : root.errorMessage
                        font.family: root.uiFontFamily
                        font.weight: root.uiFontWeight
                        color: root.loading ? Kirigami.Theme.disabledTextColor : Kirigami.Theme.negativeTextColor
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }

                    QQC2.Label {
                        text: i18n("Source: Open-Meteo")
                        font.family: root.uiFontFamily
                        font.weight: root.uiFontWeight
                        color: Kirigami.Theme.disabledTextColor
                        Layout.alignment: Qt.AlignRight
                    }
                }
            }
        }
    }
}
