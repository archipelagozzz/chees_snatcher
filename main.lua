function failed_decompile(_decompiled)
    return string.find(_decompiled or "", "-- Failed to decompile") and true or false
end

function safe_decompile(_path, max_tries, tries)
    max_tries = max_tries or 128
    
    for tries = 1, max_tries do
        local state, value = pcall(function()
            return decompile(_path)
        end)
        
        local is_failed = failed_decompile(value)
        if getgenv()._extract_debug then print(`CURRENT STATE : {is_failed} | DECOMPILING {_path.Name} TRIES TAKEN : {tries}`) end
    
        if is_failed then 
            task.wait(6)
            continue
        end
        return not is_failed, tries, value
    end
end

local function get_path_as_string(object)
    local _return = {}
    local current_object = object
 
    repeat
        table.insert(_return, 1, current_object.Name)
        current_object = current_object.Parent
        task.wait()
    until not current_object or not current_object.Parent
    
    return _return
end

function find_descendant_of_class(obj, classes_name)
    for _, _obj in obj:GetDescendants() do
        for _, class_name in classes_name do
            if _obj:IsA(class_name) then return _obj end
        end
    end
end

function save_script(sc, _folder_path)
    if not sc:IsA("ModuleScript") and not sc:IsA("LocalScript") then 
        writefile(`{_folder_path}/{sc.Name} | sc.ClassName`, "")
        return
    end
    local start = os.clock()
    local success_process, tries, _decompiled = safe_decompile(sc)
    
    local _path = table.concat(get_path_as_string(sc), ".")
    local _name = `{tries or "FAILED"} {sc.Name} {sc.ClassName}.txt`

    if getgenv()._extract_debug then 
        print("------------ SNATCHING -----------------")
        print(`NAME : {_name}`)
        print(`PATH : {_path}`)
        print("------------ SNATCHING -----------------")
    end
    
    local state, _ = pcall(function()
        return writefile(`{_folder_path}/{_name}`, _decompiled)
    end)
    
    if state and getgenv()._extract_debug then
        print(`snatched {sc.Name} at {os.clock()-start}s in {tries} tries`)
    elseif getgenv()._extract_debug then
        print(`{sc.Name} ranaway cuh`)
    end
end

function save_container_scripts(container, descendant, current_path)
    if not container then warn("Snatching target has to be referenced.") return end
    current_path = current_path or {}
    
    local _path = `chees_snatcher/{game.Name}/{table.concat(current_path, "/")}`
    makefolder(`chees_snatcher/{game.Name}`)
    makefolder(_path)
   
    for _, obj in container:GetChildren() do
        for i = 1, #current_path do
            if current_path[#current_path] == `{container.Name} {container.ClassName}` then break end
            table.remove(current_path, #current_path)
        end

        for _, banned_ancestor in getgenv()._extract_blacklist_ancestor do
            if (obj:IsA("LocalScript") or obj:IsA("ModuleScript")) and obj:FindFirstAncestor(banned_ancestor) then
                save_script(obj, _path)
                task.wait()
            end
        end

        if descendant and find_descendant_of_class(obj, {"ModuleScript", "LocalScript"}) then
            table.insert(current_path, `{obj.Name} {obj.ClassName}`)
            save_container_scripts(obj, true, current_path)
        end
    end
end

local _path = getgenv()._extract_path
local _descendants = getgenv()._extract_descendants
local _debug = getgenv()._extract_debug
local _blacklist = getgenv()._extract_blacklist_ancestor
save_container_scripts(_path, _descendants)
