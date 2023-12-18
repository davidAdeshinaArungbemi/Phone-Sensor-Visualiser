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

include("dataloading.jl")
import .DataLoader: readData, MEAS_DTYPE

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
# CImGui.StyleColorsDark()
# CImGui.StyleColorsClassic()
CImGui.StyleColorsLight()

# When viewports are enabled we tweak WindowRounding/WindowBg so platform windows can look identical to regular ones.
style = Ptr{ImGuiStyle}(CImGui.GetStyle())
if unsafe_load(io.ConfigFlags) & ImGuiConfigFlags_ViewportsEnable == ImGuiConfigFlags_ViewportsEnable
    style.WindowRounding = 5.0f0
    col = CImGui.c_get(style.Colors, CImGui.ImGuiCol_WindowBg)
    CImGui.c_set!(style.Colors, CImGui.ImGuiCol_WindowBg, ImVec4(col.x, col.y, col.z, 1.0f0))
end

fonts = unsafe_load(CImGui.GetIO().Fonts)
CImGui.AddFontFromFileTTF(fonts, "resources/Inter-VariableFont_slnt,wght.ttf", 16)

# setup Platform/Renderer bindings
ImGuiGLFWBackend.init(window_ctx)
ImGuiOpenGLBackend.init(gl_ctx)

#hold array of each sensor axis values
accX_values = MEAS_DTYPE[]
accY_values = MEAS_DTYPE[]
accZ_values = MEAS_DTYPE[]

gyrX_values = MEAS_DTYPE[]
gyrY_values = MEAS_DTYPE[]
gyrZ_values = MEAS_DTYPE[]

magX_values = MEAS_DTYPE[]
magY_values = MEAS_DTYPE[]
magZ_values = MEAS_DTYPE[]

activate_record = false

try
    demo_open = true
    clear_color = Cfloat[0, 0, 0, 1.00]

    #channels for communication between background and gui
    channel = Channel{Any}(0) #communicating the IMU data
    channel2 = Channel{Bool}(1) #communcating, to inform backend to connect to url and collect data
    task = Threads.@spawn readData(channel, channel2)

    while glfwWindowShouldClose(window) == 0
        glfwPollEvents()
        # start the Dear ImGui frame
        ImGuiOpenGLBackend.new_frame(gl_ctx)
        ImGuiGLFWBackend.new_frame(window_ctx)
        CImGui.NewFrame()

        width, height = Ref{Cint}(), Ref{Cint}()
        glfwGetWindowSize(window, width, height)

        # demo_open && @c CImGui.ShowDemoWindow(&demo_open)
        CImGui.SetNextWindowPos((0, 0))

        CImGui.Begin("Data Visualiser", C_NULL)
        CImGui.SetWindowSize(ImVec2(CImGui.GetWindowSize().x, height[]), CImGui.ImGuiCond_Always)

        CImGui.PushStyleVar(CImGui.ImGuiStyleVar_FrameRounding, 5.0)

        if CImGui.Button("Record") && isempty(channel2)
            # println("$(Crayon(foreground=:yellow))FRONTEND: $(Crayon(foreground=:green))\'Record Button\' Pressed!")
            global activate_record = true
            # println("$(Crayon(foreground=:yellow))FRONTEND: $(Crayon(foreground=:green))Placing boolean to channel")
            put!(channel2, activate_record)
            # println("$(Crayon(foreground=:yellow))FRONTEND: $(Crayon(foreground=:green))boolean placed in channel!")
        end

        CImGui.PopStyleVar()

        CImGui.SameLine()

        CImGui.PushStyleVar(CImGui.ImGuiStyleVar_FrameRounding, 5.0)

        if CImGui.Button("Reset")
            # println("$(Crayon(foreground=:yellow))FRONTEND: $(Crayon(foreground=:green))\'Reset Button\' Pressed!")
            global activate_record = false

            if !isempty(channel2)
                take!(channel2) #take value from channel2
            end

            global accX_values = MEAS_DTYPE[]
            global accY_values = MEAS_DTYPE[]
            global accZ_values = MEAS_DTYPE[]

            global gyrX_values = MEAS_DTYPE[]
            global gyrY_values = MEAS_DTYPE[]
            global gyrZ_values = MEAS_DTYPE[]

            global magX_values = MEAS_DTYPE[]
            global magY_values = MEAS_DTYPE[]
            global magZ_values = MEAS_DTYPE[]
        end

        CImGui.PopStyleVar()

        CImGui.Separator()

        try
            if isready(channel)
                # println("$(Crayon(foreground=:yellow))FRONTEND: $(Crayon(foreground=:green))Data available")
                # sleep(0.05)
                state = take!(channel)
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
            println(Crayon(foreground=:red), "$(Crayon(foreground=:red))Error: $(Crayon(foreground=:white))$e")
            # activate_record = false
        end

        color1 = 1
        color2 = 1
        color3 = 1

        ImPlot.FitNextPlotAxes()
        if ImPlot.BeginPlot("Linear Acceleration(m/s^2)", "samples", "m/s^2")
            if !isempty(accX_values) && !isempty(accY_values) && !isempty(accZ_values)
                ImPlot.SetNextLineStyle(ImVec4(color1, 0, 0, 1))
                ImPlot.PlotLine(accX_values, label_id="accX")
                ImPlot.SetNextLineStyle(ImVec4(0, color2, 0, 1))
                ImPlot.PlotLine(accY_values, label_id="accY")
                ImPlot.SetNextLineStyle(ImVec4(0, 0, color3, 1))
                ImPlot.PlotLine(accZ_values, label_id="accZ")
            end
            ImPlot.EndPlot()
        end

        ImPlot.FitNextPlotAxes()
        if ImPlot.BeginPlot("Gyroscope(rad/s)", "samples", "rad/s")
            if !isempty(gyrX_values) && !isempty(gyrY_values) && !isempty(gyrZ_values)
                ImPlot.SetNextLineStyle(ImVec4(color1, 0, 0, 1))
                ImPlot.PlotLine(gyrX_values, label_id="gyrX")
                ImPlot.SetNextLineStyle(ImVec4(0, color2, 0, 1))
                ImPlot.PlotLine(gyrY_values, label_id="gyrY")
                ImPlot.SetNextLineStyle(ImVec4(0, 0, color3, 1))
                ImPlot.PlotLine(gyrZ_values, label_id="gyrZ")
            end
            ImPlot.EndPlot()
        end

        ImPlot.FitNextPlotAxes()
        if ImPlot.BeginPlot("Magnetic field(uT)", "x1", "uT")
            if !isempty(accX_values) && !isempty(magY_values) && !isempty(magZ_values)
                ImPlot.SetNextLineStyle(ImVec4(color1, 0, 0, 1))
                ImPlot.PlotLine(magX_values, label_id="magX")
                ImPlot.SetNextLineStyle(ImVec4(0, color2, 0, 1))
                ImPlot.PlotLine(magY_values, label_id="magY")
                ImPlot.SetNextLineStyle(ImVec4(0, 0, color3, 1))
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
    end  #end of for loop
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
# module DataVisualisation


# end