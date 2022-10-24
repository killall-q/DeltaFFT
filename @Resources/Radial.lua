function Initialize()
  mFFT = {} -- array of FFT measures
  FFTd = {[0]={}, [1]={}, [2]={}} -- arrays of FFT data
  mode = SKIN:GetVariable('Mode') == '1'
  bands = tonumber(SKIN:GetVariable('Bands')) -- number of FFT bands
  minR = tonumber(SKIN:GetVariable('MinR')) -- min radius
  arcH = tonumber(SKIN:GetVariable('ArcH')) -- arc height
  travel = tonumber(SKIN:GetVariable('MaxR')) - minR - arcH -- distance arcs can travel
  decay = travel / tonumber(SKIN:GetVariable('Decay'))
  isLocked = false -- lock hiding of mouseover controls
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
  SetChannel(SKIN:GetVariable('Channel'))
  SetOrder(tonumber(SKIN:GetVariable('Order')), true)
  SetAngle()
  SetStyle(tonumber(SKIN:GetVariable('Solid')))
  SKIN:Bang('[!SetOption Mode'..(mode and 1 or 0)..' SolidColor FF0000][!SetOption Mode'..(mode and 1 or 0)..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor FF0000"][!SetOption SensSlider X '..(tonumber(SKIN:GetVariable('Sens')) * 0.9)..'r]')
  if mode then
    SKIN:Bang('!SetOption DecaySlider X '..(tonumber(SKIN:GetVariable('Decay')) * 0.09)..'r')
  else
    SKIN:Bang('[!SetOptionGroup A LineColor #*Color0*#][!SetOption DecayLabel X -200][!SetOption DecayLabel Y r][!MoveMeter 0 -20 Color1Set]')
  end
  if SKIN:GetVariable('ShowSet') == '1' then
    ShowSettings()
    SKIN:Bang('!WriteKeyValue Variables ShowSet 0 "#@#Radial.inc"')
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
  SKIN:Bang('[!SetOption Handle W '..math.max(maxR * 2, 200)..'][!SetOption Handle H '..math.max(maxR * 2, 368)..'][!SetOption Hover LineColor 00000001][!MoveMeter 12 12 ModeLabel][!MoveMeter 83 62 ChannelBG][!ShowMeterGroup Set]')
end

function HideSettings()
  if isLocked then return end
  SKIN:Bang('[!MoveMeter 12 -40 ModeLabel][!MoveMeter 83 -300 ChannelBG][!HideMeterGroup Set][!SetOption Hover LineColor 00000001]')
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
    file:write('[A'..b..']\nMeter=Roundline\nMeterStyle=A\n'..(mode and '[C'..b..']\nMeter=Roundline\nMeterStyle=C\n' or ''))
  end
  file:close()
end

function SetMode(n)
  if mode == (n == 1) then return end
  SKIN:Bang('[!WriteKeyValue Variables Mode '..(n or 0)..' "#@#Radial.inc"][!WriteKeyValue Variables ShowSet 1 "#@#Radial.inc"][!Refresh]')
end

function SetDecay(n, m)
  local set = tonumber(SKIN:GetVariable('Decay'))
  if m then
    set = math.floor(m * 0.11) * 100
  elseif 0 <= set + n and set + n <= 1000 then
    set = math.floor((set + n) * 0.01 + 0.5) * 100
  else return end
  decay = travel / set
  SKIN:Bang('[!SetOption DecaySlider X '..(set * 0.09)..'r][!SetOption DecayVal Text '..set..'][!SetVariable Decay '..set..'][!WriteKeyValue Variables Decay '..set..' "#@#Radial.inc"]')
end

function SetSens(n, m)
  local sens = tonumber(SKIN:GetVariable('Sens'))
  if m then
    sens = math.floor(m * 0.11) * 10
  elseif 0 <= sens + n and sens + n <= 100 then
    sens = math.floor((sens + n) * 0.1 + 0.5) * 10
  else return end
  SKIN:Bang('[!SetOption mFFT0 Sensitivity '..sens..'][!SetOption SensSlider X '..(sens * 0.9)..'r][!SetOption SensVal Text '..sens..'][!SetVariable Sens '..sens..'][!WriteKeyValue Variables Sens '..sens..' "#@#Radial.inc"]')
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
  SKIN:Bang('[!SetOption ChannelSet Text "'..(name[tonumber(n)] or n)..'"][!SetVariable Channel '..n..'][!WriteKeyValue Variables Channel '..n..' "#@#Radial.inc"]')
end

function SetBands()
  isLocked = false
  local set = tonumber(SKIN:GetVariable('Set'))
  if not set or set <= 0 then return end
  SKIN:Bang('[!WriteKeyValue Variables Bands '..set..' "#@#Radial.inc"][!WriteKeyValue Variables ShowSet 1 "#@#Radial.inc"][!Refresh]')
end

function SetOrder(n, init)
  if n ~= tonumber(SKIN:GetVariable('Order')) or init and n == 1 then
    for b = 0, bands / 2 - 1 do
      mFFT[b], mFFT[bands - b - 1] = mFFT[bands - b - 1], mFFT[b]
    end
  end
  SKIN:Bang('[!SetOption Order'..(n == 1 and 'Right' or 'Left')..' SolidColor 505050E0][!SetOption Order'..(n == 1 and 'Right' or 'Left')..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor 505050E0"][!SetOption Order'..(n == 1 and 'Left' or 'Right')..' SolidColor FF0000][!SetOption Order'..(n == 1 and 'Left' or 'Right')..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor FF0000"][!SetVariable Order '..n..'][!WriteKeyValue Variables Order '..n..' "#@#Radial.inc"]')
end

function SetAngle(var, set)
  local startA = math.rad(var == 'StartA' and set or tonumber(SKIN:GetVariable('StartA')))
  local sweepA = math.rad(var == 'SweepA' and set or tonumber(SKIN:GetVariable('SweepA')))
  local arcG = math.rad(var == 'ArcG' and set or tonumber(SKIN:GetVariable('ArcG')))
  local rotA = (sweepA + arcG) / bands
  for b = 0, bands - 1 do
    SKIN:Bang('[!SetOption A'..b..' StartAngle '..(startA + rotA * b)..']'..(mode and '[!SetOption C'..b..' StartAngle '..(startA + rotA * b)..']' or ''))
  end
  SKIN:Bang('[!SetOptionGroup A RotationAngle '..(rotA - arcG)..']'..(mode and '[!SetOptionGroup C RotationAngle '..(rotA - arcG)..']' or '')..(set and '[!SetVariable '..var..' "#Set#"][!WriteKeyValue Variables '..var..' '..set..' "#@#Radial.inc"]' or ''))
end

function SetStyle(n)
  local solid = SKIN:GetVariable('Solid') == '1'
  SKIN:Bang('[!SetOption Style'..(solid and 1 or 0)..' SolidColor 505050E0][!SetOption Style'..(solid and 1 or 0)..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor 505050E0"][!SetOption Style'..(n or 0)..' SolidColor FF0000][!SetOption Style'..(n or 0)..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor FF0000"][!SetOption LineWLabel X '..(n and -200 or 12)..'][!SetOption LineWLabel Y '..(n and 'r' or '6R')..'][!SetOption ArcGLabel X '..(n and 12 or -200)..'][!SetOption ArcGLabel Y '..(n and '6R' or 'r')..'][!SetOptionGroup A Solid '..(n or 0)..'][!SetOptionGroup C Solid '..(n or 0)..'][!SetVariable Solid '..(n or 0)..'][!WriteKeyValue Variables Solid '..(n or 0)..' "#@#Radial.inc"]')
end

function SetVar(var, min)
  isLocked = false
  local set = tonumber(SKIN:GetVariable('Set'))
  if not set or min and set < min then return end
  if var == 'MinR' then
    local maxR = tonumber(SKIN:GetVariable('MaxR'))
    if set >= maxR then return end
    minR = set
    travel = maxR - set - arcH
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
  isLocked = false
  if SKIN:GetVariable('Set') == '' then return end
  SKIN:Bang('[!SetOptionGroup '..((not mode or n == 1) and 'A' or 'C')..' LineColor "#Set#"][!SetOption Color'..n..'Set Text "#Set#"][!SetVariable Color'..n..' "#Set#"][!WriteKeyValue Variables Color'..n..' "#Set#" "#@#Radial.inc"]')
end
