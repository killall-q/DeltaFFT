function Initialize()
    mFFT, FFTPrev, minR, t = {}, {}, tonumber(SKIN:GetVariable('MinRadius')), tonumber(SKIN:GetVariable('Thickness'))
    range = tonumber(SKIN:GetVariable('MaxRadius')) - minR
    for i = 0, 23 do
        mFFT[i], FFTPrev[i] = SKIN:GetMeasure('mFFT'..i), 0
    end
end

function Update()
    for i = 0, 23 do
        local FFT = mFFT[i]:GetValue() * range
        SKIN:Bang('[!SetOption Band'..i..' LineStart '..(minR - t + (FFT < FFTPrev[i] and FFT or FFTPrev[i]))..'][!SetOption Band'..i..' LineLength '..(minR + (FFT > FFTPrev[i] and FFT or FFTPrev[i]))..']')
        FFTPrev[i] = FFT
    end
end
