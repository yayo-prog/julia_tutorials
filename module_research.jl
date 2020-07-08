struct MyStruct
    a
    c
end

"""
overide the print version
"""
function show(io::IO, m::MyStruct)
    print("2 arg version of MyStuct - we be used with print")
end

"""
overide the representation method
"""
function show(io::IO, ::MIME"text/plain",  m::MyStruct)
    print("3 arg version of MyStuct - excuted when called bare")
end



module Testy
using Random

export a

function a()
    println("this is a")
end

# Top-Level code will be excuted when including / using
println ("this is a top level code")

end # module Testy


# We can't create and use a new version of the Module because it will create a conflict which version of 
# the new method to overide
#

module Testy
using Random

export a

function a()
    println("this is a")
    println("changed a")
end

# Top-Level code will be excuted when including / using
println ("this is a top level code")

end # module Testy
