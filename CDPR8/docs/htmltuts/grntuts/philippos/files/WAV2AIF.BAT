if NOT EXIST %1 mkdir %1
for %%i in (*.wav) do copysfx %%~ni.wav %1\%%~ni.aif
