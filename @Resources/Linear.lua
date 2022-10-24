function Initialize()
  mFFT = {} -- array of FFT measures
  FFTd = {[0]={}, [1]={}, [2]={}} -- arrays of FFT data
  bar = {[0]={}, [1]={}} -- arrays of bars
  mode = SKIN:GetVariable('Mode') == '1'
  bands = tonumber(SKIN:GetVariable('Bands')) -- number of FFT bands
  barH = tonumber(SKIN:GetVariable('BarH')) -- bar height
  travel = tonumber(SKIN:GetVariable('Height')) - barH -- distance bars can travel
  decay = travel / tonumber(SKIN:GetVariable('Decay'))
  isLocked = false -- lock hiding of mouseover controls
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
  SetChannel(SKIN:GetVariable('Channel'))
  SetOrder(tonumber(SKIN:GetVariable('Order')), true)
  SKIN:Bang('[!SetOption Mode'..(mode and 1 or 0)..' SolidColor FF0000][!SetOption Mode'..(mode and 1 or 0)..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor FF0000"][!SetOption SensSlider X '..(tonumber(SKIN:GetVariable('Sens')) * 0.9)..'r]')
  if mode then
    SKIN:Bang('!SetOption DecaySlider X '..(tonumber(SKIN:GetVariable('Decay')) * 0.09)..'r')
  else
    SKIN:Bang('[!SetOptionGroup B SolidColor #*Color0*#][!SetOption DecayLabel X -200][!SetOption DecayLabel Y r][!MoveMeter 0 -20 Color1Set]')
  end
  if SKIN:GetVariable('ShowSet') == '1' then
    ShowSettings()
    SKIN:Bang('!WriteKeyValue Variables ShowSet 0 "#@#Linear.inc"')
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
  SKIN:Bang('[!SetOption Handle W '..math.max(hover:GetW(), 186)..'][!SetOption Handle H '..math.max(hover:GetH(), 293)..'][!SetOption Hover SolidColor 00000001][!MoveMeter 12 12 ModeLabel][!MoveMeter 83 62 ChannelBG][!ShowMeterGroup Set]')
end

function HideSettings()
  if isLocked then return end
  SKIN:Bang('[!MoveMeter 12 -40 ModeLabel][!MoveMeter 83 -300 ChannelBG][!HideMeterGroup Set][!SetOption Hover SolidColor 00000001]')
end

function GenMeasures()
  local file = io.open(SKIN:GetVariable('@')..'Measures.inc', 'w')
  for b = 1, bands - 1 do
    file:write('[mFFT'..b..']\nMeasure=Plugin\nPlugin=AudioLevel\nParent=mFFT0\nType=Band\nBandIdx='..b..'\nGroup=mFFT\n')
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
  SKIN:Bang('[!WriteKeyValue Variables Mode '..(n or 0)..' "#@#Linear.inc"][!WriteKeyValue Variables ShowSet 1 "#@#Linear.inc"][!Refresh]')
end

function SetDecay(n, m)
  local set = tonumber(SKIN:GetVariable('Decay'))
  if m then
    set = math.floor(m * 0.11) * 100
  elseif 0 <= set + n and set + n <= 1000 then
    set = math.floor((set + n) * 0.01 + 0.5) * 100
  else return end
  decay = travel / set
  SKIN:Bang('[!SetOption DecaySlider X '..(set * 0.09)..'r][!SetOption DecayVal Text '..set..'][!SetVariable Decay '..set..'][!WriteKeyValue Variables Decay '..set..' "#@#Linear.inc"]')
end

function SetSens(n, m)
  local sens = tonumber(SKIN:GetVariable('Sens'))
  if m then
    sens = math.floor(m * 0.11) * 10
  elseif 0 <= sens + n and sens + n <= 100 then
    sens = math.floor((sens + n) * 0.1 + 0.5) * 10
  else return end
  SKIN:Bang('[!SetOption mFFT0 Sensitivity '..sens..'][!SetOption SensSlider X '..(sens * 0.9)..'r][!SetOption SensVal Text '..sens..'][!SetVariable Sens '..sens..'][!WriteKeyValue Variables Sens '..sens..' "#@#Linear.inc"]')
end

function SetChannel(n)
  local name = {[0]='Left','Right','Center','Subwoofer','Back Left','Back Right','Side Left','Side Right'}
  if n == 'Stereo' then
    -- Split bands between L and R channels
    for b = 0, bands / 2 - 1 do
      SKIN:Bang('[!SetOption mFFT'..b..' Channel L][!SetOption mFFT'..b..' BandIdx '..(bands - b * 2 - 2)..']')
    end
    for b = bands / 2, bands - 1 do
      SKIN:Bang('[!SetOption mFFT'..b..' Channel R][!SetOption mFFT'..b..' BandIdx '..(b * 2 - bands - 2)..']')
    end
  else
    SKIN:Bang('!SetOptionGroup mFFT Channel '..n)
    for b = 0, bands - 1 do
      SKIN:Bang('!SetOption mFFT'..b..' BandIdx '..b)
    end
  end
  SKIN:Bang('[!SetOption ChannelSet Text "'..(name[tonumber(n)] or n)..'"][!SetVariable Channel '..n..'][!WriteKeyValue Variables Channel '..n..' "#@#Linear.inc"]')
end

function SetBands()
  isLocked = false
  local set = tonumber(SKIN:GetVariable('Set'))
  if not set or set <= 0 then return end
  SKIN:Bang('[!WriteKeyValue Variables Bands '..set..' "#@#Linear.inc"][!WriteKeyValue Variables ShowSet 1 "#@#Linear.inc"][!Refresh]')
end

function SetOrder(n, init)
  if n ~= tonumber(SKIN:GetVariable('Order')) or init and n == 1 then
    for b = 0, bands / 2 - 1 do
      mFFT[b], mFFT[bands - b - 1] = mFFT[bands - b - 1], mFFT[b]
    end
  end
  SKIN:Bang('[!SetOption Order'..(n == 1 and 'Right' or 'Left')..' SolidColor 505050E0][!SetOption Order'..(n == 1 and 'Right' or 'Left')..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor 505050E0"][!SetOption Order'..(n == 1 and 'Left' or 'Right')..' SolidColor FF0000][!SetOption Order'..(n == 1 and 'Left' or 'Right')..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor FF0000"][!SetVariable Order '..n..'][!WriteKeyValue Variables Order '..n..' "#@#Linear.inc"]')
end

function SetVar(var, min)
  isLocked = false
  local set = tonumber(SKIN:GetVariable('Set'))
  if not set or min and set < min then return end
  if var == 'Height' then
    travel = set - barH
  elseif var == 'BarH' then
    barH = set
    travel = tonumber(SKIN:GetVariable('Height')) - set
    SKIN:Bang('!SetOptionGroup C H '..set)
  elseif var == 'BarW' then
    if tonumber(SKIN:GetVariable('BarG')) + set < 0 then return end
    SKIN:Bang('[!SetOptionGroup B W '..set..'][!SetOptionGroup C W '..set..']')
  elseif var == 'BarG' then
    if tonumber(SKIN:GetVariable('BarW')) + set < 0 then return end
    SKIN:Bang('[!SetOptionGroup B X '..set..'R][!SetOption B0 X 0]')
  end
  SKIN:Bang('[!SetOption '..var..'Set Text "'..set..' px"][!SetVariable '..var..' "#Set#"][!WriteKeyValue Variables '..var..' '..set..' "#@#Linear.inc"]')
end

function SetColor(n)
  isLocked = false
  if SKIN:GetVariable('Set') == '' then return end
  SKIN:Bang('[!SetOptionGroup '..((not mode or n == 1) and 'B' or 'C')..' SolidColor "#Set#"][!SetOption Color'..n..'Set Text "#Set#"][!SetVariable Color'..n..' "#Set#"][!WriteKeyValue Variables Color'..n..' "#Set#" "#@#Linear.inc"]')
end
