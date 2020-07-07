using Images, GtkReactive, ImageView
using TestImages
using Gtk.ShortNames  # for signal_connect
using Random  # for the init game
import Base.show # Used for adding struct specific prints

# used example from    https://discourse.julialang.org/t/imageview-gtk-unastable-results/25267

mutable struct GameState
    img::Array{T,2} where T <:Colorant
    shuf_img::Array{T,2} where T <:Colorant
    guidict::Dict{String,Any}
    isActive::Bool
    isFirstClick::Bool
    nof_blocks::Int
    block_size::Int

    box_handler::Union{Nothing, ImageView.AnnotationHandle{ImageView.AnchoredAnnotation{AnnotationBox}} }
    blocks::Union{Nothing, Array{Tuple{UnitRange{Int64},UnitRange{Int64}},2}}
    swaps::Int64

    function GameState(img::Array{T,2}, nof_blocks::Int) where T<:Colorant
        shuf_img, blocks, block_size = initGame(img, nof_blocks)
        guidict = imshow(shuf_img)
        new(img, shuf_img, guidict, true, true, nof_blocks, block_size, nothing,blocks,0)
    end

    function GameState(img::Array{T,2}) where T<:Colorant
        #default if 4 block per row
        shuf_img, blocks, block_size = initGame(img, 4)
        guidict = imshow(shuf_img)
        new(img, shuf_img, guidict, true, true, 4, block_size, nothing,blocks,0)
    end
end
"""
Dedicated show function for the GameState struct
"""
function show(io::IO, ::MIME"text/plain", game::GameState)
    active_str = game.isActive ? "Active" : "Not Active"
    window_name = get_gtk_property(game.guidict["gui"]["window"], :name, String)
    ann_cnt = length(game.guidict["annotations"].value)
    print(io, "Game State: $(active_str).")
          #In window '$(window_name)'' has $(ann_cnt) annotations and $(game.swaps) swaps (nof_blocks = $(game.nof_blocks))")
end

"""
Override the print version as well
"""
function show(io::IO, game::GameState)
    active_str = game.isActive ? "Active" : "Not Active"
    window_name = get_gtk_property(game.guidict["gui"]["window"], :name, String)
    ann_cnt = length(game.guidict["annotations"].value)
    print(io, "Game State: $(active_str).",
          "In window '$(window_name)'' has $(ann_cnt) annotations and $(game.swaps) swaps (nof_blocks = $(game.nof_blocks))")
end


"""
Shuffles the input image to an unorderded versoin
"""
function initGame(img::Array{T,2}, nof_blocks::Int) where T<:Colorant
    block_size = Int(size(img)[1] / nof_blocks)
    # i* block_size + 1 : (i+1) * block_size
    row_range = [i* block_size + 1 : (i+1) * block_size for i in 0:nof_blocks-1]

    blocks = [(x,y) for x in row_range for y in row_range]
    blocks = reshape(blocks, nof_blocks, nof_blocks)  # orginze in a matrix for bebugging

    new = zeros(RGB, size(img))
    blocks_new = shuffle(blocks)
    for b in 1:length(blocks)
        new[blocks_new[b][1], blocks_new[b][2]] = img[blocks[b][1], blocks[b][2]]
    end
    return new, blocks, block_size
end

function close_window_signal(c::Base.GenericCondition{Base.AlwaysLockedST}, game::GameState)
    println("Window closed - finishing game")
    game.isActive = false
    notify(c)
end

"""
return box coordinates
if mode == "box" - coordinage in left, top, right. bottom
if mode == "ind" - indeceis matching the box index
"""
function get_box_coords(coord::Tuple{AbstractFloat,AbstractFloat}; box_size::Int=32, mode::String="box")
    hor_offset = rem(coord[1], box_size)
    ver_offset = rem(coord[2], box_size)

    row_ind = Int(div(coord[1], box_size))
    col_ind = Int(div(coord[2], box_size))

    left = coord[1] - hor_offset + 1
    top = coord[2] - ver_offset + 1

    right = coord[1] - hor_offset + box_size
    bottom = coord[2] - ver_offset + box_size

    if mode == "box"
        println("box: left=$left top=$top right=$right bottom=$bottom")
        return Int.(round.([left,top,right,bottom]))
    elseif mode == "ind"
        println("box index row=$row_ind col=$col_ind")
        return row_ind,col_ind
    else
        nothing
    end
