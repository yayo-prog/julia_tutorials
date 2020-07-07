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
    shuf
end
