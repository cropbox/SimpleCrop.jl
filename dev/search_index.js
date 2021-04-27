var documenterSearchIndex = {"docs":
[{"location":"#SimpleCrop.jl","page":"Home","title":"SimpleCrop.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"SimpleCrop.jl is an implementation of SimpleCrop model which was introduced as an example of how DSSAT models were structured in a modular approach. The original model was coded in Fortran and here reimplemented in a domain-specific language based on Julia using Cropbox framework.","category":"page"},{"location":"#Installation","page":"Home","title":"Installation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"using Pkg\nPkg.add(\"SimpleCrop\")","category":"page"},{"location":"#Getting-Started","page":"Home","title":"Getting Started","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"using Cropbox\nusing SimpleCrop","category":"page"},{"location":"","page":"Home","title":"Home","text":"The model is implemented as a system named Model defined in SimpleCrop module.","category":"page"},{"location":"","page":"Home","title":"Home","text":"parameters(SimpleCrop.Model; alias = true)","category":"page"},{"location":"","page":"Home","title":"Home","text":"As many parameters are already defined in the model, we only need to prepare time-series data for daily weather and irrigation, which are included in the package for convenience.","category":"page"},{"location":"","page":"Home","title":"Home","text":"using CSV\nusing DataFrames\nusing Dates\nusing TimeZones\n\nloaddata(f) = CSV.File(joinpath(dirname(pathof(SimpleCrop)), \"../test/data\", f)) |> DataFrame\n; # hide","category":"page"},{"location":"","page":"Home","title":"Home","text":"config = @config (\n    :Clock => :step => 1u\"d\",\n    :Calendar => :init => ZonedDateTime(1987, 1, 1, tz\"UTC\"),\n    :Weather => :weather_data => loaddata(\"weather.csv\"),\n    :SoilWater => :irrigation_data => loaddata(\"irrigation.csv\"),\n)\n; # hide","category":"page"},{"location":"","page":"Home","title":"Home","text":"Let's run simulation with the model using configuration we just created. Stop condition for simulation is defined in a flag variable named endsim which coincides with plant maturity or the end of reproductive stage.","category":"page"},{"location":"","page":"Home","title":"Home","text":"r = simulate(SimpleCrop.Model; config, stop = :endsim)\n; # hide","category":"page"},{"location":"","page":"Home","title":"Home","text":"The output of simulation is now contained in a data frame from which we generate multiple plots. The number of leaf (N) went from initial_leaf_number (= 0) to maximum_leaf_number (= 12) as indicated in the default set of parameters.","category":"page"},{"location":"","page":"Home","title":"Home","text":"visualize(r, :DATE, :N; ylim = (0, 15), kind = :line)","category":"page"},{"location":"","page":"Home","title":"Home","text":"Thermal degree days (INT) started accumulating from mid-August with the onset of reproductive stage until late-October when it reaches the maturity indicated by duration_of_reproductive_stage.","category":"page"},{"location":"","page":"Home","title":"Home","text":"visualize(r, :DATE, :INT; kind = :line)","category":"page"},{"location":"","page":"Home","title":"Home","text":"Assimilated carbon (W) was partitioned into multiple parts of the plant as shown in the plot of dry biomass.","category":"page"},{"location":"","page":"Home","title":"Home","text":"visualize(r, :DATE, [:W, :Wc, :Wr, :Wf]; names = [\"Total\", \"Canopy\", \"Root\", \"Fruit\"], kind = :line)","category":"page"},{"location":"","page":"Home","title":"Home","text":"Leaf area index (LAI) reached its peak at the end of vegetative stage then began declining throughout reproductive stage.","category":"page"},{"location":"","page":"Home","title":"Home","text":"visualize(r, :DATE, :LAI; kind = :line)","category":"page"},{"location":"","page":"Home","title":"Home","text":"For soil water balance, here is a plot showing water runoff (ROF), infiltration (INF), and vertical drainage (DRN).","category":"page"},{"location":"","page":"Home","title":"Home","text":"visualize(r, :DATE, [:ROF, :INF, :DRN]; kind = :line)","category":"page"},{"location":"","page":"Home","title":"Home","text":"Soil water status has influence on potential evapotranspiration (ETp), actual soil evaporation (ESa), and actual plant transpiration (ESp).","category":"page"},{"location":"","page":"Home","title":"Home","text":"visualize(r, :DATE, [:ETp, :ESa, :EPa]; kind = :line)","category":"page"},{"location":"","page":"Home","title":"Home","text":"The resulting soil water content (SWC) is shown here.","category":"page"},{"location":"","page":"Home","title":"Home","text":"visualize(r, :DATE, :SWC; ylim = (0, 400), kind = :line)","category":"page"},{"location":"","page":"Home","title":"Home","text":"Which, in turn, determines soil water stress factor (SWFAC) in this model.","category":"page"},{"location":"","page":"Home","title":"Home","text":"visualize(r, :DATE, [:SWFAC, :SWFAC1, :SWFAC2]; ylim = (0, 1), kind = :line)","category":"page"},{"location":"","page":"Home","title":"Home","text":"For more information about using the framework such as simulate() and visualize() functions, please refer to the Cropbox documentation.","category":"page"}]
}
