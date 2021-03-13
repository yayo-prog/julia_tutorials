using Images
using ImageView
using VideoIO
using PlutoUI
using ImageTransformations

north = load("/home/shefi/Pictures/flat_earth_north.png");
south = load("/home/shefi/Pictures/flat_earth_south.png");

# Scale the images
scale = 384  # 128*3
scale = 1024  # 128*6
north_s = imresize(north, scale, scale);
south_s = imresize(south, scale, scale);

println("North: $(size(north))  small version $(size(north_s))")
println("South: $(size(south))  small version $(size(south_s))")

function az_to_lat(az::Int)
    az = az % 360
    if az < 180
        "E $(Int(round(az, digits=0)))°"
    else
        "W $(Int(round(180-az, digits=0)))°"
    end
end

function flat_vertical_map(az::Int)
    rad = az * (2π/360);

    # keeps the axes - this is great for a cicular image
    north_rot = imrotate(north_s, rad + π/2, axes(north_s));
    south_rot = imrotate(south_s, -rad + π/2, axes(south_s));

    flat = vcat(north_rot,south_rot)
end

function flat_horizontal_map(az::Int, north_s::Array{T,2}, south_s::Array{T,2}) where T<:Colorant
    rad = az * (2π/360);

    # keeps the axes - this is great for a cicular image
    north_rot = imrotate(north_s, rad, axes(north_s));
    south_rot = imrotate(south_s, -rad, axes(south_s));

    flat = hcat(north_rot,south_rot)
end

function quad_flat(az::Int)
    rad = az * (2π/360);
    tl = imrotate(north_s, rad, axes(north_s));
    tr = imrotate(south_s, -rad, axes(south_s));
    bl = imrotate(south_s, -rad + π, axes(south_s));
    br = imrotate(north_s, rad + π, axes(north_s));

    flat = hcat(vcat(tl, bl), vcat(tr, br))
end


frames = []
for az in 100:1:520
    flat_earth = flat_vertical_map(az)
    frame = convert.(RGB, flat_earth)
    # annotate!(1.,1.,az_to_lat(az))
    push!(frames, frame)
end
    
vid_file = "/tmp/test.mp4"

# Using ffmpeg - did not work yet
# open(`ffmpeg -f rawvideo -pix_fmt gray -s:v 512x512 -r 70 -i pipe:0 $(vid_file)`, "w") do out
#     for frame in frames
#         # img = convert(Image{Gray{U8}}, frame)
#         # img = convert(Image{fmt}, frame)
#         img = frame
#         write(out, reinterpret(UInt8, data(img)))
#      end
# end

# using VideoIO
props = [:priv_data => ("crf"=>"22","preset"=>"medium")]
# encodevideo("video.mp4",frames,framerate=15,AVCodecContextProperties=props)
encodevideo("flat_map.mp4", frames, framerate=25, AVCodecContextProperties=props)
