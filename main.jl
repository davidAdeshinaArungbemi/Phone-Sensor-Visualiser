import Pkg
Pkg.resolve()
using Revise
include("src/dataloading.jl")
include("src/visualisation.jl")
import .DataLoader: readData
import .DataPlot: createPlot

measurement_dtype::DataType = Float32 #free to change, controls the precision of received data

imuChannel = Channel{Vector{measurement_dtype}}(0) #send imu data from readData to createPlot()
urlChannel = Channel{String}(1) #communicating the URL to getURLResponse()

@sync begin
    @async readData(imuChannel, urlChannel, measurement_dtype)
    @async createPlot(imuChannel, urlChannel, measurement_dtype)
end

# task1 = Threads.@spawn readData(imuChannel, urlChannel, measurement_dtype)
# createPlot(imuChannel, urlChannel, measurement_dtype)