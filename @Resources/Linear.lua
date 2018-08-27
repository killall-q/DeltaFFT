function Initialize()
    mFFT, FFTPrev, band, height, thick = {}, {}, {}, tonumber(SKIN:GetVariable('Height')), tonumber(SKIN:GetVariable('Thick'))
    for i = 0, 23 do
        mFFT[i], FFTPrev[i], band[i] = SKIN:GetMeasure('mFFT'..i), 0, SKIN:GetMeter('Band'..i)
    end
end

function Update()
    for i = 0, 23 do
        local FFT = mFFT[i]:GetValue() * height
        band[i]:SetY(height - (FFT > FFTPrev[i] and FFT or FFTPrev[i]))
        band[i]:SetH(math.abs(FFT - FFTPrev[i]) + thick)
        FFTPrev[i] = FFT
    end
end
