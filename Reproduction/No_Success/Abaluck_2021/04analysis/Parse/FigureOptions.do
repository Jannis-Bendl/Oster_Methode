* local 0: subinstr local 0 ";" ","
* syntax, [*]

* Main figure colors:

local lColorBadTerm    ${material_blue_900}
local lColorBadNoTerm  ${material_blue_800}
local lColorGoodTerm   ${material_orange_600}
local lColorGoodNoTerm ${material_orange_400}

local lColorNoTerm     ${material_blue_900}
local lColorTerm       ${material_orange_600}

* Appendix colors:

local alColorBadTerm    ${material_blue_900}
local alColorBadNoTerm  ${material_blue_300}
local alColorGoodTerm   ${material_red_900}
local alColorGoodNoTerm ${material_red_300}

local alColorNoTerm     ${material_blue_900}
local alColorTerm       ${material_red_900}

local lStyleTerm       solid
local lStyleNoTerm     dash

local xopts fontface("LM Roman 10") width(1920px) height(1080px) replace
local lopts lwidth(0.5 0.5 0.5 0.5)
