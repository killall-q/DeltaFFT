function Initialize()
    mFFT = {} -- array of FFT measures
    FFTd = {[0]={}, [1]={}, [2]={}} -- arrays of FFT data
    bar = {[0]={}, [1]={}} -- arrays of bars
    mode = tonumber(SKIN:GetVariable('Mode')) and true or false
    bands = tonumber(SKIN:GetVariable('Bands')) -- number of FFT bands
    barH = tonumber(SKIN:GetVariable('BarH')) -- bar height
    travel = tonumber(SKIN:GetVariable('Height')) - barH -- distance bars can travel
    decay = travel / tonumber(SKIN:GetVariable('Decay'))
    lock = false -- lock hiding of mouseover controls
    if not SKIN:GetMeter('B0') then
        GenMeasures()
        GenMeters()
        SKIN:Bang('!Refresh')
        return
    end
    for b = 0, bands - 1 do
        mFFT[b], FFTd[0][b], bar[0][b] = SKIN:GetMeasure('mFFT'..b), 0, SKIN:GetMeter('B'..b)
        if mode then
            FFTd[1][b], FFTd[2][b], bar[1][b] = 0, 9, SKIN:GetMeter('C'..b)
            bar[1][b]:SetH(barH)
        end
    end
    os.remove(SKIN:GetVariable('@')..'Measures.inc')
    os.remove(SKIN:GetVariable('@')..'Meters.inc')
    SKIN:Bang('[!SetOption Mode'..(mode and 1 or 0)..' SolidColor FF0000][!SetOption Mode'..(mode and 1 or 0)..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor FF0000"]')
    if mode then
        SKIN:Bang('!SetOption DecaySlider X '..(62 + tonumber(SKIN:GetVariable('Decay')) * 0.09))
    else
        SKIN:Bang('[!SetOptionGroup B SolidColor #*Color0*#][!SetOption DecayLabel X -200][!SetOption DecayLabel Y r][!SetOption DecaySlider X -100][!MoveMeter 0 -20 Color1Set]')
    end
    if SKIN:GetVariable('ShowSet') ~= '' then
        ShowSettings()
        SKIN:Bang('!WriteKeyValue Variables ShowSet "" "#@#Linear.inc"')
    end
end

function Update()
    if mode then
        for b = 0, bands - 1 do
            local FFT = mFFT[b]:GetValue() * travel
            FFTd[0][b] = math.max(FFT, FFTd[0][b] - decay)
            FFTd[1][b] = FFTd[2][b] > 8 and FFT or math.min(FFT, FFTd[1][b] + decay)
            FFTd[2][b] = FFTd[1][b] == 0 and FFTd[2][b] + 1 or 0
            bar[0][b]:SetY(travel - FFTd[0][b])
            bar[0][b]:SetH(FFTd[0][b] - FFTd[1][b] + barH)
            bar[1][b]:SetY(travel - FFT)
        end
    else
        for b = 0, bands - 1 do
            local FFT = mFFT[b]:GetValue() * travel
            bar[0][b]:SetY(travel - math.max(FFT, FFTd[0][b]))
            bar[0][b]:SetH(math.abs(FFT - FFTd[0][b]) + barH)
            FFTd[0][b] = FFT
        end
    end
end

function ShowHover()
    if SKIN:GetMeter('Handle'):GetW() > 0 then return end
    SKIN:Bang('!SetOption Hover SolidColor 80808050')
end

function ShowSettings()
    local hover = SKIN:GetMeter('Hover')
    SKIN:Bang('[!SetOption Handle W '..math.max(hover:GetW(), 186)..'][!SetOption Handle H '..math.max(hover:GetH(), 218)..'][!SetOption Hover SolidColor 00000001][!MoveMeter 12 12 ModeLabel][!ShowMeterGroup Set]')
end

function HideSettings()
    if lock then return end
    SKIN:Bang('[!MoveMeter 12 -40 ModeLabel][!HideMeterGroup Set][!SetOption Hover SolidColor 00000001]')
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
        file:write('[B'..b..']\nMeter=Image\nMeterStyle=B\n'..(b ~= 0 and '' or 'X=0\n')..(mode and '[C'..b..']\nMeter=Image\nMeterStyle=C\n' or ''))
    end
    file:close()
end

function SetMode(n)
    if mode == (n == 1) then return end
    SKIN:Bang('[!WriteKeyValue Variables Mode '..(n or '""')..' "#@#Linear.inc"][!WriteKeyValue Variables ShowSet 1 "#@#Linear.inc"][!Refresh]')
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
    SKIN:Bang('[!SetOption DecayVal Text '..set..'][!SetVariable Decay '..set..'][!WriteKeyValue Variables Decay '..set..' "#@#Linear.inc"]')
end

function SetBands()
    lock = false
    local set = tonumber(SKIN:GetVariable('Set'))
    if not set or set <= 0 then return end
    SKIN:Bang('[!WriteKeyValue Variables Bands '..set..' "#@#Linear.inc"][!WriteKeyValue Variables ShowSet 1 "#@#Linear.inc"][!Refresh]')
end

function SetVar(var, min)
    lock = false
    local set = tonumber(SKIN:GetVariable('Set'))
    if not set or min and set < min then return end
    if var == 'Height' then
        travel = set - barH
    elseif var == 'BarW' then
        if tonumber(SKIN:GetVariable('BarG')) + set < 0 then return end
        SKIN:Bang('[!SetOptionGroup B W '..set..'][!SetOptionGroup C W '..set..']')
    elseif var == 'BarH' then
        barH = set
        travel = tonumber(SKIN:GetVariable('Height')) - set
        SKIN:Bang('!SetOptionGroup C H '..set)
    elseif var == 'BarG' then
        if tonumber(SKIN:GetVariable('BarW')) + set < 0 then return end
        SKIN:Bang('[!SetOptionGroup B X '..set..'R][!SetOption B0 X 0]')
    end
    SKIN:Bang('[!SetOption '..var..'Set Text '..set..'][!SetVariable '..var..' "#Set#"][!WriteKeyValue Variables '..var..' '..set..' "#@#Linear.inc"]')
end

function SetColor(n)
    lock = false
    if SKIN:GetVariable('Set') == '' then return end
    SKIN:Bang('[!SetOptionGroup '..((not mode or n == 1) and 'B' or 'C')..' SolidColor "#Set#"][!SetOption Color'..n..'Set Text "#Set#"][!SetVariable Color'..n..' "#Set#"][!WriteKeyValue Variables Color'..n..' "#Set#" "#@#Linear.inc"]')
end
