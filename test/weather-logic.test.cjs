const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const logicPath = path.join(__dirname, "..", "contents", "ui", "weather-logic.js");
const WeatherLogic = require(logicPath);

function formatter(prefix) {
    return (value) => prefix + value;
}

test("format helpers handle invalid values and unit conversions", () => {
    assert.equal(WeatherLogic.formatNumber("nope", 2), "--");
    assert.equal(WeatherLogic.formatNumber(12.6, 0), "13");
    assert.equal(WeatherLogic.formatNumber(12.345, 2), "12.35");

    assert.equal(WeatherLogic.formatTemperature(undefined), "--");
    assert.equal(WeatherLogic.formatTemperature(12.4), "12°");

    assert.equal(WeatherLogic.formatPercent(undefined), "--");
    assert.equal(WeatherLogic.formatPercent(46.2), "46%");

    assert.equal(WeatherLogic.formatSpeed("bad", "kmh"), "--");
    assert.equal(WeatherLogic.formatSpeed(18, "kmh"), "18 km/h");
    assert.equal(WeatherLogic.formatSpeed(18, "ms"), "5.0 m/s");
    assert.equal(WeatherLogic.formatSpeed(18, "mph"), "11 mph");

    assert.equal(WeatherLogic.formatPressure("bad", "hPa"), "--");
    assert.equal(WeatherLogic.formatPressure(1000, "hPa"), "1000 hPa");
    assert.equal(WeatherLogic.formatPressure(1000, "mmHg"), "750 mmHg");
    assert.equal(WeatherLogic.formatPressure(1000, "inHg"), "29.53 inHg");

    assert.equal(WeatherLogic.formatDistance("bad", "km"), "--");
    assert.equal(WeatherLogic.formatDistance(9500, "km"), "9.5 km");
    assert.equal(WeatherLogic.formatDistance(12000, "km"), "12 km");
    assert.equal(WeatherLogic.formatDistance(9000, "mi"), "5.6 mi");
    assert.equal(WeatherLogic.formatDistance(20000, "mi"), "12 mi");

    assert.equal(WeatherLogic.formatPrecipitation("bad", "mm"), "--");
    assert.equal(WeatherLogic.formatPrecipitation(1.2, "mm"), "1.2 mm");
    assert.equal(WeatherLogic.formatPrecipitation(25.4, "in"), "1.00 in");
});

test("wind and date helpers produce stable derived values", () => {
    assert.equal(WeatherLogic.cardinalDirection(undefined), "");
    assert.equal(WeatherLogic.cardinalDirection(0), "N");
    assert.equal(WeatherLogic.cardinalDirection(46), "NE");
    assert.equal(WeatherLogic.cardinalDirection(225), "SW");

    assert.equal(WeatherLogic.formatWind("bad", 270, "kmh"), "--");
    assert.equal(WeatherLogic.formatWind(4, undefined, "kmh"), "4 km/h");
    assert.equal(WeatherLogic.formatWind(4, 270, "kmh"), "4 km/h W");

    const date = new Date(2026, 3, 18, 21, 7, 0);
    assert.equal(WeatherLogic.currentDateKey(date), "2026-04-18");
    assert.equal(WeatherLogic.currentDateKey("2026-04-19T08:09:00"), "2026-04-19");
    assert.match(WeatherLogic.currentDateKey(), /^\d{4}-\d{2}-\d{2}$/);

    assert.equal(WeatherLogic.currentDateTimeKey(date), "2026-04-18T21:07");
    assert.equal(WeatherLogic.currentDateTimeKey("2026-04-19T08:09:00"), "2026-04-19T08:09");
    assert.match(WeatherLogic.currentDateTimeKey(), /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/);
});

test("resolveCurrentDayIndex handles current, past, and empty day lists", () => {
    assert.equal(
        WeatherLogic.resolveCurrentDayIndex(["2026-04-18", "2026-04-19", "2026-04-20"], "2026-04-19"),
        1
    );
    assert.equal(
        WeatherLogic.resolveCurrentDayIndex(["2026-04-15", "2026-04-16"], "2026-04-19"),
        1
    );
    assert.equal(WeatherLogic.resolveCurrentDayIndex([], "2026-04-19"), 0);
    assert.equal(WeatherLogic.resolveCurrentDayIndex([]), 0);
});

test("weather descriptions cover all supported groups and fall back cleanly", () => {
    const groupedCodes = [
        [[0], "Clear"],
        [[1], "Mostly clear"],
        [[2], "Partly cloudy"],
        [[3], "Overcast"],
        [[45, 48], "Fog"],
        [[51, 53, 55, 56, 57], "Drizzle"],
        [[61, 63, 65, 66, 67], "Rain"],
        [[71, 73, 75, 77], "Snow"],
        [[80, 81, 82], "Rain showers"],
        [[85, 86], "Snow showers"],
        [[95], "Thunderstorm"],
        [[96, 99], "Thunderstorm with hail"]
    ];

    for (const [codes, expected] of groupedCodes) {
        for (const code of codes) {
            assert.equal(WeatherLogic.weatherDescriptionText(code), expected);
        }
    }

    assert.equal(WeatherLogic.weatherDescriptionText(999), "Weather unavailable");
});

