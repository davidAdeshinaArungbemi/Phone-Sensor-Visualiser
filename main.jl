import Pkg
Pkg.instantiate()
using Revise
include("src/dataloading.jl")
include("src/visualisation.jl")
import .DataLoader: readData
import .DataPlot: createPlot

measurement_dtype = Float32

imuChannel = Channel{Vector{measurement_dtype}}(0) #send imu data from readData to createPlot()
urlChannel = Channel{String}(1) #communicating the URL to getURLResponse()

task1 = Threads.@spawn readData(imuChannel, urlChannel, measurement_dtype)
createPlot(imuChannel, urlChannel, measurement_dtype)
