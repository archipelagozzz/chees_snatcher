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
    if sc:IsA("ModuleScript") or sc:IsA("LocalScript") then 
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
	else
		local _path = table.concat(get_path_as_string(sc), ".")
		local _name = remove_symbols(`[{sc.ClassName}] {sc.Name}`)

		writefile(`{_folder_path}/{_name}`, "")
    end
end

function get_path_by_origin_container(origin_container, object)
    local _path = {}
    local current_object = object
    repeat
        table.insert(_path, 1, current_object)
        if current_object == origin_container or not current_object.Parent then break end
        current_object = current_object.Parent
    until not current_object.Parent

    return _path
end

local origin_container
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

    local banned_ancestors = getgenv()._extract_blacklist_ancestor or {}
    local classes_only = getgenv()._extract_only_class or {}

	local stamp = os.clock()

    for _, obj in container:GetChildren() do
        if getgenv()._extract_stop then break end
        local state_break = false

        for _, banned_ancestor in banned_ancestors do
            if obj:FindFirstAncestor(banned_ancestor.Name) then -- obj:IsA("LocalScript") or obj:IsA("ModuleScript"))
                state_break = true
            end
        end

        if not state_break then -- 
			if #classes_only > 0 and not table.find(classes_only, obj.ClassName) then continue end

            save_script(obj, _path)
			
            if descendant and #obj:GetChildren() > 0 then
				if #classes_only > 0 and (not find_descendant_of_class(obj, getgenv()._extract_only_class)) then continue end
            	save_container_scripts(obj, getgenv()._extract_descendants)
			end
        end
    end

	if origin_container.Name == container.Name and origin_container.ClassName == container.ClassName and #origin_container:GetChildren() == #container:GetChildren() then 
		print("----- SNATCHED TARGET -----")
    	print(`done snatched ts target cuh, they from da {origin_container.Parent.Name} and they is {origin_container.Name}`)
		print(`ts lowkey taking me some {os.clock() - stamp}s`)
    	print("----- SNATCHED TARGET -----")
	end
end

local _path = getgenv()._extract_path
local _descendants = getgenv()._extract_descendants
local _debug = getgenv()._extract_debug
local _blacklist = getgenv()._extract_blacklist_ancestor
local _classes = getgenv()._extract_only_class
local _force_stop = getgenv()._extract_stop
save_container_scripts(_path, _descendants)