test("weather icon mapping covers day, night, grouped, and fallback codes", () => {
    assert.equal(WeatherLogic.weatherIconName(0, true), "weather-clear");
    assert.equal(WeatherLogic.weatherIconName(0, false), "weather-clear-night");
    assert.equal(WeatherLogic.weatherIconName(1, true), "weather-few-clouds");
    assert.equal(WeatherLogic.weatherIconName(1, false), "weather-few-clouds-night");
    assert.equal(WeatherLogic.weatherIconName(2, true), "weather-clouds");
    assert.equal(WeatherLogic.weatherIconName(2, false), "weather-clouds-night");

    const groupedCases = [
        [[3], "weather-overcast"],
        [[45, 48], "weather-fog"],
        [[51, 53, 55, 56, 57], "weather-showers-scattered"],
        [[61, 63, 65, 66, 67], "weather-showers"],
        [[71, 73, 75, 77], "weather-snow"],
        [[80, 81, 82], "weather-showers"],
        [[85, 86], "weather-snow-scattered"],
        [[95, 96, 99], "weather-storm"]
    ];

    for (const [codes, expected] of groupedCases) {
        for (const code of codes) {
            assert.equal(WeatherLogic.weatherIconName(code, true), expected);
        }
    }

    assert.equal(WeatherLogic.weatherIconName(999, true), "weather-none-available");
});

test("forecastUrl encodes coordinates and timezone for Open-Meteo", () => {
    const url = WeatherLogic.forecastUrl(45.64, 25.60, "Europe/Bucharest");

    assert.match(url, /^https:\/\/api\.open-meteo\.com\/v1\/forecast\?/);
    assert.match(url, /latitude=45\.64/);
    assert.match(url, /longitude=25\.6/);
    assert.match(url, /forecast_days=6/);
    assert.match(url, /timezone=Europe%2FBucharest/);
});

test("buildMetricItems includes nothing when disabled and everything when enabled", () => {
    const values = {
        feelsLikeText: "10°",
        humidityText: "46%",
        windText: "2 km/h W",
        gustsText: "10 km/h",
        pressureText: "712 mmHg",
        visibilityText: "10 km",
        cloudCoverText: "80%",
        precipitationAmountText: "0.0 mm",
        sunriseText: "06:26",
        sunsetText: "20:07",
        updatedText: "21:45"
    };
    const labels = {
        feelsLike: "Feels like",
        humidity: "Humidity",
        wind: "Wind",
        gusts: "Gusts",
        pressure: "Pressure",
        visibility: "Visibility",
        cloudCover: "Cloud cover",
        precipitation: "Precipitation",
        sunrise: "Sunrise",
        sunset: "Sunset",
        updated: "Updated"
    };

    assert.deepEqual(
        WeatherLogic.buildMetricItems(values, {
            showFeelsLike: false,
            showHumidity: false,
            showWind: false,
            showGusts: false,
            showPressure: false,
            showVisibility: false,
            showCloudCover: false,
            showPrecipitation: false,
            showSunTimes: false,
            showUpdated: false
        }, labels),
        []
    );

    const allItems = WeatherLogic.buildMetricItems(values, {
        showFeelsLike: true,
        showHumidity: true,
        showWind: true,
        showGusts: true,
        showPressure: true,
        showVisibility: true,
        showCloudCover: true,
        showPrecipitation: true,
        showSunTimes: true,
        showUpdated: true
    }, labels);

    assert.equal(allItems.length, 11);
    assert.deepEqual(allItems[0], { label: "Feels like", value: "10°" });
    assert.deepEqual(allItems[8], { label: "Sunrise", value: "06:26" });
    assert.deepEqual(allItems[10], { label: "Updated", value: "21:45" });
});

test("buildHourlyItems uses the first future hour and keeps the default selection when none is restored", () => {
    const result = WeatherLogic.buildHourlyItems({
        time: ["2026-04-18T21:00", "2026-04-18T22:00", "2026-04-18T23:00"],
        weather_code: [3, 80, 2],
        temperature_2m: [12, 11, 10],
        relative_humidity_2m: [40, 50, 60],
        precipitation_probability: [10, 20, 30],
        wind_speed_10m: [4, 5, 6],
        wind_direction_10m: [270, 180, 90],
        is_day: [0, 0, 0]
    }, {
        maxItems: 2,
        referenceTime: "2026-04-18T21:15",
        previousSelectionTimeKey: "",
        formatTime: formatter("time:"),
        formatTemperature: formatter("temp:"),
        formatPercent: formatter("pct:"),
        formatWind: (speed, direction) => `wind:${speed}/${direction}`,
        describeWeather: formatter("desc:"),
        iconForWeather: (code, isDay) => `icon:${code}/${isDay}`
    });

    assert.equal(result.selectedIndex, 0);
    assert.deepEqual(result.items, [
        {
            timeKey: "2026-04-18T22:00",
            timeLabel: "time:2026-04-18T22:00",
            description: "desc:80",
            temperature: "temp:11",
            humidity: "pct:50",
            precipitation: "pct:20",
            wind: "wind:5/180",
            iconName: "icon:80/false"
        },
        {
            timeKey: "2026-04-18T23:00",
            timeLabel: "time:2026-04-18T23:00",
            description: "desc:2",
            temperature: "temp:10",
            humidity: "pct:60",
            precipitation: "pct:30",
            wind: "wind:6/90",
            iconName: "icon:2/false"
        }
    ]);
});

