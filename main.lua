local _high_snatch_try = {}

function remove_symbols(text)
    local symbols = [[/\*?:<>|"]]
    local cleanedText = text:gsub("[" .. symbols .. "]", "")
    return cleanedText
end

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
            task.wait()
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
        if sc:IsA("Folder") then return end
        writefile(`{_folder_path}/{remove_symbols(`{sc.Name} {sc.ClassName}`)}`, "")
        return
    end
    local start = os.clock()
    local success_process, tries, _decompiled = safe_decompile(sc)
    
    local _path = table.concat(get_path_as_string(sc), ".")
    local _name = remove_symbols(`{tries or "FAILED"} {sc.Name} {sc.ClassName}.txt`)

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

function get_path_by_origin_container(origin_container, object)
    local _path = {}
    local current_object = object
    repeat
        table.insert(_path, 1, current_object)
        if current_object == origin_container or not current_object.Parent then break end
        current_object = current_object.Parent
        task.wait()
    until not current_object.Parent

    return _path
end

function save_container_scripts(container, descendant, origin_container)
    if getgenv()._extract_stop then print("Snatching stopped") end
    if not container then warn("Snatching target has to be referenced.") return end
    origin_container = origin_container or container
    
    local _array_path = get_path_by_origin_container(origin_container, container, origin_container)
    local _string_array_path = {}
    for index, value in _array_path do
        _string_array_path[index] = remove_symbols(`{value.Name} {value.ClassName}`)
    end
    
    local _path = `chees_snatcher/{remove_symbols(game.Name)}/{table.concat(_string_array_path, "/")}`
    local state, err = pcall(function()
        return makefolder(_path)
    end)
    if not getgenv()._extract_debug then 
        print(_path)
        print(state, err)
    end

    local banned_ancestors = getgenv()._extract_blacklist_ancestor or {}
    local classes_only = getgenv()._extract_only_class or {}
    for _, obj in container:GetChildren() do
        if getgenv()._extract_stop then break end
        local state_break = false

        for _, banned_ancestor in banned_ancestors do
            if not obj:FindFirstAncestor(banned_ancestor) then -- obj:IsA("LocalScript") or obj:IsA("ModuleScript"))
                if #classes_only > 0 and not table.find(classes_only, obj.ClassName) then continue end
                save_script(obj, _path)
                task.wait()
            else
                state_break = true
            end
        end
   
        if not state_break and descendant then -- 
            if #classes_only > 0 and (not find_descendant_of_class(obj, getgenv()._extract_only_class) or #obj:GetChildren() <= 0) then continue end
            save_container_scripts(obj, getgenv()._extract_descendants, origin_container)
        end
    end

    if container ~= origin_cointainer then return end
    print("----- SNATCHED TARGET -----")
    print(`done snatched ts target cuh, they from da {origin_container.Parent.Name} and they is {origin_container.Name}`)
    print("----- SNATCHED TARGET -----")
end

local _path = getgenv()._extract_path
local _descendants = getgenv()._extract_descendants
local _debug = getgenv()._extract_debug
local _blacklist = getgenv()._extract_blacklist_ancestor
local _classes = getgenv()._extract_only_class
local _force_stop = getgenv()._extract_stop
save_container_scripts(_path, _descendants)
