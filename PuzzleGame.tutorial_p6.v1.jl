module PuzzleGame

using Images, ImageView, TestImages
using Gtk, Reactive, GtkReactive
using Random
import Base.show

export main

mutable struct GameState{T <: Colorant}
    img::Array{T,2}
    shuf::Array{T,2}
    guidict::Dict{String, Any}

    isActive::Bool
    firstClick::Bool

    nof_blocks::Tuple{Int,Int}
    block_size::Tuple{Int,Int}

    box_handler::Union{Nothing,ImageView.AnnotationHandle{ImageView.AnchoredAnnotation{AnnotationBox}}}
    swaps::Int

    function GameState(img::Array{K,2}; nof_blocks::Tuple{Int,Int}=(4,4)) where K <: Colorant
        shuf, block_size= init_game(img, nof_row_blocks=nof_blocks[1], nof_col_blocks=nof_blocks[2])
        guidict = imshow(shuf, name="Image Puzzle Game")
        new{K}(img, shuf, guidict, true, true, nof_blocks, block_size, nothing, 0)
    end
end

function show(io::IO, game::GameState)
    print("Game $(game.isActive ? "On-Goning" :  "Ended") conducted $(game.swaps) swaps")
end
function show(io::IO, ::MIME"text/plain", game::GameState)
    print("3 arg metod Game $(game.isActive ? "On-Goning" :  "Ended")")
end

function rules()
    println("please swap tiles to complete the image")
end

function init_game(img::Array{T,2}; nof_row_blocks::Int=4, nof_col_blocks::Int=4 ) where T  <: Colorant
    block_size = Int.(size(img) ./ (nof_row_blocks, nof_col_blocks))
    row_slices = [ i*block_size[1] + 1 : (i+1) * block_size[1] for i in 0:nof_row_blocks-1]
    col_slices = [ i*block_size[2] + 1 : (i+1) * block_size[2] for i in 0:nof_col_blocks-1] 
    
    blocks = [(x,y) for y in col_slices for x in row_slices]
    
    shuf = zeros(eltype(img), size(img))
    shuf_blocks = shuffle(blocks)
    
    for b in 1:length(blocks)
        shuf[shuf_blocks[b][1], shuf_blocks[b][2]] = img[blocks[b][1], blocks[b][2]]
    end
    shuf, block_size
end

"""
get the margins of the block from (x,y) pixel location
"""
function get_block_coords(coord::Tuple{AbstractFloat, AbstractFloat}, block_size::Tuple{Int,Int})
    offset = rem.(coord, block_size)
    left = coord[1] - offset[1] + 1
    top = coord[2] - offset[2] + 1

    right = left + block_size[1] - 1
    bottom = top + block_size[2] - 1

    margins = Int.(round.([left, top, right, bottom]))
    return margins
end

"""
box = Int.([left, top, right, bottom])
"""
function swap_blocks(boxA, boxB, img)
    tmp = img[boxA[2]:boxA[4], boxA[1]:boxA[3]] 
    img[boxA[2]:boxA[4], boxA[1]:boxA[3]] = img[boxB[2]:boxB[4], boxB[1]:boxB[3]]
    img[boxB[2]:boxB[4], boxB[1]:boxB[3]] = tmp
    return img
end


function do_click(btn::GtkReactive.MouseButton{GtkReactive.UserUnit}, game_state::GameState)
    row = Float64(btn.position.x)
    col = Float64(btn.position.y)
    println("you clicked @ [x=$(row), y=$(col)] with $(btn.button)")
    margins = get_block_coords((row, col), game_state.block_size)

    if game_state.firstClick
        println("highlight the selected block")
        game_state.box_handler = annotate!(game_state.guidict, AnnotationBox(margins[1], margins[2], margins[3], margins[4],
                                linewidth=2.5, color=colorant"blue"))
        game_state.firstClick = false

    else
        println("swap the blocks")
        prev_margins = Int.([game_state.box_handler.ann.data.left, game_state.box_handler.ann.data.top, game_state.box_handler.ann.data.right, game_state.box_handler.ann.data.bottom])
        swap_blocks(margins, prev_margins, game_state.shuf)
        delete!(game_state.guidict, game_state.box_handler)
        game_state.swaps += 1
        game_state.firstClick = true
    end
    return row,col
end


function main()
    img = testimage("fabio")
    game_state = GameState(img)
    rules()

    @guarded signal_connect(game_state.guidict["gui"]["window"], :destroy) do widget
        game_state.isAcitve = false
        println("you closded the window")
    end

    partial_do_click(btn::GtkReactive.MouseButton{GtkReactive.UserUnit}) = do_click(btn, game_state)
    coord_sig =  map(partial_do_click, game_state.guidict["gui"]["canvas"].mouse.buttonpress, init=(0.0,0.0))
    return game_state
end

#Top level code
if !isinteractive()
    state.main()
    while state.isAcitve
        sleep(1)
    end
    println("code done..")
end

end # module PuzzleGame
