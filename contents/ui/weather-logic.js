function formatNumber(value, decimals) {
    var numericValue = Number(value);

    if (!Number.isFinite(numericValue)) {
        return "--";
    }

    if (decimals <= 0) {
        return String(Math.round(numericValue));
    }

    var factor = Math.pow(10, decimals);
    return (Math.round(numericValue * factor) / factor).toFixed(decimals);
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

function formatSpeed(value, windUnit) {
    if (!Number.isFinite(Number(value))) {
        return "--";
    }

    switch (windUnit) {
    case "ms":
        return formatNumber(Number(value) / 3.6, 1) + " m/s";
    case "mph":
        return formatNumber(Number(value) * 0.621371, 0) + " mph";
    default:
        return formatNumber(Number(value), 0) + " km/h";
    }
}

function formatPressure(value, pressureUnit) {
    if (!Number.isFinite(Number(value))) {
        return "--";
    }

    switch (pressureUnit) {
    case "mmHg":
        return formatNumber(Number(value) * 0.750061683, 0) + " mmHg";
    case "inHg":
        return formatNumber(Number(value) * 0.0295299831, 2) + " inHg";
    default:
        return formatNumber(Number(value), 0) + " hPa";
    }
}

function formatDistance(value, distanceUnit) {
    if (!Number.isFinite(Number(value))) {
        return "--";
    }

    var kilometers = Number(value) / 1000;

    if (distanceUnit === "mi") {
        var miles = kilometers * 0.621371;
        return (miles >= 10 ? formatNumber(miles, 0) : formatNumber(miles, 1)) + " mi";
    }

    return (kilometers >= 10 ? formatNumber(kilometers, 0) : formatNumber(kilometers, 1)) + " km";
}

function formatPrecipitation(value, precipitationUnit) {
    if (!Number.isFinite(Number(value))) {
        return "--";
    }

    if (precipitationUnit === "in") {
        return formatNumber(Number(value) * 0.0393701, 2) + " in";
    }

    return formatNumber(Number(value), 1) + " mm";
}

function cardinalDirection(degrees) {
    if (!Number.isFinite(Number(degrees))) {
        return "";
    }

    var directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];
    var index = Math.round(Number(degrees) / 45) % directions.length;
    return directions[index];
}

function formatWind(speed, direction, windUnit) {
    var speedText = formatSpeed(speed, windUnit);
    var directionText = cardinalDirection(direction);

    if (speedText === "--") {
        return "--";
    }

    return directionText.length > 0 ? speedText + " " + directionText : speedText;
}

function pad2(value) {
    return String(value).padStart(2, "0");
}

function currentDateKey(date) {
    var current = date instanceof Date ? new Date(date.getTime()) : (date ? new Date(date) : new Date());

    return current.getFullYear()
        + "-" + pad2(current.getMonth() + 1)
        + "-" + pad2(current.getDate());
}

function currentDateTimeKey(date) {
    var current = date instanceof Date ? new Date(date.getTime()) : (date ? new Date(date) : new Date());

    return currentDateKey(current)
        + "T" + pad2(current.getHours())
        + ":" + pad2(current.getMinutes());
}

function resolveCurrentDayIndex(days, currentDate) {
    var currentDay = String(currentDate || currentDateKey());
    var dayIndex = 0;
    var i = 0;

    for (i = 0; i < days.length; ++i) {
        if (String(days[i]) >= currentDay) {
            dayIndex = i;
            break;
        }
    }

    if (days.length > 0 && String(days[days.length - 1]) < currentDay) {
        dayIndex = days.length - 1;
    }

    return dayIndex;
}

