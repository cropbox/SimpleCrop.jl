# SimpleCrop.jl

[SimpleCrop.jl](https://github.com/cropbox/SimpleCrop.jl) is an implementation of [SimpleCrop](https://github.com/DSSAT/SimpleCrop) model which was introduced as an example of how [DSSAT](https://dssat.net/models-overview/modular-approach-example/) models were structured in a modular approach. The original model was coded in Fortran and here reimplemented in a domain-specific language based on Julia using [Cropbox](https://github.com/cropbox/Cropbox.jl) framework.

## Installation

```julia
using Pkg
Pkg.add("SimpleCrop")
```

## Getting Started

```@example simple
using Cropbox
using SimpleCrop
```

The model is implemented as a system named `Model` defined in `SimpleCrop` module.

```@example simple
parameters(SimpleCrop.Model; alias = true)
```

As many parameters are already defined in the model, we only need to prepare time-series data for daily weather and irrigation, which are included in the package for convenience.

```@example simple
using CSV
using DataFrames
using Dates
using TimeZones

loaddata(f) = CSV.File(joinpath(dirname(pathof(SimpleCrop)), "../test/data", f)) |> DataFrame
; # hide
```

```@example simple
config = @config (
    :Clock => :step => 1u"d",
    :Calendar => :init => ZonedDateTime(1987, 1, 1, tz"UTC"),
    :Weather => :weather_data => loaddata("weather.csv"),
    :SoilWater => :irrigation_data => loaddata("irrigation.csv"),
)
; # hide
```

Let's run simulation with the model using configuration we just created. Stop condition for simulation is defined in a flag variable named `endsim` which coincides with plant maturity or the end of reproductive stage.

```@example simple
r = simulate(SimpleCrop.Model; config, stop = :endsim)
; # hide
```

The output of simulation is now contained in a data frame from which we generate multiple plots. The number of leaf (`N`) went from `initial_leaf_number` (= 0) to `maximum_leaf_number` (= 12) as indicated in the default set of parameters.

```@example simple
visualize(r, :DATE, :N; ylim = (0, 15), kind = :line)
```

Thermal degree days (`INT`) started accumulating from mid-August with the onset of reproductive stage until late-October when it reaches the maturity indicated by `duration_of_reproductive_stage`.

```@example simple
visualize(r, :DATE, :INT; kind = :line)
```

Assimilated carbon (`W`) was partitioned into multiple parts of the plant as shown in the plot of dry biomass.

```@example simple
visualize(r, :DATE, [:W, :Wc, :Wr, :Wf]; names = ["Total", "Canopy", "Root", "Fruit"], kind = :line)
```

Leaf area index (`LAI`) reached its peak at the end of vegetative stage then began declining throughout reproductive stage.

```@example simple
visualize(r, :DATE, :LAI; kind = :line)
```

For soil water balance, here is a plot showing water runoff (`ROF`), infiltration (`INF`), and vertical drainage (`DRN`).

```@example simple
visualize(r, :DATE, [:ROF, :INF, :DRN]; kind = :line)
```

Soil water status has influence on potential evapotranspiration (`ETp`), actual soil evaporation (`ESa`), and actual plant transpiration (`ESp`).

```@example simple
visualize(r, :DATE, [:ETp, :ESa, :EPa]; kind = :line)
```

The resulting soil water content (`SWC`) is shown here.

```@example simple
visualize(r, :DATE, :SWC; ylim = (0, 400), kind = :line)
```

Which, in turn, determines soil water stress factor (`SWFAC`) in this model.

```@example simple
visualize(r, :DATE, [:SWFAC, :SWFAC1, :SWFAC2]; ylim = (0, 1), kind = :line)
```

For more information about using the framework such as `simulate()` and `visualize()` functions, please refer to the [Cropbox documentation](http://cropbox.github.io/Cropbox.jl/stable/).
