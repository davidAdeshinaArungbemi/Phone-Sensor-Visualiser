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


function createPlot(imuChannel::Channel, urlChannel::Channel, measurement_dtype::DataType)
    global accX_values = measurement_dtype[]
    global accY_values = measurement_dtype[]
    global accZ_values = measurement_dtype[]

    global gyrX_values = measurement_dtype[]
    global gyrY_values = measurement_dtype[]
    global gyrZ_values = measurement_dtype[]

    global magX_values = measurement_dtype[]
    global magY_values = measurement_dtype[]
    global magZ_values = measurement_dtype[]

    url_buffer::String = "http://192.168.17.35:8080/get?linX&linY&linZ&gyrX&gyrY&gyrZ&magX&magY&magZ&lin_time&gyr_time&mag_time"
    put!(urlChannel, url_buffer)

    # sleep(0.01)

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

            CImGui.Begin("Data Visualiser", C_NULL)
            CImGui.SetWindowSize(ImVec2(CImGui.GetWindowSize().x, height[]), CImGui.ImGuiCond_Always)

            CImGui.PushStyleVar(CImGui.ImGuiStyleVar_FrameRounding, 5.0)
            if CImGui.Button("Record")
                if isready(urlChannel) #clear channel if filled
                    take!(urlChannel)
                end
                put!(urlChannel, url_buffer)
            end
            CImGui.PopStyleVar()

            CImGui.SameLine()

            CImGui.PushStyleVar(CImGui.ImGuiStyleVar_FrameRounding, 5.0)

            if CImGui.Button("Reset")
                global accX_values = measurement_dtype[]
                global accY_values = measurement_dtype[]
                global accZ_values = measurement_dtype[]

                global gyrX_values = measurement_dtype[]
                global gyrY_values = measurement_dtype[]
                global gyrZ_values = measurement_dtype[]

                global magX_values = measurement_dtype[]
                global magY_values = measurement_dtype[]
                global magZ_values = measurement_dtype[]
            end

            CImGui.PopStyleVar()

            CImGui.SameLine()

            if CImGui.InputText("URL", url_buffer, length(url_buffer) + 10) #update url buffer
            end

            CImGui.Separator()

            try
                if isready(imuChannel)
                    state = take!(imuChannel)
                    push!(accX_values, state[1])
                    push!(accY_values, state[2])
                    push!(accZ_values, state[3])

                    push!(gyrX_values, state[4])
                    push!(gyrY_values, state[5])
                    push!(gyrZ_values, state[6])

                    push!(magX_values, state[7])
                    push!(magY_values, state[8])
                    push!(magZ_values, state[9])
                end
            catch e
                println("$(Crayon(foreground=:red))Error: $(Crayon(foreground=:white))$e")
            end

            ImPlot.FitNextPlotAxes()
            if ImPlot.BeginPlot("Linear Acceleration(m/s^2)", "samples", "m/s^2")
                if !isempty(accX_values)
                    ImPlot.SetNextLineStyle(ImVec4(1, 0, 0, 1))
                    ImPlot.PlotLine(accX_values, label_id="accX")
                    ImPlot.SetNextLineStyle(ImVec4(0, 1, 0, 1))
                    ImPlot.PlotLine(accY_values, label_id="accY")
                    ImPlot.SetNextLineStyle(ImVec4(0, 0, 1, 1))
                    ImPlot.PlotLine(accZ_values, label_id="accZ")
                end
                ImPlot.EndPlot()
            end

            ImPlot.FitNextPlotAxes()
            if ImPlot.BeginPlot("Gyroscope(rad/s)", "samples", "rad/s")
                if !isempty(gyrX_values)
                    ImPlot.SetNextLineStyle(ImVec4(1, 0, 0, 1))
                    ImPlot.PlotLine(gyrX_values, label_id="gyrX")
                    ImPlot.SetNextLineStyle(ImVec4(0, 1, 0, 1))
                    ImPlot.PlotLine(gyrY_values, label_id="gyrY")
                    ImPlot.SetNextLineStyle(ImVec4(0, 0, 1, 1))
                    ImPlot.PlotLine(gyrZ_values, label_id="gyrZ")
                end
                ImPlot.EndPlot()
            end

            ImPlot.FitNextPlotAxes()
            if ImPlot.BeginPlot("Magnetic field(uT)", "samples", "uT")
                if !isempty(magX_values)
                    ImPlot.SetNextLineStyle(ImVec4(1, 0, 0, 1))
                    ImPlot.PlotLine(magX_values, label_id="magX")
                    ImPlot.SetNextLineStyle(ImVec4(0, 1, 0, 1))
                    ImPlot.PlotLine(magY_values, label_id="magY")
                    ImPlot.SetNextLineStyle(ImVec4(0, 0, 1, 1))
                    ImPlot.PlotLine(magZ_values, label_id="magZ")
                end
                ImPlot.EndPlot()
            end

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