function Initialize()
    mFFT = {} -- array of FFT measures
    FFTd = {[0]={}, [1]={}, [2]={}} -- arrays of FFT data
    mode = tonumber(SKIN:GetVariable('Mode')) and true or false
    bands = tonumber(SKIN:GetVariable('Bands')) -- number of FFT bands
    minR = tonumber(SKIN:GetVariable('MinR')) -- min radius
    arcH = tonumber(SKIN:GetVariable('ArcH')) -- arc height
    travel = tonumber(SKIN:GetVariable('MaxR')) - minR - arcH -- distance arcs can travel
    decay = travel / tonumber(SKIN:GetVariable('Decay'))
    lock = false -- lock hiding of mouseover controls
    if not SKIN:GetMeter('A0') then
        GenMeasures()
        GenMeters()
        SKIN:Bang('!Refresh')
        return
    end
    for b = 0, bands - 1 do
        mFFT[b], FFTd[0][b] = SKIN:GetMeasure('mFFT'..b), 0
        if mode then
            FFTd[1][b], FFTd[2][b] = 0, 9
        end
    end
    os.remove(SKIN:GetVariable('@')..'Measures.inc')
    os.remove(SKIN:GetVariable('@')..'Meters.inc')
    SetAngle()
    SetStyle(tonumber(SKIN:GetVariable('Solid')))
    SKIN:Bang('[!SetOption Mode'..(mode and 1 or 0)..' SolidColor FF0000][!SetOption Mode'..(mode and 1 or 0)..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor FF0000"]')
    if mode then
        SKIN:Bang('!SetOption DecaySlider X '..(62 + tonumber(SKIN:GetVariable('Decay')) * 0.09))
    else
        SKIN:Bang('[!SetOptionGroup A LineColor #*Color0*#][!SetOption DecayLabel X -200][!SetOption DecayLabel Y r][!SetOption DecaySlider X -100][!MoveMeter 0 -20 Color1Set]')
    end
    if SKIN:GetVariable('ShowSet') ~= '' then
        ShowSettings()
        SKIN:Bang('!WriteKeyValue Variables ShowSet "" "#@#Radial.inc"')
    end
end

function Update()
    if mode then
        for b = 0, bands - 1 do
            local FFT = mFFT[b]:GetValue() * travel
            FFTd[0][b] = math.max(FFT, FFTd[0][b] - decay)
            FFTd[1][b] = FFTd[2][b] > 8 and FFT or math.min(FFT, FFTd[1][b] + decay)
            FFTd[2][b] = FFTd[1][b] == 0 and FFTd[2][b] + 1 or 0
            SKIN:Bang('[!SetOption A'..b..' LineStart '..(minR + FFTd[1][b])..'][!SetOption A'..b..' LineLength '..(minR + arcH + FFTd[0][b])..'][!SetOption C'..b..' LineStart '..(minR + FFT)..'][!SetOption C'..b..' LineLength '..(minR + arcH + FFT)..']')
        end
    else
        for b = 0, bands - 1 do
            local FFT = mFFT[b]:GetValue() * travel
            SKIN:Bang('[!SetOption A'..b..' LineStart '..(minR + math.min(FFT, FFTd[0][b]))..'][!SetOption A'..b..' LineLength '..(minR + arcH + math.max(FFT, FFTd[0][b]))..']')
            FFTd[0][b] = FFT
        end
    end
end

function ShowHover()
    if SKIN:GetMeter('Handle'):GetW() > 0 then return end
    SKIN:Bang('!SetOption Hover LineColor 80808050')
end

function ShowSettings()
    local maxR = tonumber(SKIN:GetVariable('MaxR'))
    SKIN:Bang('[!SetOption Handle W '..math.max(maxR * 2, 200)..'][!SetOption Handle H '..math.max(maxR * 2, 318)..'][!SetOption Hover LineColor 00000001][!MoveMeter 12 12 ModeLabel][!ShowMeterGroup Set]')
end

function HideSettings()
    if lock then return end
    SKIN:Bang('[!MoveMeter 12 -40 ModeLabel][!HideMeterGroup Set][!SetOption Hover LineColor 00000001]')
end

function GenMeasures()
    local file = io.open(SKIN:GetVariable('@')..'Measures.inc', 'w')
    for b = 1, bands - 1 do
        file:write('[mFFT'..b..']\nMeasure=Plugin\nPlugin=AudioLevel\nParent=mFFT0\nType=Band\nBandIdx='..b..'\n')
    end
    file:close()
end

function GenMeters()
    local file = io.open(SKIN:GetVariable('@')..'Meters.inc', 'w')
    for b = 0, bands - 1 do
        file:write('[A'..b..']\nMeter=Roundline\nMeterStyle=A\n'..(mode and '[C'..b..']\nMeter=Roundline\nMeterStyle=C\n' or ''))
    end
    file:close()
end

function SetMode(n)
    if mode == (n == 1) then return end
    SKIN:Bang('[!WriteKeyValue Variables Mode '..(n or '""')..' "#@#Radial.inc"][!WriteKeyValue Variables ShowSet 1 "#@#Radial.inc"][!Refresh]')
end

function SetDecay(n, m)
    local set = tonumber(SKIN:GetVariable('Decay'))
    if m then
        set = math.floor(m * 0.11) * 100
    elseif set + n >= 0 and set + n <= 1000 then
        set = math.floor((set + n) * 0.01 + 0.5) * 100
    else return end
    decay = travel / set
    SKIN:GetMeter('DecaySlider'):SetX(62 + set * 0.09)
    SKIN:Bang('[!SetOption DecayVal Text '..set..'][!SetVariable Decay '..set..'][!WriteKeyValue Variables Decay '..set..' "#@#Radial.inc"]')
end

function SetAngle(var, set)
    local startA = math.rad(var == 'StartA' and set or tonumber(SKIN:GetVariable('StartA')))
    local sweepA = math.rad(var == 'SweepA' and set or tonumber(SKIN:GetVariable('SweepA')))
    local arcG = math.rad(var == 'ArcG' and set or tonumber(SKIN:GetVariable('ArcG')))
    local rotA = sweepA / bands
    for b = 0, bands - 1 do
        SKIN:Bang('[!SetOption A'..b..' StartAngle '..(startA + rotA * b)..']'..(mode and '[!SetOption C'..b..' StartAngle '..(startA + rotA * b)..']' or ''))
    end
    SKIN:Bang('[!SetOptionGroup A RotationAngle '..(rotA - arcG)..']'..(mode and '[!SetOptionGroup C RotationAngle '..(rotA - arcG)..']' or '')..(set and '[!SetVariable '..var..' "#Set#"][!WriteKeyValue Variables '..var..' '..set..' "#@#Radial.inc"]' or ''))
end

function SetBands()
    lock = false
    local set = tonumber(SKIN:GetVariable('Set'))
    if not set or set <= 0 then return end
    SKIN:Bang('[!WriteKeyValue Variables Bands '..set..' "#@#Radial.inc"][!WriteKeyValue Variables ShowSet 1 "#@#Radial.inc"][!Refresh]')
end

function SetStyle(n)
    local solid = tonumber(SKIN:GetVariable('Solid')) and true or false
    SKIN:Bang('[!SetOption Style'..(solid and 1 or 0)..' SolidColor 505050E0][!SetOption Style'..(solid and 1 or 0)..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor 505050E0"][!SetOption Style'..(n or 0)..' SolidColor FF0000][!SetOption Style'..(n or 0)..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor FF0000"][!SetOption LineWLabel X '..(n and -200 or 12)..'][!SetOption LineWLabel Y '..(n and 'r' or '6R')..'][!SetOptionGroup A Solid '..(n or 0)..'][!SetOptionGroup C Solid '..(n or 0)..'][!SetVariable Solid '..(n or '""')..'][!WriteKeyValue Variables Solid '..(n or '""')..' "#@#Radial.inc"]')
end

function SetVar(var, min)
    lock = false
    local set = tonumber(SKIN:GetVariable('Set'))
    if not set or min and set < min then return end
    if var == 'MinR' then
        local maxR = tonumber(SKIN:GetVariable('MaxR'))
        if set >= maxR then return end
        minR = set
        travel = maxR - set
    elseif var == 'MaxR' then
        if set <= minR then return end
        travel = set - minR - arcH
    elseif var == 'StartA' then
        SetAngle('StartA', set)
    elseif var == 'SweepA' then
        SetAngle('SweepA', set)
    elseif var == 'LineW' then
        SKIN:Bang('[!SetOptionGroup A LineWidth '..set..'][!SetOptionGroup C LineWidth '..set..']')
    elseif var == 'ArcH' then
        arcH = set
        travel = tonumber(SKIN:GetVariable('MaxR')) - minR - set
    elseif var == 'ArcG' then
        SetAngle('ArcG', set)
    end
    SKIN:Bang('[!SetOption '..var..'Set Text '..set..'][!SetVariable '..var..' "#Set#"][!WriteKeyValue Variables '..var..' '..set..' "#@#Radial.inc"]')
end

function SetColor(n)
    lock = false
    if SKIN:GetVariable('Set') == '' then return end
    SKIN:Bang('[!SetOptionGroup '..((not mode or n == 1) and 'A' or 'C')..' LineColor "#Set#"][!SetOption Color'..n..'Set Text "#Set#"][!SetVariable Color'..n..' "#Set#"][!WriteKeyValue Variables Color'..n..' "#Set#" "#@#Radial.inc"]')
end
