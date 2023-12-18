module DataLoader
using HTTP
using JSON
# using DataFrames
using CSV
using Crayons

# Construct the URL

# url = "http://192.168.17.35:8080/get?linX&linY&linZ&gyrX&gyrY&gyrZ&magX&magY&magZ&lin_time&gyr_time&mag_time"

MEAS_DTYPE = Float32 #alias for type

# DATAFRAME = DataFrame(accX=MEAS_DTYPE[], accY=MEAS_DTYPE[], accZ=MEAS_DTYPE[],
#     gyrX=MEAS_DTYPE[], gyrY=MEAS_DTYPE[], gyrZ=MEAS_DTYPE[],
#     magX=MEAS_DTYPE[], magY=MEAS_DTYPE[], magZ=MEAS_DTYPE[], acc_time=MEAS_DTYPE[], gcc_time=MEAS_DTYPE[], mag_time=MEAS_DTYPE[])

reading_type_arr::Vector{String} = ["linX", "linY", "linZ", "gyrX", "gyrY", "gyrZ", "magX", "magY", "magZ", "lin_time", "gyr_time", "mag_time"]

function readData(channel::Channel, channel2::Channel, url::String="http://192.168.17.35:8080/get?linX&linY&linZ&gyrX&gyrY&gyrZ&magX&magY&magZ&lin_time&gyr_time&mag_time", MEAS_DTYPE=MEAS_DTYPE)
    no_data_received_count = 0
    while true
        # println("$(Crayon(foreground=:yellow))Channel is empty: $(Crayon(foreground=:green))$(isempty(channel2))")
        if !isempty(channel2)
            try
                #check if url is online
                response = HTTP.get(url, headers=["Accept" => "application/json", "Content-Type" => "application/json"]) # Make an HTTP GET request to the URL
                if HTTP.status(response) == 200 # Check if the request was successful (status code 200)
                    # println("$(Crayon(foreground=:green))HTTP Resquest successful")

                    data = JSON.parse(String(response.body)) #read data

                    if data["status"]["measuring"] == false && data["status"]["countDown"] > 0 #check is data is not being sent and if there is a countdown
                        #note countdown received in milliseconds
                        countdown::Float32 = data["status"]["countDown"] / 1000
                        println(Crayon(foreground=:yellow), "Countdown of $countdown sec")
                        sleep(countdown + 0.005)

                    elseif data["status"]["measuring"] == false #if data is not sent and its not a timed run
                        no_data_received_count += 1
                        println("$(Crayon(foreground=:yellow))No data received")
                        if no_data_received_count > 5 #limit of allowed "no data"
                            no_data_received_count = 0
                            println("$(Crayon(foreground=:yellow))No data received limit exceeded")
                            take!(channel2)
                        end

                    else #if data is being sent, reading sample
                        readings_value_arr::Vector{MEAS_DTYPE} = []
                        for reading_n in reading_type_arr
                            push!(readings_value_arr, data["buffer"][reading_n]["buffer"][1]) #add row elements
                        end

                        println("
                        ACC(m/s^2) => $(Crayon(foreground=:yellow))AccX: $(Crayon(foreground=:green))$(readings_value_arr[1]), $(Crayon(foreground=:yellow))AccY: $(Crayon(foreground=:green))$(readings_value_arr[2]), $(Crayon(foreground=:yellow))AccZ: $(Crayon(foreground=:green))$(readings_value_arr[3]), 
                        GYR(rad/s) => $(Crayon(foreground=:yellow))GyrX: $(Crayon(foreground=:green))$(readings_value_arr[4]), $(Crayon(foreground=:yellow))GyrY: $(Crayon(foreground=:green))$(readings_value_arr[5]), $(Crayon(foreground=:yellow))GyrZ: $(Crayon(foreground=:green))$(readings_value_arr[6]),
                        MAG(μT) => $(Crayon(foreground=:yellow))MagX: $(Crayon(foreground=:green))$(readings_value_arr[7]), $(Crayon(foreground=:yellow))MagY: $(Crayon(foreground=:green))$(readings_value_arr[8]), $(Crayon(foreground=:yellow))MagZ: $(Crayon(foreground=:green))$(readings_value_arr[9]),
                        Time(s) => $(Crayon(foreground=:yellow))Acc_time: $(Crayon(foreground=:green))$(readings_value_arr[10]), $(Crayon(foreground=:yellow))Gyr_time: $(Crayon(foreground=:green))$(readings_value_arr[11]), $(Crayon(foreground=:yellow))Mag_time: $(Crayon(foreground=:green))$(readings_value_arr[12])"
                        )
                        put!(channel, readings_value_arr)

                        # println("$(Crayon(foreground=:green))Data added to channel successfuly")
                    end
                    # push!(DATAFRAME, readings_value_arr) #add row to dataframe
                else
                    println("$(Crayon(foreground=:yellow))Warning: $(Crayon(foreground=:white))Unable to fetch data. Status code: ", HTTP.status(response))
                end
            catch
                println("$(Crayon(foreground=:yellow))Ensure that the host is online")

            end #end of try catch
            # sleep(0.2)
        end#end if
        # println("$(Crayon(foreground=:blue))Delay added")
        sleep(0.01)
    end # end of while loop
end #end of function

end #end of module