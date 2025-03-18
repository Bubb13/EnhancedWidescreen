
param (
	[Parameter(Mandatory)][string]$SolutionDir,
	[Parameter(Mandatory)][string]$OutDir,
	[Parameter(Mandatory)][string]$GamePath
)

try {
	"EnhancedWidescreenGUI.dll" | ForEach-Object {Copy-Item "$OutDir/$_" "$SolutionDir/../../B3EnhancedWidescreen/loader"}
	"EnhancedWidescreenGUI.pdb" | ForEach-Object {Copy-Item "$OutDir/$_" "$SolutionDir/../pdb"}
	if (($GamePath -ne ".") -and (Test-Path $GamePath)) {
		"EnhancedWidescreenGUI.dll", "EnhancedWidescreenGUI.pdb" | ForEach-Object {Copy-Item "$OutDir/$_" $GamePath}
	}
}
catch {
	Write-Output $_
	Exit -1
}
