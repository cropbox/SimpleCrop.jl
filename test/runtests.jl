using Cropbox
using SimpleCrop
using Test

using CSV
using DataFrames
using TimeZones

loaddata(f) = CSV.File(joinpath(@__DIR__, "data", f)) |> DataFrame

config = @config (
    :Clock => :step => 1u"d",
    :Calendar => :init => ZonedDateTime(1987, 1, 1, tz"UTC"),
    :Weather => :weather_data => loaddata("weather.csv"),
    :SoilWater => :irrigation_data => loaddata("irrigation.csv"),
)

# frequency of printout (days)
FROP = 3u"d"

r = simulate(SimpleCrop.Model;
    config,
    stop = :endsim,
    #snap = s -> iszero(s.DOY' % FROP),
)

@testset "simplecrop" begin
    @testset "plant" begin
        visualize(r, :DATE, :N; kind = :line) |> println
        visualize(r, :DATE, :INT; kind = :line) |> println
        visualize(r, :DATE, :W; kind = :line) |> println
        visualize(r, :DATE, :Wc; kind = :line) |> println
        visualize(r, :DATE, :Wr; kind = :line) |> println
        visualize(r, :DATE, :Wf; kind = :line) |> println
        visualize(r, :DATE, :LAI; kind = :line) |> println
    end

    @testset "soil water" begin
        visualize(r, :DATE, :ROF; kind = :line) |> println
        visualize(r, :DATE, :INF; kind = :line) |> println
        visualize(r, :DATE, :DRN; kind = :line) |> println
        visualize(r, :DATE, :ETp; kind = :line) |> println
        visualize(r, :DATE, :ESa; kind = :line) |> println
        visualize(r, :DATE, :EPa; kind = :line) |> println
        visualize(r, :DATE, :SWC; kind = :line) |> println
        visualize(r, :DATE, :(SWC/DP); yunit = u"mm^3/mm^3", kind = :line) |> println
        visualize(r, :DATE, :SWFAC1; kind = :line) |> println
        visualize(r, :DATE, :SWFAC2; kind = :line) |> println
    end

    @testset "water balance" begin
        println("Initial soil water content: ", r[end, :SWC0])
        println("Final soil water content: ", r[end, :SWC])
        println("Total rainfall depth: ", r[end, :TRAIN])
        println("Total irrigation depth: ", r[end, :TIRR])
        println("Total soil evaporation: ", r[end, :TESa])
        println("Total plant transpiration: ", r[end, :TEPa])
        println("Total surface runoff: ", r[end, :TROF])
        println("Total vertical drainage: ", r[end, :TDRN])
        println("Water balance: ", r[end, :WATBAL])
    end
end
