@system Plant begin
    DATE ~ hold
    # added for convenience
    DOY(DATE) => Cropbox.Dates.dayofyear(DATE) ~ track::int(u"d")
    # moved from Main
    DOYP: planting_day_of_year => 121 ~ preserve::int(u"d", parameter)

    TMAX: maximum_temperature ~ hold
    TMIN: minimum_tempearture ~ hold
    TMN: mean_temperature ~ hold
    PAR: photosynthetically_active_radiation ~ hold

    SWFAC: soil_water_stress_factor ~ hold

    # distinguish initial values of variables (parameters) from actual variables being updated (i.e. LAI0, N0)
    EMP1: LAI_coeff1 => 0.104 ~ preserve(u"m^2", parameter)
    EMP2: LAI_coeff2 => 0.64 ~ preserve(parameter)
    Fc: canopy_fraction => 0.85 ~ preserve(parameter)
    sla: specific_leaf_area => 0.028 ~ preserve(u"m^2/g")
    INTOT: duration_of_reproductive_stage => 300.0 ~ preserve(u"K*d", parameter)
    LAI0: initial_leaf_area_index => 0.013 ~ preserve(u"m^2/m^2", parameter)
    Lfmax: maximum_leaf_number => 12.0 ~ preserve(parameter)
    N0: initial_leaf_number => 2.0 ~ preserve(parameter)
    nb: LAI_coeff => 5.3 ~ preserve(parameter)
    # correct units for p1 (g/K, not g)
    p1: leaf_senescence_rate => 0.03 ~ preserve(u"g/K", parameter)
    PD: plant_density => 5.0 ~ preserve(u"m^-2", parameter)
    rm: maximum_leaf_appearance_rate => 0.100 ~ preserve(u"d^-1", parameter)
    tb: base_temperature => 10.0 ~ preserve(u"°C", parameter)
    W0: initial_plant_dry_matter => 0.3 ~ preserve(u"g/m^2", parameter)
    Wc0: initial_canopy_dry_matter => 0.045 ~ preserve(u"g/m^2", parameter)
    Wr0: initial_root_dry_matter => 0.255 ~ preserve(u"g/m^2", parameter)

    # handle empirical equation for temperature (nounit)
    PT(nounit(TMIN), nounit(TMAX)): photosynthesis_reduction_factor_for_temp => begin
        1.0 - 0.0025 * ((0.25TMIN + 0.75TMAX) - 26.0)^2
    end ~ track

    # introduce RUE parameter with proper units
    RUE: radiation_use_efficiency => 2.1 ~ preserve(u"g/MJ", parameter)
    Pg(PT, SWFAC, RUE, PAR, PD, Y1, LAI): potential_growth_rate => begin
        PT * SWFAC * RUE * PAR/PD * (1 - ℯ^(-Y1 * LAI))
    end ~ track(u"g/d")

    ROWSPC: row_spacing => 60.0 ~ preserve(u"cm", parameter)
    Y1(ROWSPC, PD): canopy_light_extinction_coeff => begin
        # no need to convert units for ROWSPC
        1.5 - 0.768 * (ROWSPC^2 * PD)^0.1
    end ~ preserve

    # introduce flags for organizing rate calculations depending on development phases
    P(DOY, DOYP): planted => (DOY >= DOYP) ~ flag
    VP(P, N, Lfmax): vegetative_phase => (P && N < Lfmax) ~ flag
    RP(N, Lfmax): reproductive_phase => (N >= Lfmax) ~ flag
    #TODO: development phase code no longer needed
    FL(VP, RP): development_phase_code => (VP ? 1 : RP ? 2 : 0) ~ track

    dN(rm, PT): leaf_number_increase => rm * PT ~ track(u"d^-1", when=VP)
    N(dN): leaf_number ~ accumulate(init=N0, when=VP)

    di(TMN, tb): daily_accumulated_temperature => begin
        tb <= TMN <= 25u"°C" ? TMN - tb : 0
    end ~ track(u"K", when=RP)
    INT(di): accumulated_temperature_during_reproductive_stage ~ accumulate(u"K*d", when=RP)

    _a(EMP2, N, nb) => exp(EMP2 * (N - nb)) ~ track
    dLAI1(SWFAC, PD, EMP1, PT, _a, dN) => begin
        SWFAC * PD * EMP1 * PT * (a/(1+a)) * dN
    end ~ track(u"m^2/m^2/d", when=VP)
    dLAI2(PD, di, p1, sla) => begin
        -PD * di * p1 * sla
    end ~ track(u"m^2/m^2/d", when=RP)
    dLAI(dLAI1, dLAI2): leaf_area_index_increase => dLAI1 + dLAI2 ~ track(u"m^2/m^2/d")
    LAI(dLAI): leaf_area_index ~ accumulate(u"m^2/m^2", init=LAI0)

    E: CH2O_conversion_efficiency => 1.0 ~ preserve(u"g/g", parameter)
    dW(E, Pg, PD) => E * Pg * PD ~ track(u"g/m^2/d")
    W(dW): plant_dry_matter ~ accumulate(u"g/m^2", init=W0, when=P)
    Wc(Fc, dW): canopy_dry_matter => Fc * dW ~ accumulate(u"g/m^2", init=Wc0, when=VP)
    Wr(Fc, dW): root_dry_matter => (1-Fc) * dW ~ accumulate(u"g/m^2", init=Wr0, when=VP)
    Wf(dW): fruit_dry_matter ~ accumulate(u"g/m^2", when=RP)

    endsim(INT, INTOT): end_of_simulation => (INT > INTOT) ~ flag
end