end

function mark_box(left,top,right,bottom; color::RGB=RGB(0,0,1))
    global guidict
    box_ann = annotate!(guidict, AnnotationBox(left,top,right,bottom, linewidth=2.5, color=color))
end


function swap_boxes(game_state::GameState, boxA, boxB)
    img = game_state.shuf_img
    boxA = Int.(round.(boxA))
    boxB = Int.(round.(boxB))
    game_state.box_handler.ann.data.left
    tmp = copy(img[boxA[2]:boxA[4], boxA[1]:boxA[3]])
    img[boxA[2]:boxA[4], boxA[1]:boxA[3]] = img[boxB[2]:boxB[4], boxB[1]:boxB[3]]
    img[boxB[2]:boxB[4], boxB[1]:boxB[3]] = tmp
    img
end


# ===============
# Main game Flow
# ===============


nof_blocks = 2
img = testimage("lena")

# open window and show the image
game_state = GameState(img, nof_blocks)
guidict = game_state.guidict

# Create a condition object
c = Condition()

# shorthandes for some of the objects
win = game_state.guidict["gui"]["window"]
can = game_state.guidict["gui"]["canvas"]

gui = game_state.guidict["gui"]

# Notify the condition object when the window closes
signal_connect(close_window_signal, win, :destroy)

# controlling the button press signal - https://juliagizmos.github.io/GtkReactive.jl/stable/drawing.html
# NOTE: using a simple map will work in interacive way , but when used in a script we will need to prevent it from getting
#       collected by the garbage collector - the way is to assign it to a varable and use prevent gc
sig_click = map(can.mouse.buttonpress) do btn  # Reactive.Signal{GtkReactive.MouseButton{GtkReactive.UserUnit}}
    global game_state
    x_curr = Float64(btn.position.x)  #row
    y_curr = Float64(btn.position.y)  # col
    println("Found a button clicked @ [x=$(round(x_curr, digits=2)), y=$(round(y_curr, digits=2))]")
    println(game_state)

    # invalid points occur at startup
    if x_curr > 0 && y_curr > 0
        if game_state.isFirstClick
            println("first click")  # TODO: add hihlight of the block
            game_state.isFirstClick = false
            cc = get_box_coords((x_curr, y_curr), box_size=game_state.block_size)
            #box_ann = mark_box(cc[1], cc[2], cc[3], cc[4])
            game_state.box_handler = annotate!(game_state.guidict, AnnotationBox(cc[1], cc[2], cc[3], cc[4], linewidth=2.5, color=colorant"blue"))

            println("cc meta data:",typeof(cc), cc)
        else
            println("second click - need to swap") # TODO: add swap functionality
            game_state.isFirstClick = true
            game_state.swaps += 1
            left,top,right,bottom = get_box_coords((x_curr, y_curr), box_size=game_state.block_size)
            # FIXME try showing a very short period of selected box - and then sleep and remove
            #       the refresh does not work

            swap_boxes(game_state,
                       [game_state.box_handler.ann.data.left, game_state.box_handler.ann.data.top,
                        game_state.box_handler.ann.data.right, game_state.box_handler.ann.data.bottom],
                       [left,top,right,bottom])

            delete!(game_state.guidict, game_state.box_handler)
        end
    end
    if game_state.img == game_state.shuf_img
        println("Game WON!!!  finishing game")
        notify(c)
    end
end

GtkReactive.gc_preserve(win, sig_click)  # prevetns the mapping from being garbage collected



# Wait for the notification before proceeding ...
wait(c)