function weatherDescriptionText(code) {
    switch (Number(code)) {
    case 0:
        return "Clear";
    case 1:
        return "Mostly clear";
    case 2:
        return "Partly cloudy";
    case 3:
        return "Overcast";
    case 45:
    case 48:
        return "Fog";
    case 51:
    case 53:
    case 55:
    case 56:
    case 57:
        return "Drizzle";
    case 61:
    case 63:
    case 65:
    case 66:
    case 67:
        return "Rain";
    case 71:
    case 73:
    case 75:
    case 77:
        return "Snow";
    case 80:
    case 81:
    case 82:
        return "Rain showers";
    case 85:
    case 86:
        return "Snow showers";
    case 95:
        return "Thunderstorm";
    case 96:
    case 99:
        return "Thunderstorm with hail";
    default:
        return "Weather unavailable";
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

function forecastUrl(latitude, longitude, timezone) {
    return "https://api.open-meteo.com/v1/forecast"
        + "?latitude=" + encodeURIComponent(latitude)
        + "&longitude=" + encodeURIComponent(longitude)
        + "&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,wind_speed_10m,wind_gusts_10m,wind_direction_10m,surface_pressure,cloud_cover,visibility,weather_code,is_day"
        + "&hourly=temperature_2m,relative_humidity_2m,precipitation_probability,wind_speed_10m,wind_direction_10m,weather_code,is_day"
        + "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset"
        + "&forecast_days=6"
        + "&timezone=" + encodeURIComponent(timezone);
}

function buildMetricItems(values, flags, labels) {
    var items = [];

    if (flags.showFeelsLike) {
        items.push({ "label": labels.feelsLike, "value": values.feelsLikeText });
    }

    if (flags.showHumidity) {
        items.push({ "label": labels.humidity, "value": values.humidityText });
    }

    if (flags.showWind) {
        items.push({ "label": labels.wind, "value": values.windText });
    }

    if (flags.showGusts) {
        items.push({ "label": labels.gusts, "value": values.gustsText });
    }

    if (flags.showPressure) {
        items.push({ "label": labels.pressure, "value": values.pressureText });
    }

    if (flags.showVisibility) {
        items.push({ "label": labels.visibility, "value": values.visibilityText });
    }

    if (flags.showCloudCover) {
        items.push({ "label": labels.cloudCover, "value": values.cloudCoverText });
    }

    if (flags.showPrecipitation) {
        items.push({ "label": labels.precipitation, "value": values.precipitationAmountText });
    }

    if (flags.showSunTimes) {
        items.push({ "label": labels.sunrise, "value": values.sunriseText });
        items.push({ "label": labels.sunset, "value": values.sunsetText });
    }

    if (flags.showUpdated) {
        items.push({ "label": labels.updated, "value": values.updatedText });
    }

    return items;
}

function buildHourlyItems(hourly, options) {
    var times = hourly.time || [];
    var maxItems = Number(options.maxItems);
    var referenceTime = String(options.referenceTime || "");
    var previousSelectionTimeKey = String(options.previousSelectionTimeKey || "");
    var startIndex = -1;
    var items = [];
    var restoredIndex = 0;
    var i = 0;

    if (!Number.isFinite(maxItems)) {
        maxItems = 0;
    }

    maxItems = Math.max(0, Math.floor(maxItems));

    for (i = 0; i < times.length; ++i) {
        if (String(times[i]) > referenceTime) {
            startIndex = i;
            break;
        }
    }

    if (startIndex < 0) {
        startIndex = Math.max(0, times.length - maxItems);
    }

    for (i = startIndex; i < times.length && items.length < maxItems; ++i) {
        items.push({
            "timeKey": String(times[i]),
            "timeLabel": options.formatTime(times[i]),
            "description": options.describeWeather(hourly.weather_code[i]),
            "temperature": options.formatTemperature(hourly.temperature_2m[i]),
            "humidity": options.formatPercent(hourly.relative_humidity_2m[i]),
            "precipitation": options.formatPercent(hourly.precipitation_probability[i]),
            "wind": options.formatWind(hourly.wind_speed_10m[i], hourly.wind_direction_10m[i]),
            "iconName": options.iconForWeather(hourly.weather_code[i], Number(hourly.is_day[i]) === 1)
        });
    }

    if (previousSelectionTimeKey.length > 0) {
        for (i = 0; i < items.length; ++i) {
            if (String(items[i].timeKey) === previousSelectionTimeKey) {
                restoredIndex = i;
                break;
            }
        }
    }

    return {
        "items": items,
        "selectedIndex": restoredIndex
    };
}

function buildDailyItems(daily, options) {
    var days = daily.time || [];
    var startIndex = resolveCurrentDayIndex(days, options.currentDate);
    var items = [];
    var i = 0;

    for (i = startIndex + 1; i < days.length; ++i) {
        items.push({
            "dayLabel": options.formatShortDay(days[i]),
            "description": options.describeWeather(daily.weather_code[i]),
            "temperatureRange": options.formatTemperature(daily.temperature_2m_max[i]) + " / " + options.formatTemperature(daily.temperature_2m_min[i]),
            "iconName": options.iconForWeather(daily.weather_code[i], true)
        });
    }

    return items;
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = {
        formatNumber: formatNumber,
        formatTemperature: formatTemperature,
        formatPercent: formatPercent,
        formatSpeed: formatSpeed,
        formatPressure: formatPressure,
        formatDistance: formatDistance,
        formatPrecipitation: formatPrecipitation,
        cardinalDirection: cardinalDirection,
        formatWind: formatWind,
        currentDateKey: currentDateKey,
        currentDateTimeKey: currentDateTimeKey,
        resolveCurrentDayIndex: resolveCurrentDayIndex,
        weatherDescriptionText: weatherDescriptionText,
        weatherIconName: weatherIconName,
        forecastUrl: forecastUrl,
        buildMetricItems: buildMetricItems,
        buildHourlyItems: buildHourlyItems,
        buildDailyItems: buildDailyItems
    };
}
