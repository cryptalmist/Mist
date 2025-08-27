if queue_on_teleport then
    queue_on_teleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/cryptalmist/Mist/refs/heads/main/QOL-patch/bss-atlas.lua'))()")
else
    print("queue_on_teleport is not supported by the executor")
end
loadstring(game:HttpGet("https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua"))()