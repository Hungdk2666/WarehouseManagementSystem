if (!(Test-Path build\web\WEB-INF\classes)) {
    New-Item -ItemType Directory -Path build\web\WEB-INF\classes -Force
}
$files = Get-ChildItem -Path src\java -Recurse -Filter *.java | ForEach-Object {
    Resolve-Path -Path $_.FullName -Relative
}
$filesStr = $files -join " "
$cmd = "javac -encoding UTF-8 -cp `"C:\Program Files\Apache Software Foundation\Tomcat 10.1\lib\*;web\WEB-INF\lib\*`" -d build\web\WEB-INF\classes $filesStr"
Write-Host "Running compilation..."
Invoke-Expression $cmd
if ($LASTEXITCODE -eq 0) {
    Write-Host "Compilation successful!"
} else {
    Write-Host "Compilation failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}
