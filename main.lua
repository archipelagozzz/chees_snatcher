local MarketplaceService = game:GetService("MarketplaceService")

local SavePath = `CheeusSnatcher/Placeholder`

local GameNameState, GameName = pcall(function() 
	return MarketplaceService:GetProductInfoAsync(game.PlaceId).Name 
end)

if GameNameState then
	SavePath = `CheeusSnatcher/{GameName}`
end

local Cache = {
	HighestDecompileTries = 0,
}

function RemoveSymbols(String : string)
	local Symbols = [[/\*?:<>|"]]
	local NewString = String:gsub("[" .. Symbols .. "]", "")

	return NewString
end

function IsDecompileFailed(Decompiled : string)
	return string.find(Decompiled or "", "-- Failed to decompile")
end

function SafeDecompile(DecompileScript : LocalScript | ModuleScript, MaxTries : number)
	MaxTries = MaxTries or 128

	for Tries = 1, MaxTries do
		local State, Decompiled = pcall(function()
			return decompile(DecompileScript)
		end)

		local IsFailed = IsDecompileFailed(Decompiled)
		if getgenv().ExtractDebug then 
			print(`CURRENT STATE : {IsFailed} | DECOMPILING {DecompileScript.Name} TRIES TAKEN : {Tries}`) 
		end

		if IsFailed then 
			task.wait()
			continue
		end
		
		if Tries > Cache.HighestDecompileTries then
			Cache.HighestDecompileTries = Tries
			Cache.HighestDecomplieScript = DecompileScript:GetFullName()
		end

		return Tries, Decompiled
	end
end

function GetParentPath(Object : Instance, InitialParent : Instance)
	local CurrentParent = Object
	local PathArray = {}
	local Path = ""

	repeat
		table.insert(PathArray, CurrentParent.Name)
		CurrentParent = CurrentParent.Parent
	until CurrentParent == InitialParent or CurrentParent == game

	for Index = #PathArray, 1, -1 do
		Path = `{Path}{Path == "" and "" or "/"}{PathArray[Index]}`
	end

	return Path
end

function SaveObject(Object : Instance, CurrentPath : Instance, Folder : boolean, ForceName : string)
	if Folder or Object:IsA("Folder") then
		local FolderPath = `{CurrentPath}/{ForceName or `{Object.Name} {Object.ClassName}`}`
		makefolder(FolderPath)

		return FolderPath
	elseif Object:IsA("ModuleScript") or Object:IsA("LocalScript") then
		local Stamp = os.clock()
		local Tries, Decompiled = SafeDecompile(Object)

		local DecompiledName = RemoveSymbols(`{Tries or "FAILED"} {Object.Name} {Object.ClassName}.txt`)

		if getgenv().ExtractDebug then 
			print("------------ SNATCHED -----------------")
			print(`NAME : {DecompiledName}`)
			print(`PATH : {Object:GetFullName()}`)
			print("------------ SNATCHED -----------------")
		end

		local State, _ = pcall(function()
			return writefile(`{CurrentPath}/{DecompiledName}`, Decompiled)
		end)

		if State and getgenv().ExtractDebug then
			print(`snatched {Object.Name} at {os.clock() - Stamp}s in {Tries} tries`)
		elseif not State or getgenv().ExtractDebug then
			print(`{Object.Name} ranaway cuh`)
		end
	else
		writefile(`{CurrentPath}/{Object.Name} {Object.ClassName}`, "")
	end
end

local OriginalContainer

local OngoingSnatching = 0
local CompletedSnatch = 0

function SaveContainerObjects(Container : Instance, PreviousPath : string)
	if getgenv().ExtractForceStop then
		print("snatching stopped")
		return
	end

	if not Container then
		print("i see no target")
		return
	end

	local ExcludedAncestors = getgenv().ExtractAncestorExclude or {}
	local BannedState = false

	if #ExcludedAncestors > 0 then
		for _, Ancestor in ExcludedAncestors do
			if Container:FindFirstAncestor(Ancestor) then
				BannedState = true
				break
			end
		end
	end

	if BannedState then
		return
	end
	
	local StartStamp = os.clock()
	local IsOriginalContainer = OriginalContainer == nil
	OriginalContainer = OriginalContainer or Container

	local CurrentPath = PreviousPath or `{SavePath}`
	CurrentPath = SaveObject(Container, CurrentPath, true, IsOriginalContainer and RemoveSymbols(Container:GetFullName()))
	
	if IsOriginalContainer then
		print("----- --- -- Cheeus Snatcher -- --- -----")
		print("Cheeus is eyeing at {Container.Name}!")
		print(`Beware {Container:GetFullName()}, Cheeus is coming!`)
		print("----- --- -- Cheeus Snatcher -- --- -----")
	end
	
	for _, Object in Container:GetChildren() do
		if getgenv().ExtractForceStop then
			break
		end

		SaveObject(Object, CurrentPath)
		if Object:IsA("ModuleScript") or Object:IsA("LocalScript") then
			OngoingSnatching += 1
			CompletedSnatch += 1
		end

		if #Object:GetChildren() > 0 then
			task.spawn(function()
				SaveContainerObjects(Object, CurrentPath)
			end)
		end

		task.wait()
	end
	
	if IsOriginalContainer then
		local Stamp = os.clock()
		
		while task.wait() do
			if os.clock() - Stamp >= 60 then
				print("----- --- -- Cheeus Snatcher -- --- -----")
				print("This shit lowkey took longer than 60s")
				print("I'm leavin bruh, i'm not gonna wait forever")
				print("Just the tracker tho, not the real snatch, I'm still keepin my eyes on them")
				print("----- --- -- Cheeus Snatcher -- --- -----")
				
				break
			end
			
			if CompletedSnatch >= OngoingSnatching then
				print("----- --- -- Cheeus Snatcher -- --- -----")
				print("Cheeus succesfully snatched the target!")
				print(`Snatched {Container.Name} with full Id of {Container:GetFullName()}`)
				print(`Stored in {CurrentPath}`)
				print(`{Cache.HighestDecompileTries <= 1 and "I see no challenge on snatching these targets, the Highest Tries is" or "Got some problems while snatching these targets, I got some with"} {Cache.HighestDecompileTries} Tries which is when i tryna to snatch {Cache.HighestDecomplieScript}`)
				print(`I only took {os.clock() - StartStamp}s to snatch these targets`)
				print("----- --- -- Cheeus Snatcher -- --- -----")
				
				break
			end
		end
	end
end

local ExtractObject = getgenv().ExtractObject
local ExtractDebug = getgenv().ExtractDebug
local ExtractAncestorExclude = getgenv().ExtractAncestorExclude
local ExtractForceStop = getgenv().ExtractForceStop

SaveContainerObjects(ExtractObject)
