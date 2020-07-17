module PuzzleGame

using Images, ImageView, TestImages
using Gtk, Reactive, GtkReactive
using Random

export main

function rules()
    println("please swap tiles to complete the image")
end

function init_game(img::Array{T,2}; nof_row_blocks::Int=4, nof_col_blocks::Int=4 ) where T  <: Colorant
    global block_size
    block_size = Int.(size(img) ./ (nof_row_blocks, nof_col_blocks))
    row_slices = [ i*block_size[1] + 1 : (i+1) * block_size[1] for i in 0:nof_row_blocks-1]
    col_slices = [ i*block_size[2] + 1 : (i+1) * block_size[2] for i in 0:nof_col_blocks-1] 
    
    blocks = [(x,y) for y in col_slices for x in row_slices]
    
    shuf = zeros(eltype(img), size(img))
    shuf_blocks = shuffle(blocks)
    
    for b in 1:length(blocks)
        shuf[shuf_blocks[b][1], shuf_blocks[b][2]] = img[blocks[b][1], blocks[b][2]]
    end
    shuf
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

function main()
    img = testimage("fabio")
    new = init_game(img)
    guidict = imshow(new)
    rules()

    @guarded signal_connect(guidict["gui"]["window"], :destroy) do widget
        isAcitve = false
        println("you closded the window")
    end

    coord_sig = @guarded map(guidict["gui"]["canvas"].mouse.buttonpress, init=(0.0,0.0)) do btn
        global ann_handler, firstClick
        row = Float64(btn.position.x)
        col = Float64(btn.position.y)
        println("you clicked @ [x=$(row), y=$(col)] with $(btn.button)")
        margins = get_block_coords((row, col), block_size)

        if firstClick
            println("highlight the selected block")
            ann_handler = annotate!(guidict, AnnotationBox(margins[1], margins[2], margins[3], margins[4],
                                    linewidth=2.5, color=colorant"blue"))
            firstClick = false

        else
            println("swap the blocks")
            prev_margins = Int.([ann_handler.ann.data.left, ann_handler.ann.data.top, ann_handler.ann.data.right, ann_handler.ann.data.bottom])
            swap_blocks(margins, prev_margins, new)
            delete!(guidict, ann_handler)
            firstClick = true
        end

        return row,col
    end

    return guidict
end

#Top level code
firstClick = true
isActive = true
if !isinteractive()
    main()
    while isAcitve
        sleep(1)
    end
    println("code done..")
end

end # module PuzzleGame
