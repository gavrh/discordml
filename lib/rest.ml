module type Rest = sig
    val endpoint : string
end

include (struct

    let endpoint : string = ""

end : Rest)
