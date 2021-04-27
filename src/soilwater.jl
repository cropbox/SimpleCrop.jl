@system SoilWater begin
    # make sure we have a correct time interval when doing accumulation (i.e. we may use a non-daily time step)
    Δt(context.clock.step): timestep ~ preserve(u"hr")

    SRAD: solar_radiation ~ hold
    TMAX: maximum_temperature ~ hold
    TMIN: minimum_temperature ~ hold
    RAIN: rainfall ~ hold
    LAI: leaf_area_index ~ hold

    calendar ~ hold
    _i: irrigation_data ~ provide(index=:DATE, init=calendar.date, parameter)
    IRR ~ drive(from=_i, u"mm/d")

    CN: runoff_curve_number => 55 ~ preserve(parameter)
    DP: soil_profile_depth => 145 ~ preserve(u"cm", parameter)
    DRNp: daily_drainage => 0.1 ~ preserve(u"cm^3/cm^3/d", parameter)
    WPp: soil_water_portion_at_wilting_point => 0.06 ~ preserve(u"cm^3/cm^3", parameter)
    FCp: soil_water_portion_at_field_capacity => 0.17 ~ preserve(u"cm^3/cm^3", parameter)
    STp: soil_water_portion_at_saturation => 0.28 ~ preserve(u"cm^3/cm^3", parameter)
    SWC0: initial_soil_water_content => 246.5 ~ preserve(u"mm", parameter)

    # no need for manual conversion from cm to mm (DP*10)
    WP(DP, WPp): soil_water_content_at_wilting_point => DP * WPp ~ preserve(u"mm")
    FC(DP, FCp): soil_water_content_at_field_capacity => DP * FCp ~ preserve(u"mm")
    ST(DP, STp): soil_water_content_at_saturation => DP * STp ~ preserve(u"mm")

    # no need for manual conversion from inch to mm (25.4 mm/inch)
    S(CN): potential_maximum_soil_moisture_retention_after_runoff => begin
        1000/CN - 10
    end ~ preserve(u"inch/d")

    POTINF(RAIN, IRR): potential_infiltration => RAIN + IRR ~ track(u"mm/d")
    ROF(POTINF, S, dROF_extra): runoff => begin
        if POTINF > 0.2S
            (POTINF - 0.2S)^2 / (POTINF + 0.8S)
        else
            0u"mm/d"
        end + dROF_extra
    end ~ track(u"mm/d")
    INF(POTINF, ROF): infiltration => POTINF - ROF ~ track(u"mm/d")

    THE(WP, FC): soil_water_content_threshold => WP + 0.75(FC - WP) ~ preserve(u"mm")

    TRAIN(RAIN): cumulative_rainfall ~ accumulate(u"mm")
    TIRR(IRR): cumulative_irrigation ~ accumulate(u"mm")
    TESa(ESa): cumulative_soil_evaporation ~ accumulate(u"mm")
    TEPa(EPa): cumulative_plant_transpiration ~ accumulate(u"mm")
    TROF(ROF): cumulative_runoff ~ accumulate(u"mm")
    TDRN(DRN): cumulative_vertical_drainage ~ accumulate(u"mm")
    TINF(INF): cumulative_infiltration ~ accumulate(u"mm")

    DRN(SWC, FC, DRNp): vertical_drainage => (SWC - FC) * DRNp ~ track(u"mm/d", min=0)

    # make soil/crop albedo parameters
    αs: soil_albedo => 0.1 ~ preserve(parameter)
    αc: crop_albedo => 0.2 ~ preserve(parameter)
    ALB(LAI, αs, αc): surface_albedo => αs * ℯ^(-0.7LAI) + αc * (1 - ℯ^(-0.7LAI)) ~ track

    Tmed(TMAX, TMIN) => 0.6u"K"(TMAX) + 0.4u"K"(TMIN) ~ track(u"°C")

    # match units of Priestly-Taylor equations
    # http://www.clw.csiro.au/publications/technical98/tr34-98.pdf
    # handle temperature units correctly (°C vs. K)
    EEQ(SRAD, ALB, Tmed): equilibrium_evaporation => begin
        SRAD * (4.88e-3 - 4.37e-3ALB)u"mm^3/J/K" * (Tmed - 0u"°C" + 29u"K")
    end ~ track(u"mm/d")

    # handle empirical equation for temperature (nounit)
    f(nounit(TMAX)) => begin
        if TMAX < 5
            0.01ℯ^(0.18(TMAX + 20))
        elseif TMAX > 35
            1.1 + 0.05(TMAX - 35)
        else
            1.1
        end
    end ~ track
    ETp(f, EEQ): potential_evapotranspiration => f * EEQ ~ track(u"mm/d")
    ESp(ETp, LAI): potential_soil_evaporation => ETp * ℯ^(-0.7LAI) ~ track(u"mm/d")
    EPp(ETp, LAI): potential_plant_transpiration => ETp * (1 - ℯ^(-0.7LAI)) ~ track(u"mm/d")

    _a(SWC, WP, FC) => (SWC - WP) / (FC - WP) ~ track(min=0, max=1)
    ESa(ESp, _a): soil_evaporation => ESp * a ~ track(u"mm/d")
    EPa(EPp, SWFAC): plant_transpiration => EPp * SWFAC ~ track(u"mm/d")

    dSWC(INF, ESa, EPa, DRN, dROF_extra, dSWC_ADJ)=> begin
        INF - ESa - EPa - DRN - dROF_extra + dSWC_ADJ
    end ~ track(u"mm/d")

    # these seemingly complicated extra/adj variables are due to incomplete separation of rate variable calculation and integration logic in the original model
    # handle ROF update w.r.t SWC overflow
    dROF_extra(SWC, ST, Δt) => (SWC - ST) / Δt ~ track(u"mm/d", min=0)
    # handle SWC_ADJ w.r.t SWC underflow
    dSWC_ADJ(SWC, Δt) => -SWC / Δt ~ track(u"mm/d", min=0)
    SWC_ADJ(dSWC_ADJ) ~ accumulate(u"mm")

    SWC(dSWC): soil_water_content ~ accumulate(u"mm", init=SWC0)
    ΔSWC(SWC0, SWC): storage_change => SWC0 - SWC ~ track(u"mm")

    Fi(TRAIN, TIRR) => TRAIN + TIRR ~ track(u"mm")
    Fo(TESa, TEPa, TROF, TDRN) => TESa + TEPa + TROF + TDRN ~ track(u"mm")
    WATBAL(ΔSWC, Fi, Fo) => ΔSWC + Fi - Fo ~ track(u"mm")

    CHECK(TRAIN, TIRR, TROF) => TRAIN + TIRR - TROF ~ track(u"mm")

    # if-else logic replaced by min=0, max=1
    SWFAC1(SWC, WP, THE): drought_stress_factor => (SWC - WP) / (THE - WP) ~ track(min=0, max=1)

    # no need for manual conversion from cm to mm (DP*10)
    WTABLE(SWC, FC, ST, DP): water_table_thickness => (SWC - FC) / (ST - FC) * DP ~ track(u"mm", min=0)
    DWT(DP, WTABLE): water_table_depth => DP - WTABLE ~ track(u"mm")

    STRESS_DEPTH: water_table_depth_threshold => 250 ~ preserve(u"mm", parameter)
    # if-else logic replaced by max=1
    SWFAC2(DWT, STRESS_DEPTH): excess_stress_factor => DWT / STRESS_DEPTH ~ track(min=0, max=1)

    SWFAC(SWFAC1, SWFAC2): soil_water_stress_factor => min(SWFAC1, SWFAC2) ~ track
end
