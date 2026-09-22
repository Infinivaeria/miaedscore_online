# shortcuts for easier to read formulas

PI   = Math::PI
sin  = Math.method(:sin)
cos  = Math.method(:cos)
tan  = Math.method(:tan)
asin = Math.method(:asin)
atan = Math.method(:atan2)
acos = Math.method(:acos)
rad  = PI / 180

# sun calculations are based on http://aa.quae.nl/en/reken/zonpositie.html formulas


# date/time constants and conversions

dayMs = 1000 * 60 * 60 * 24
J1970 = 2440588
J2000 = 2451545

def to_julian(date) date.to_f / dayMs - 0.5 + J1970 end
def from_julian(j) Time.at((j + 0.5 - J1970) * dayMs) end
def to_days(date) to_julian(date) - J2000 end


# general calculations for position

e = rad * 23.4397 # obliquity of the Earth

def right_ascension(l, b) atan.call(sin.call(l) * cos.call(e) - tan.call(b) * sin.call(e), cos.call(l)) end
def declination(l, b) asin.call(sin.call(b) * cos.call(e) + cos.call(b) * sin.call(e) * sin.call(l)) end

def azimuth(h, phi, dec) atan.call(sin.call(h), cos.call(h) * sin.call(phi) - tan.call(dec) * cos.call(phi)) end
def altitude(h, phi, dec) asin.call(sin.call(phi) * sin.call(dec) + cos.call(phi) * cos.call(dec) * cos.call(h)) end

def sidereal_time(d, lw) rad * (280.16 + 360.9856235 * d) - lw end

def astro_refraction(h)
    if h < 0 # the following formula works for positive altitudes only.
        h = 0 # if h = -0.08901179 a div/0 would occur.
    end

    # formula 16.4 of "Astronomical Algorithms" 2nd edition by Jean Meeus (Willmann-Bell, Richmond) 1998.
    # 1.02 / tan(h + 10.26 / (h + 5.10)) h in degrees, result in arc minutes -> converted to rad:
    return 0.0002967 / Math.tan(h + 0.00312536 / (h + 0.08901179))
end

# general sun calculations

def solar_mean_anomaly(d) rad * (357.5291 + 0.98560028 * d) end

def ecliptic_longitude(m)

    c = rad * (1.9148 * sin.call(m) + 0.02 * sin.call(2 * m) + 0.0003 * sin.call(3 * m)) # equation of center
    p = rad * 102.9372 # perihelion of the Earth

    return m + c + p + PI
end

def sun_coords(d)

    m = solar_mean_anomaly(d)
    l = ecliptic_longitude(m)

    return {
        dec: declination(l, 0),
        ra: right_ascension(l, 0)
    }
end


sun_calc = SunCalc.new


# calculates sun position for a given date and latitude/longitude

sun_calc.get_position = -> (date, lat, lng) {

    lw  = rad * -lng
    phi = rad * lat
    d   = to_days(date)

    c  = sun_coords(d)
    h  = sidereal_time(d, lw) - c[:ra]

    return {
        azimuth: azimuth(h, phi, c[:dec]),
        altitude: altitude(h, phi, c[:dec])
    }
}


# sun times configuration (angle, morning name, evening name)

times = sun_calc.times = [
    [-0.833, 'sunrise',       'sunset'      ],
    [ -0.3, 'sunriseEnd',    'sunsetStart' ],
    [   -6, 'dawn',          'dusk'        ],
    [ -12, 'nauticalDawn',  'nauticalDusk'],
    [ -18, 'nightEnd',      'night'       ],
    [   6, 'goldenHourEnd', 'goldenHour' ]
]

# adds a custom time to the times config

sun_calc.add_time = -> (angle, rise_name, set_name) {
    times.push([angle, rise_name, set_name])
}


# calculations for sun times

j0 = 0.0009

def julian_cycle(d, lw) (d - j0 - lw / (2 * PI)).round end

def approx_transit(ht, lw, n) j0 + (ht + lw) / (2 * PI) + n end
def solar_transit_j(ds, m, l) j2000 + ds + 0.0053 * sin.call(m) - 0.0069 * sin.call(2 * l) end

def hour_angle(h, phi, d) acos.call((sin.call(h) - sin.call(phi) * sin.call(d)) / (cos.call(phi) * cos.call(d))) end
def observer_angle(height) -2.076 * Math.sqrt(height) / 60 end

# returns set time for the given sun altitude
def get_set_j(h, lw, phi, dec, n, m, l)

    w = hour_angle(h, phi, dec)
    a = approx_transit(w, lw, n)
    return solar_transit_j(a, m, l)
end


# calculates sun times for a given date and latitude/longitude, and, optionally,
# the observer height (in meters) relative to the horizon

