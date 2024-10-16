--[[
    Copyright (C) 2024 s3gfa0lt <hi@s3gfa0lt.net>. All Rights Reserved.
    Copyright (C) 2024 shell32 <hi@shell32.net>. All Rights Reserved.
    vim: tabstop=4 shiftwidth=4 expandtab
]]--

--// Imports \\--
local FileSystem = require("@lune/fs")

local LuaEncode = require("LuaEncode")

--// Variables \\--
local RefId = 0

local FileExtensionToClassname = {
    [{"server.lua", "server.luau"}] = "Script",
    [{"client.lua", "client.luau"}] = "LocalScript",
    [{"lua", "luau"}] = "ModuleScript"
}

--// Main \\--
local Kuma = {}
Kuma["Version"] = "0.1"

Kuma["BundleScriptTemplate"] = [[
local ObjectTree = ${ObjectTree}
--// TODO: Finish default bundle script template
]]

function Kuma.CreateObjectTree(Directory)
    local ParentObjectChildren = {}

    for _, EntryName in FileSystem.readDir(Directory) do
        if EntryName:lower():match("init") then continue end
        RefId += 1

        local EntryPath = `{Directory}/{EntryName}`
        local EntryExtension = EntryName:match("^%w+%.(.+)$")
        local Object = {
            ["Id"] = RefId,
            ["Name"] = EntryName:gsub(`.{EntryExtension}`, "")
        } 

        if FileSystem.isFile(EntryPath) then
            for Exts, Classname in next, FileExtensionToClassname do
                for _, Ext in next, Exts do
                    if EntryExtension == Ext then
                        Object["Classname"] = Classname
                    end
                end
            end
            Object["Content"] = FileSystem.readFile(EntryPath)
        elseif FileSystem.isDir(EntryPath) then
            Object["Classname"] = "Folder"
            Object["Children"] = Kuma.CreateObjectTree(EntryPath)

            for Exts, Classname in next, FileExtensionToClassname do
                for _, Ext in next, Exts do
                    local InitPath = `{EntryPath}/Init.{Ext}`
                    if FileSystem.isFile(InitPath) then
                        Object["Classname"] = Classname
                        Object["Content"] = FileSystem.readFile(InitPath)
                    end
                end
            end
        end

        table.insert(ParentObjectChildren, Object)
    end

    return ParentObjectChildren
end

function Kuma.Bundle(Options)
    Options["EnvironmentName"] = Options["EnvironmentName"] or "Kuma" 
    
    if not Options["Source"] or not Options["Output"] then
        error("Please specify source or output")
        return
    end

    local ObjectTree = Kuma.CreateObjectTree(Options["Source"])
    return string.gsub(Kuma["BundleScriptTemplate"], "${([A-Za-z_][A-Za-z0-9_]*)}", {
        ["ObjectTree"] = LuaEncode(ObjectTree, {["Prettify"] = true}),
        ["EnvironmentName"] = Options["EnvironmentName"]
    })
end

return Kuma
