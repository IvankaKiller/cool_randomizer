WOOWZ = {}

-- ИКОНКИ -- <

	local CATEGORY_ICONS = {
		{"ABSOLUTE", "cool_randomizer/png/absolute.png"},
		{"Vaniny pushki", "cool_randomizer/png/1.png"},
		{"Ванины пушки", "cool_randomizer/png/2.png"},
		{"Entities", "cool_randomizer/png/ent.png"}
	}

	if CLIENT then
		for _, Data in ipairs(CATEGORY_ICONS) do
			local CategoryName = Data[1]
			local IconPath     = Data[2]
			
			if CategoryName and IconPath then
				list.Set("ContentCategoryIcons", CategoryName, IconPath)
			end
		end
	end
 
 -- >