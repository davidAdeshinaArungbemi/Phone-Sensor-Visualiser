module DataPlot
using Revise
using Crayons
using GLFW
using CImGui
using ImPlot
using CImGui.ImGuiGLFWBackend
using CImGui.ImGuiGLFWBackend.LibCImGui
using CImGui.ImGuiGLFWBackend.LibGLFW
using CImGui.ImGuiOpenGLBackend
using CImGui.ImGuiOpenGLBackend.ModernGL
using CImGui.CSyntax

glfwDefaultWindowHints()
glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3)
glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 2)

if Sys.isapple()
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE) # 3.2+ only
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE) # required on Mac
end

# create window
window = glfwCreateWindow(1280, 720, "Gesture Visualisation & Analysis", C_NULL, C_NULL)
@assert window != C_NULL
glfwMakeContextCurrent(window)
glfwSwapInterval(1)  # enable vsync

# create OpenGL and GLFW context
window_ctx = ImGuiGLFWBackend.create_context(window)
gl_ctx = ImGuiOpenGLBackend.create_context()

# setup Dear ImGui and Implot context
ctx = CImGui.CreateContext()
ctxp = ImPlot.CreateContext()
ImPlot.SetImGuiContext(ctx)

# enable docking and multi-viewport
io = CImGui.GetIO()
io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_DockingEnable
# io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_ViewportsEnable

# setup Dear ImGui style
CImGui.StyleColorsLight()

fonts = unsafe_load(CImGui.GetIO().Fonts)
CImGui.AddFontFromFileTTF(fonts, "resources/Inter-VariableFont_slnt,wght.ttf", 16)

# setup Platform/Renderer bindings
ImGuiGLFWBackend.init(window_ctx)
ImGuiOpenGLBackend.init(gl_ctx)

clear_color = Cfloat[0, 0, 0, 1.00]

function fillIMUArray(imuData)
    for data in imuData
        for val in data

        end
    end
end

