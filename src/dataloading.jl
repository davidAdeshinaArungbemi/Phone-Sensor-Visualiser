module DataLoader
using HTTP
using JSON
using Crayons
reading_type_arr::Vector{String} = ["linX", "linY", "linZ", "gyrX", "gyrY", "gyrZ", "magX", "magY", "magZ", "lin_time", "gyr_time", "mag_time"]

function readData(imuChannel::Channel, urlChannel::Channel, measurement_dtype::DataType)
    url = ""
    while true
        try
            if isready(urlChannel)
                url = take!(urlChannel)
            end

            response = HTTP.get(url, headers=["Accept" => "application/json", "Content-Type" => "application/json"])

            if HTTP.status(response) == 200 #if successful
                data = JSON.parse(String(response.body)) #read data

                if data["status"]["measuring"] == false && data["status"]["countDown"] > 0
                    countdown::Float32 = data["status"]["countDown"] / 1000 #secs
                    println(Crayon(foreground=:yellow), "Countdown of $countdown sec")

                elseif data["status"]["measuring"] == false
                    println("$(Crayon(foreground=:yellow))No data received")

                else #if data is being sent, reading sample
                    readings_value_arr::Vector{measurement_dtype} = []
                    for reading_n in reading_type_arr
                        push!(readings_value_arr, data["buffer"][reading_n]["buffer"][1]) #add row elements
                    end

                    println("
                    ACC(m/s^2) => $(Crayon(foreground=:yellow))AccX: $(Crayon(foreground=:green))$(readings_value_arr[1]), $(Crayon(foreground=:yellow))AccY: $(Crayon(foreground=:green))$(readings_value_arr[2]), $(Crayon(foreground=:yellow))AccZ: $(Crayon(foreground=:green))$(readings_value_arr[3]), 
                    GYR(rad/s) => $(Crayon(foreground=:yellow))GyrX: $(Crayon(foreground=:green))$(readings_value_arr[4]), $(Crayon(foreground=:yellow))GyrY: $(Crayon(foreground=:green))$(readings_value_arr[5]), $(Crayon(foreground=:yellow))GyrZ: $(Crayon(foreground=:green))$(readings_value_arr[6]),
                    MAG(μT) => $(Crayon(foreground=:yellow))MagX: $(Crayon(foreground=:green))$(readings_value_arr[7]), $(Crayon(foreground=:yellow))MagY: $(Crayon(foreground=:green))$(readings_value_arr[8]), $(Crayon(foreground=:yellow))MagZ: $(Crayon(foreground=:green))$(readings_value_arr[9]),
                    Time(s) => $(Crayon(foreground=:yellow))Acc_time: $(Crayon(foreground=:green))$(readings_value_arr[10]), $(Crayon(foreground=:yellow))Gyr_time: $(Crayon(foreground=:green))$(readings_value_arr[11]), $(Crayon(foreground=:yellow))Mag_time: $(Crayon(foreground=:green))$(readings_value_arr[12])"
                    )
                    put!(imuChannel, readings_value_arr)
                end
            else
                println("$(Crayon(foreground=:yellow))Warning: $(Crayon(foreground=:white))Unable to fetch data. Status code: ", HTTP.status(response))
            end
        catch e
            println("$(Crayon(foreground=:yellow))Problem: $(Crayon(foreground=:white))$e")
        end #end of try catch
        sleep(0.01)
    end # end of while loop
end #end of function
end #end of module