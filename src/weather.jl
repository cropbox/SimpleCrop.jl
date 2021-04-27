@system Weather begin
    calendar(context) ~ ::Calendar
    _w: weather_data ~ provide(index=:DATE, init=calendar.date, parameter)

    DATE ~ drive::date(from=_w)

    SRAD: solar_radiation ~ drive(from=_w, u"MJ/m^2/d")
    #PAR(s): photosynthetically_active_radiation ~ drive(from=_w, u"MJ/m^2/d")
    PAR(SRAD): photosynthetically_active_radiation => 0.5SRAD ~ track(u"MJ/m^2/d")

    TMAX: maximum_temperature ~ drive(from=_w, u"°C")
    TMIN: minimum_temperature ~ drive(from=_w, u"°C")
    TMN(TMAX, TMIN): mean_temperature => begin
        # explicit conversion due to strictness of temperature units handling by Unitful.jl
        0.5(u"K"(TMAX) + u"K"(TMIN))
    end ~ track(u"°C")

    RAIN: rainfall ~ drive(from=_w, u"mm/d")
end
