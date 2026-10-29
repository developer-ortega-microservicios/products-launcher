# Convierte todos los YAML de templates/ a UTF-8 sin BOM.
# Uso (desde k8s\tienda):  powershell -ExecutionPolicy Bypass -File .\fix-encoding.ps1
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

Get-ChildItem -Path (Join-Path $PSScriptRoot 'templates') -Recurse -Include *.yml, *.yaml | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    [System.IO.File]::WriteAllText($_.FullName, $content, $utf8NoBom)
    Write-Host "OK  $($_.FullName)"
}
