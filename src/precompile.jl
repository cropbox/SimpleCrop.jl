import PrecompileTools

using CSV
using DataFrames
using TimeZones

PrecompileTools.@compile_workload begin
    loaddata(f) = CSV.File(joinpath(@__DIR__, "../test/data", f)) |> DataFrame

    config = @config (
        :Clock => :step => 1u"d",
        :Calendar => :init => ZonedDateTime(1987, 1, 1, tz"UTC"),
        :Weather => :weather_data => loaddata("weather.csv"),
        :SoilWater => :irrigation_data => loaddata("irrigation.csv"),
    )

    # frequency of printout (days)
    FROP = 3u"d"

    r = simulate(Model;
        config,
        stop = :endsim,
        #snap = s -> iszero(s.DOY' % FROP),
        verbose = false,
    )

    for backend in (:UnicodePlots, :Gadfly)
        visualize(r, :DATE, :LAI; kind = :line, backend)
    end
end
