WOOWZ = {}

function WOOWZ.GENERATE_ICON(PNGPath)
	local MATERIAL = Material(PNGPath)
	MATERIAL:SetInt("$ignorez",     1)
	MATERIAL:SetInt("$vertexcolor", 1)
	MATERIAL:SetInt("$vertexalpha", 1)
	MATERIAL:SetInt("$nolod",       1)
	return MATERIAL
end