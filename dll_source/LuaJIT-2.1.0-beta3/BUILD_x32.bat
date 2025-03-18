call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsamd64_x86.bat"
cd src
call msvcbuild.bat
copy "lua51.dll" "..\..\..\B3EnhancedWidescreen\loader"
copy "lua51.pdb" "..\..\pdb"
pause