test("buildHourlyItems falls back to the tail, restores a previous selection, and handles invalid maxItems", () => {
    const hourly = {
        time: ["2026-04-18T20:00", "2026-04-18T21:00", "2026-04-18T22:00", "2026-04-18T23:00"],
        weather_code: [1, 2, 3, 80],
        temperature_2m: [14, 13, 12, 11],
        relative_humidity_2m: [30, 40, 50, 60],
        precipitation_probability: [0, 5, 10, 15],
        wind_speed_10m: [1, 2, 3, 4],
        wind_direction_10m: [0, 45, 90, 135],
        is_day: [1, 0, 0, 0]
    };
    const options = {
        maxItems: 2,
        referenceTime: "2026-04-19T01:00",
        previousSelectionTimeKey: "2026-04-18T23:00",
        formatTime: formatter("time:"),
        formatTemperature: formatter("temp:"),
        formatPercent: formatter("pct:"),
        formatWind: (speed, direction) => `wind:${speed}/${direction}`,
        describeWeather: formatter("desc:"),
        iconForWeather: (code, isDay) => `icon:${code}/${isDay}`
    };

    const restored = WeatherLogic.buildHourlyItems(hourly, options);
    assert.equal(restored.items.length, 2);
    assert.equal(restored.items[0].timeKey, "2026-04-18T22:00");
    assert.equal(restored.items[1].timeKey, "2026-04-18T23:00");
    assert.equal(restored.selectedIndex, 1);

    const empty = WeatherLogic.buildHourlyItems(hourly, {
        ...options,
        maxItems: Number.NaN,
        previousSelectionTimeKey: "missing"
    });
    assert.deepEqual(empty, { items: [], selectedIndex: 0 });

    assert.deepEqual(WeatherLogic.buildHourlyItems({}, {
        ...options,
        maxItems: 2,
        referenceTime: "",
        previousSelectionTimeKey: ""
    }), { items: [], selectedIndex: 0 });
});

test("buildDailyItems skips today and formats the next days from the current date", () => {
    const result = WeatherLogic.buildDailyItems({
        time: ["2026-04-18", "2026-04-19", "2026-04-20"],
        weather_code: [3, 61, 80],
        temperature_2m_max: [14, 16, 10],
        temperature_2m_min: [7, 5, 3]
    }, {
        currentDate: "2026-04-18",
        formatShortDay: formatter("day:"),
        describeWeather: formatter("desc:"),
        formatTemperature: formatter("temp:"),
        iconForWeather: (code, isDay) => `icon:${code}/${isDay}`
    });

    assert.deepEqual(result, [
        {
            dayLabel: "day:2026-04-19",
            description: "desc:61",
            temperatureRange: "temp:16 / temp:5",
            iconName: "icon:61/true"
        },
        {
            dayLabel: "day:2026-04-20",
            description: "desc:80",
            temperatureRange: "temp:10 / temp:3",
            iconName: "icon:80/true"
        }
    ]);

    assert.deepEqual(WeatherLogic.buildDailyItems({
        time: ["2026-04-18"],
        weather_code: [3],
        temperature_2m_max: [14],
        temperature_2m_min: [7]
    }, {
        currentDate: "2026-04-19",
        formatShortDay: formatter("day:"),
        describeWeather: formatter("desc:"),
        formatTemperature: formatter("temp:"),
        iconForWeather: (code, isDay) => `icon:${code}/${isDay}`
    }), []);

    assert.deepEqual(WeatherLogic.buildDailyItems({}, {
        formatShortDay: formatter("day:"),
        describeWeather: formatter("desc:"),
        formatTemperature: formatter("temp:"),
        iconForWeather: (code, isDay) => `icon:${code}/${isDay}`
    }), []);
});

test("the QML-compatible module can also execute without CommonJS exports", () => {
    const source = fs.readFileSync(logicPath, "utf8");

    vm.runInNewContext(source, {
        Number,
        Math,
        Date,
        String,
        encodeURIComponent
    }, {
        filename: logicPath
    });

    assert.ok(true);
});
