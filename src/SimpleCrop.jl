module SimpleCrop

using Cropbox

include("plant.jl")
include("soilwater.jl")
include("weather.jl")

@system Model(Plant, SoilWater, Weather, Controller)

export Model

end