sun_calc.get_times = -> (date, lat, lng, height) {

    height = height || 0

    lw = rad * -lng
    phi = rad * lat

    dh = observer_angle(height)

    d = to_days(date)
    n = julian_cycle(d, lw)
    ds = approx_transit(0, lw, n)

    m = solar_mean_anomaly(ds)
    l = ecliptic_longitude(m)
    dec = declination(l, 0)

    jnoon = solar_transit_j(ds, m, l)

    i = 0
    len = times.length
    time = nil
    h0 = nil
    jset = nil
    jrise = nil


    result = {
        solarNoon: from_julian(jnoon),
        nadir: from_julian(jnoon - 0.5)
    }

    while i < len do
        time = times[i]
        h0 = (time[0] + dh) * rad

        jset = get_set_j(h0, lw, phi, dec, n, m, l)
        jrise = jnoon - (jset - jnoon)

        result[time[1]] = from_julian(jrise)
        result[time[2]] = from_julian(jset)

        i += 1
    end

    return result
end


# moon calculations, based on http://aa.quae.nl/en/reken/hemelpositie.html formulas

def moon_coords(d) # geocentric ecliptic coordinates of the moon

    l = rad * (218.316 + 13.176396 * d) # ecliptic longitude
    m = rad * (134.963 + 13.064993 * d) # mean anomaly
    f = rad * (93.272 + 13.229350 * d)  # mean distance

    l  = l + rad * 6.289 * sin.call(m) # longitude
    b  = rad * 5.128 * sin.call(f)     # latitude
    dt = 385001 - 20905 * cos.call(m)  # distance to the moon in km

    return {
        ra: right_ascension(l, b),
        dec: declination(l, b),
        dist: dt
    }
end

sun_calc.get_moon_position = -> (date, lat, lng) {

    lw  = rad * -lng
    phi = rad * lat
    d   = to_days(date)

    c = moon_coords(d)
    h = sidereal_time(d, lw) - c[:ra]

     # formula 14.1 of "Astronomical Algorithms" 2nd edition by Jean Meeus (Willmann-Bell, Richmond) 1998.
     pa = atan.call(sin.call(h), tan.call(phi) * cos.call(c[:dec]) - sin.call(c[:dec]) * cos.call(h))

     h += astro_refraction(h); # altitude correction for refraction

     return {
         azimuth: azimuth(h, phi, c[:dec]),
         altitude: h,
         distance: c[:dist],
         parallacticAngle: pa
     }
end

# calculations for illumination parameters of the moon,
# based on http://idlastro.gsfc.nasa.gov/ftp/pro/astro/mphase.pro formulas and
# Chapter 48 of "Astronomical Algorithms" 2nd edition by Jean Meeus (Willmann-Bell, Richmond) 1998

sun_calc.get_moon_illumination = -> (date) {

    d = to_days(date || Time.now)
    s = sun_coords(d)
    m = moon_coords(d)

    sdist = 149598000 # distance from Earth to Sun in km

    phi = acos.call(sin.call(s[:dec]) * sin.call(m[:dec]) + cos.call(s[:dec]) * cos.call(m[:dec]) * cos.call(s[:ra] - m[:ra]))
    inc = atan.call(sdist * sin.call(phi), m[:dist] - sdist * cos.call(phi))
    angle = atan.call(cos.call(s[:dec]) * sin.call(s[:ra] - m[:ra]), sin.call(s[:dec]) * cos.call(m[:dec]) -
            cos.call(s[:dec]) * sin.call(m[:dec]) * cos.call(s[:ra] - m[:ra]))

    return {
        fraction: (1 + cos.call(inc)) / 2,
        phase: 0.5 + 0.5 * inc * (angle < 0 ? -1 : 1) / PI,
        angle: angle
    }
end


def hours_later(date, h)
    return Time.at(date.to_f + h * dayMs / 24)
end

# calculations for moon rise/set times are based on http://www.stargazing.net/kepler/moonrise.html article

sun_calc.get_moon_times = -> (date, lat, lng, in_utc) {
    t = Time.at(date.to_f)
    if in_utc
        t.utc
        t.hour = 0
        t.min = 0
        t.sec = 0
        t.usec = 0
    else
        t.localtime
        t.hour = 0
        t.min = 0
        t.sec = 0
        t.usec = 0
    end

    hc = 0.133 * rad
    h0 = sun_calc.get_moon_position.(t, lat, lng)[:altitude] - hc
    h1 = nil
    h2 = nil
    rise = nil
    set = nil
    a = nil
    b = nil
    xe = nil
    ye = nil
    d = nil
    roots = nil
    x1 = nil
    x2 = nil
    dx = nil

    # go in 2-hour chunks, each time seeing if a 3-point quadratic curve crosses zero (which means rise or set)
    i = 1
    while i <= 24 do
        h1 = sun_calc.get_moon_position.(hours_later(t, i), lat, lng)[:altitude] - hc;
        h2 = sun_calc.get_moon_position.(hours_later(t, i + 1), lat, lng)[:altitude] - hc;

        a = (h0 + h2) / 2 - h1;
        b = (h2 - h0) / 2;
        xe = -b / (2 * a);
        ye = (a * xe + b) * xe + h1;
        d = b * b - 4 * a * h1;
        roots = 0;

        if d >= 0
            dx = Math.sqrt(d) / (a.abs * 2);
            x1 = xe - dx;
            x2 = xe + dx;
            roots += 1 if x1.abs <= 1
            roots += 1 if x2.abs <= 1
            x1 = x2 if x1 < -1
        end

        if roots == 1
            if h0 < 0
                rise = i + x1;
            else
                set = i + x1;
            end

        elsif roots == 2
            rise = i + (ye < 0 ? x2 : x1);
            set = i + (ye < 0 ? x1 : x2);
        end

        break if rise && set

        h0 = h2;

        i += 2
    end

    result = {}

    result[:rise] = hours_later(t, rise) if rise
    result[:set] = hours_later(t, set) if set

    result[ye > 0 ? :alwaysUp : :alwaysDown] = true if !rise && !set

    return result
end