function createPlot(imuChannel::Channel, urlChannel::Channel, measurement_dtype::DataType)

    data_size = 10000

    ACCX_VALUES::Vector{measurement_dtype} = []
    ACCY_VALUES::Vector{measurement_dtype} = []
    ACCZ_VALUES::Vector{measurement_dtype} = []

    GYRX_VALUES::Vector{measurement_dtype} = []
    GYRY_VALUES::Vector{measurement_dtype} = []
    GYRZ_VALUES::Vector{measurement_dtype} = []

    MAGX_VALUES::Vector{measurement_dtype} = []
    MAGY_VALUES::Vector{measurement_dtype} = []
    MAGZ_VALUES::Vector{measurement_dtype} = []

    #place url here
    url_buffer::String = "http://000.000.000.000:8080/get?linX&linY&linZ&gyrX&gyrY&gyrZ&magX&magY&magZ&lin_time&gyr_time&mag_time"
    URLBUFFERSIZE = length(url_buffer) + 10
    put!(urlChannel, url_buffer)

    try
        while glfwWindowShouldClose(window) == 0
            glfwPollEvents()
            # start the Dear ImGui frame
            ImGuiOpenGLBackend.new_frame(gl_ctx)
            ImGuiGLFWBackend.new_frame(window_ctx)
            CImGui.NewFrame()

            width, height = Ref{Cint}(), Ref{Cint}()
            glfwGetWindowSize(window, width, height)

            CImGui.SetNextWindowPos((0, 0))

            CImGui.Begin("Control", C_NULL)
            CImGui.SetWindowSize(ImVec2(CImGui.GetWindowSize().x, height[]), CImGui.ImGuiCond_Always)
            CImGui.BeginTabBar("Tabs")

            try
                if isready(imuChannel)
                    state = take!(imuChannel)
                    push!(ACCX_VALUES, state[1])
                    push!(ACCY_VALUES, state[2])
                    push!(ACCZ_VALUES, state[3])

                    push!(GYRX_VALUES, state[4])
                    push!(GYRY_VALUES, state[5])
                    push!(GYRZ_VALUES, state[6])

                    push!(MAGX_VALUES, state[7])
                    push!(MAGY_VALUES, state[8])
                    push!(MAGZ_VALUES, state[9])
                end
            catch e
                println("$(Crayon(foreground=:red))Error: $(Crayon(foreground=:white))$e")
            end

            if CImGui.BeginTabItem("Plots")
                if isready(urlChannel) #clear channel if filled
                    take!(urlChannel)
                end
                put!(urlChannel, url_buffer)

                CImGui.PushStyleVar(CImGui.ImGuiStyleVar_FrameRounding, 5.0)

                if CImGui.Button("Clear Data")
                    empty!(ACCX_VALUES)
                    empty!(ACCY_VALUES)
                    empty!(ACCZ_VALUES)

                    empty!(GYRX_VALUES)
                    empty!(GYRY_VALUES)
                    empty!(GYRZ_VALUES)

                    empty!(MAGX_VALUES)
                    empty!(MAGY_VALUES)
                    empty!(MAGZ_VALUES)
                end

                CImGui.PopStyleVar()

                CImGui.SameLine()

                if CImGui.InputText("URL", url_buffer, URLBUFFERSIZE) #update url buffer
                end

                CImGui.Separator()

                ImPlot.FitNextPlotAxes()
                if ImPlot.BeginPlot("Linear Acceleration(m/s^2)", "samples", "m/s^2")
                    if !isempty(ACCX_VALUES)
                        ImPlot.SetNextLineStyle(ImVec4(1, 0, 0, 1))
                        ImPlot.PlotLine(ACCX_VALUES, label_id="accX")
                        ImPlot.SetNextLineStyle(ImVec4(0, 1, 0, 1))
                        ImPlot.PlotLine(ACCY_VALUES, label_id="accY")
                        ImPlot.SetNextLineStyle(ImVec4(0, 0, 1, 1))
                        ImPlot.PlotLine(ACCZ_VALUES, label_id="accZ")
                    end
                    ImPlot.EndPlot()
                end

                ImPlot.FitNextPlotAxes()
                if ImPlot.BeginPlot("Gyroscope(rad/s)", "samples", "rad/s")
                    if !isempty(GYRX_VALUES)
                        ImPlot.SetNextLineStyle(ImVec4(1, 0, 0, 1))
                        ImPlot.PlotLine(GYRX_VALUES, label_id="gyrX")
                        ImPlot.SetNextLineStyle(ImVec4(0, 1, 0, 1))
                        ImPlot.PlotLine(GYRY_VALUES, label_id="gyrY")
                        ImPlot.SetNextLineStyle(ImVec4(0, 0, 1, 1))
                        ImPlot.PlotLine(GYRZ_VALUES, label_id="gyrZ")
                    end
                    ImPlot.EndPlot()
                end

                ImPlot.FitNextPlotAxes()
                if ImPlot.BeginPlot("Magnetic field(uT)", "samples", "uT")
                    if !isempty(MAGX_VALUES)
                        ImPlot.SetNextLineStyle(ImVec4(1, 0, 0, 1))
                        ImPlot.PlotLine(MAGX_VALUES, label_id="magX")
                        ImPlot.SetNextLineStyle(ImVec4(0, 1, 0, 1))
                        ImPlot.PlotLine(MAGY_VALUES, label_id="magY")
                        ImPlot.SetNextLineStyle(ImVec4(0, 0, 1, 1))
                        ImPlot.PlotLine(MAGZ_VALUES, label_id="magZ")
                    end
                    ImPlot.EndPlot()
                end
                CImGui.EndTabItem()
            end

            if CImGui.BeginTabItem("Logs")
                CImGui.EndTabItem()
            end

            CImGui.EndTabBar()
            CImGui.End()
            # rendering
            CImGui.Render()
            glfwMakeContextCurrent(window)

            width, height = Ref{Cint}(), Ref{Cint}() #! need helper fcn
            glfwGetFramebufferSize(window, width, height)
            display_w = width[]
            display_h = height[]

            glViewport(0, 0, display_w, display_h)
            glClearColor(clear_color...)
            glClear(GL_COLOR_BUFFER_BIT)
            ImGuiOpenGLBackend.render(gl_ctx)

            if unsafe_load(igGetIO().ConfigFlags) & ImGuiConfigFlags_ViewportsEnable == ImGuiConfigFlags_ViewportsEnable
                backup_current_context = glfwGetCurrentContext()
                igUpdatePlatformWindows()
                GC.@preserve gl_ctx igRenderPlatformWindowsDefault(C_NULL, pointer_from_objref(gl_ctx))
                glfwMakeContextCurrent(backup_current_context)
            end

            glfwSwapBuffers(window)

            sleep(0.01)
        end  #end of while loop
    catch e
        @error "Error in renderloop!" exception = e
        Base.show_backtrace(stderr, catch_backtrace())
    finally
        ImGuiOpenGLBackend.shutdown(gl_ctx)
        ImGuiGLFWBackend.shutdown(window_ctx)
        ImPlot.DestroyContext(ctxp)
        CImGui.DestroyContext(ctx)
        glfwDestroyWindow(window)
    end
end
end