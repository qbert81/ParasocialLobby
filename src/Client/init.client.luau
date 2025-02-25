--!strict

--LOAD SERVICES

local ServicesFolder : Folder = script.Services
local Services = {}
for _, v in ServicesFolder:GetChildren() do
	if v:IsA("ModuleScript") then
		local success, module = pcall(require, v)
		if not success then
			warn("Failed to require module: " .. v.Name)
			continue
		end
		if module["init"] then
			module["init"]()
		end
		if Services[v.Name] ~= nil then
			warn("Service " .. v.Name .. " already exists in Services table and its value is being overriden")
		end
		Services[v.Name] = module
	end
end
--LOAD Replicated Services
local ReplicatedServicesFolder : Folder = game.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Services")
local ReplicatedServices = {}
for _, v in ReplicatedServicesFolder:GetChildren() do
	if v:IsA("ModuleScript") then
		local success, module = pcall(require, v)
		if not success then
			warn("Failed to require module: " .. v.Name)
			continue
		end
		if module["init"] then
			module["init"]()
		end
		if ReplicatedServices[v.Name] ~= nil then
			warn("Service " .. v.Name .. " already exists in Services table and its value is being overriden")
		end
		ReplicatedServices[v.Name] = module
	end
end

--initialize blink

