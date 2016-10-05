--
-- For more information on config.lua see the Corona SDK Project Configuration Guide at:
-- https://docs.coronalabs.com/guide/basics/configSettings
--

application =
{
	content =
	{
	shaderPrecision =
        { 
            P_POSITION = "lowp",
            P_UV = "lowp",
            P_COLOR = "lowp",
        },
		width = 1280,
		height = 720, 
		scale = "letterBox",
		fps = 60,
		
		--[[
		imageSuffix =
		{
			    ["@2x"] = 2,
			    ["@4x"] = 4,
		},
		--]]
	},
}
